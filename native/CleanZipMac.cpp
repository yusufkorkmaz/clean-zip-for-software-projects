#include <CoreFoundation/CoreFoundation.h>
#include <mach-o/dyld.h>
#define MINIZ_NO_ZLIB_COMPATIBLE_NAMES
#include <miniz.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <algorithm>
#include <cerrno>
#include <cstdio>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>
#include <unordered_set>
#include <vector>

namespace fs = std::filesystem;
static void fail(const std::string& action, const fs::path& path) {
    throw std::runtime_error(action + ": " + path.string() + " (" + std::strerror(errno) + ")");
}
static std::string folded(const std::string& text) {
    auto value = CFStringCreateWithBytes(nullptr, reinterpret_cast<const UInt8*>(text.data()),
                                        text.size(), kCFStringEncodingUTF8, false);
    if (!value) throw std::runtime_error("Invalid UTF-8 filename or rule");
    auto result = CFStringCreateMutableCopy(nullptr, 0, value);
    CFRelease(value);
    if (!result) throw std::bad_alloc();
    CFStringNormalize(result, kCFStringNormalizationFormC);
    CFStringLowercase(result, nullptr);
    std::vector<char> buffer(CFStringGetMaximumSizeForEncoding(CFStringGetLength(result), kCFStringEncodingUTF8) + 1);
    bool ok = CFStringGetCString(result, buffer.data(), buffer.size(), kCFStringEncodingUTF8);
    CFRelease(result);
    if (!ok) throw std::runtime_error("Cannot normalize filename");
    return buffer.data();
}
static fs::path executableDirectory() {
    uint32_t size = 0;
    _NSGetExecutablePath(nullptr, &size);
    std::vector<char> buffer(size);
    if (_NSGetExecutablePath(buffer.data(), &size)) throw std::runtime_error("Cannot locate Clean Zip");
    return fs::canonical(buffer.data()).parent_path();
}
struct Rules {
    std::unordered_set<std::string> dirs, extensions, names;
    std::vector<std::string> suffixes;
    void load(const fs::path& path) {
        if (fs::file_size(path) > 1048576) throw std::runtime_error("Rules file is too large");
        std::ifstream input(path);
        if (!input) throw std::runtime_error("Cannot read rules: " + path.string());
        std::string line;
        bool firstLine = true;
        while (std::getline(input, line)) {
            if (firstLine && line.rfind("\xef\xbb\xbf", 0) == 0) line.erase(0, 3);
            firstLine = false;
            auto first = line.find_first_not_of(" \t\r");
            if (first == std::string::npos) continue;
            line = line.substr(first, line.find_last_not_of(" \t\r") - first + 1);
            if (line[0] == '#') continue;
            if (line.size() < 3 || line[1] != ':') throw std::runtime_error("Invalid rule: " + line);
            auto value = folded(line.substr(2));
            switch (line[0]) {
            case 'd': dirs.insert(value); break;
            case 'e': extensions.insert(value); break;
            case 'f': names.insert(value); break;
            case 's': suffixes.push_back(value); break;
            default: throw std::runtime_error("Unknown rule: " + line);
            }
        }
        if (input.bad()) throw std::runtime_error("Cannot read rules: " + path.string());
    }
    bool skip(const std::string& name) const {
        auto value = folded(name);
        auto dot = value.find_last_of('.');
        if (names.count(value) || (dot != std::string::npos && extensions.count(value.substr(dot))) ||
            value.find(".so.") != std::string::npos) return true;
        for (const auto& suffix : suffixes)
            if (value.size() >= suffix.size() && value.compare(value.size() - suffix.size(), suffix.size(), suffix) == 0) return true;
        return false;
    }
};
struct File { fs::path relative; struct stat snapshot; };
static std::vector<File> scan(const fs::path& root, const Rules& rules) {
    std::vector<File> files;
    std::vector<fs::path> pending{root};
    while (!pending.empty()) {
        auto dir = pending.back(); pending.pop_back();
        for (const auto& entry : fs::directory_iterator(dir)) {
            struct stat info;
            if (lstat(entry.path().c_str(), &info)) fail("Cannot inspect source", entry.path());
            auto name = entry.path().filename().string();
            if (S_ISLNK(info.st_mode)) continue;
            if (S_ISDIR(info.st_mode)) {
                if (!rules.dirs.count(folded(name))) pending.push_back(entry.path());
            } else if (S_ISREG(info.st_mode) && !rules.skip(name)) {
                files.push_back({entry.path().lexically_relative(root), info});
            }
        }
    }
    std::sort(files.begin(), files.end(), [](const File& a, const File& b) { return a.relative < b.relative; });
    return files;
}
static bool sameFile(const struct stat& a, const struct stat& b) {
    return a.st_dev == b.st_dev && a.st_ino == b.st_ino && a.st_size == b.st_size &&
           a.st_mtimespec.tv_sec == b.st_mtimespec.tv_sec && a.st_mtimespec.tv_nsec == b.st_mtimespec.tv_nsec &&
           a.st_ctimespec.tv_sec == b.st_ctimespec.tv_sec && a.st_ctimespec.tv_nsec == b.st_ctimespec.tv_nsec;
}
// Resolve parent aliases while retaining the final name so existing symlinks can be rejected.
static fs::path targetPath(const fs::path& path) {
    auto absolute = fs::absolute(path).lexically_normal();
    return fs::canonical(absolute.parent_path()) / absolute.filename();
}
static bool inside(const fs::path& path, const fs::path& root) {
    auto a = root.begin(), b = path.begin();
    for (; a != root.end() && b != path.end(); ++a, ++b) if (*a != *b) return false;
    return a == root.end();
}
static void checkTarget(const fs::path& path, const fs::path& root) {
    if (inside(path, root)) throw std::runtime_error("Output and manifest must be outside the source folder");
    auto status = fs::symlink_status(path);
    if (fs::is_symlink(status) || (fs::exists(status) && !fs::is_regular_file(status)))
        throw std::runtime_error("Target must be a regular file: " + path.string());
}
struct Temporary {
    fs::path path;
    FILE* stream = nullptr;
    explicit Temporary(const fs::path& target) {
        auto pattern = target.string() + ".XXXXXX";
        std::vector<char> name(pattern.begin(), pattern.end()); name.push_back('\0');
        int fd = mkstemp(name.data());
        if (fd < 0) fail("Cannot create temporary output", target);
        path = name.data();
        stream = fdopen(fd, "w+b");
        if (!stream) { auto saved = errno; close(fd); unlink(path.c_str()); errno = saved; fail("Cannot open output", target); }
    }
    ~Temporary() { if (stream) fclose(stream); if (!path.empty()) unlink(path.c_str()); }
    Temporary(const Temporary&) = delete;
    Temporary& operator=(const Temporary&) = delete;
    void commit(const fs::path& target) {
        if (fflush(stream) || fsync(fileno(stream))) fail("Cannot flush output", path);
        int result = fclose(stream); stream = nullptr;
        if (result) fail("Cannot close output", path);
        if (rename(path.c_str(), target.c_str())) fail("Cannot replace output; previous ZIP preserved", target);
        path.clear();
    }
};
static void writeManifest(const fs::path& path, const std::vector<File>& files) {
    Temporary output(path);
    for (const auto& file : files) {
        auto name = file.relative.generic_string();
        // A line-based manifest cannot represent line breaks unambiguously.
        if (name.find_first_of("\r\n") != std::string::npos) throw std::runtime_error("Manifest cannot represent a filename containing a line break");
        name += '\n';
        if (fwrite(name.data(), 1, name.size(), output.stream) != name.size()) fail("Cannot write manifest", path);
    }
    output.commit(path);
}
static void writeZip(const fs::path& root, const fs::path& target, const std::vector<File>& files) {
    Temporary output(target);
    mz_zip_archive zip = {};
    if (!mz_zip_writer_init_cfile(&zip, output.stream, MZ_ZIP_FLAG_WRITE_ZIP64)) throw std::runtime_error("Cannot initialize ZIP writer");
    try {
        size_t count = 0;
        for (const auto& file : files) {
            auto path = root / file.relative;
            int fd = open(path.c_str(), O_RDONLY | O_NOFOLLOW | O_NONBLOCK);
            if (fd < 0) fail("Cannot read source", path);
            struct stat info;
            if (fstat(fd, &info) || !S_ISREG(info.st_mode) || !sameFile(info, file.snapshot)) {
                close(fd); throw std::runtime_error("Source changed during ZIP: " + path.string());
            }
            FILE* raw = fdopen(fd, "rb");
            if (!raw) { auto saved = errno; close(fd); errno = saved; fail("Cannot open source", path); }
            std::unique_ptr<FILE, decltype(&fclose)> input(raw, fclose);
            time_t modified = info.st_mtimespec.tv_sec;
            auto name = file.relative.generic_string();
            if (!mz_zip_writer_add_cfile(&zip, name.c_str(), input.get(), info.st_size, &modified,
                                         nullptr, 0, MZ_BEST_SPEED, nullptr, 0, nullptr, 0))
                throw std::runtime_error("ZIP failed for " + name + ": " + mz_zip_get_error_string(mz_zip_get_last_error(&zip)));
            if (fstat(fd, &info) || !sameFile(info, file.snapshot)) throw std::runtime_error("Source changed during ZIP: " + path.string());
            if (++count % 500 == 0) std::cout << "Compressing: " << count << " / " << files.size() << '\n';
        }
        if (!mz_zip_writer_finalize_archive(&zip)) throw std::runtime_error("Cannot finalize ZIP");
    } catch (...) { mz_zip_writer_end(&zip); throw; }
    mz_zip_writer_end(&zip);
    output.commit(target);
}
int main(int argc, char** argv) {
    try {
        fs::path source, output, manifest, rulesPath = executableDirectory() / "CleanZip.rules.txt";
        bool scanOnly = false;
        for (int i = 1; i < argc; ++i) {
            std::string arg(argv[i]);
            if (arg == "--no-ui") continue;
            if (arg == "--scan-only") { scanOnly = true; continue; }
            if (arg == "--version") { std::cout << "Clean Zip 2.0.1 (macOS)\n"; return 0; }
            if (arg == "--help") { std::cout << "CleanZip --path <folder> [--output <zip>] [--scan-only] [--manifest <file>] [--rules <file>] [--no-ui]\n"; return 0; }
            if ((arg == "--path" || arg == "--output" || arg == "--manifest" || arg == "--rules") && i + 1 < argc) {
                fs::path value(argv[++i]);
                if (arg == "--path") source = value;
                else if (arg == "--output") output = value;
                else if (arg == "--manifest") manifest = value;
                else rulesPath = value;
            } else throw std::runtime_error("Invalid argument; use --help");
        }
        if (source.empty()) throw std::runtime_error("--path is required");
        auto root = fs::canonical(source);
        if (!fs::is_directory(root) || root == root.root_path()) throw std::runtime_error("Select a project folder, not a disk root");
        output = targetPath(output.empty() ? fs::path(root.string() + ".zip") : output);
        checkTarget(output, root);
        if (!manifest.empty()) {
            manifest = targetPath(manifest); checkTarget(manifest, root);
            std::error_code error;
            if (folded(manifest.string()) == folded(output.string()) || fs::equivalent(manifest, output, error))
                throw std::runtime_error("ZIP and manifest targets must be different");
        }
        Rules rules; rules.load(rulesPath);
        auto files = scan(root, rules);
        std::cout << "Selected: " << files.size() << " files\n";
        if (!manifest.empty()) writeManifest(manifest, files);
        if (scanOnly) return 0;
        if (files.empty()) { std::cout << "No selected files; existing ZIP preserved.\n"; return 0; }
        writeZip(root, output, files);
        std::cout << "Done: " << output.string() << '\n';
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "Clean Zip error: " << error.what() << '\n'; return 1;
    }
}
