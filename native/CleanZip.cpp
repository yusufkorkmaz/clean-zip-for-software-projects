#include <windows.h>
#include <objbase.h>
#include <miniz.h>
#include <algorithm>
#include <chrono>
#include <cstdio>
#include <cwctype>
#include <map>
#include <stdexcept>
#include <string>
#include <unordered_set>
#include <vector>

using Clock = std::chrono::steady_clock;
static std::string utf8(const std::wstring& s) {
    if (s.empty()) return {};
    int n = WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, s.data(), static_cast<int>(s.size()), nullptr, 0, nullptr, nullptr);
    if (!n) throw std::runtime_error("Invalid Unicode path");
    std::string result(n, '\0');
    WideCharToMultiByte(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), &result[0], n, nullptr, nullptr);
    return result;
}
static std::wstring wide(const std::string& s) {
    if (s.empty()) return {};
    int n = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, s.data(), static_cast<int>(s.size()), nullptr, 0);
    if (!n) throw std::runtime_error("Rules must use UTF-8");
    std::wstring result(n, L'\0');
    MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), &result[0], n);
    return result;
}
static std::wstring lower(std::wstring s) {
    std::transform(s.begin(), s.end(), s.begin(), [](wchar_t c) { return static_cast<wchar_t>(towlower(c)); });
    return s;
}
static std::wstring fullPath(const std::wstring& path) {
    DWORD size = GetFullPathNameW(path.c_str(), 0, nullptr, nullptr);
    if (!size) throw std::runtime_error("Invalid path");
    std::vector<wchar_t> buf(size);
    if (!GetFullPathNameW(path.c_str(), size, buf.data(), nullptr)) throw std::runtime_error("Invalid path");
    std::wstring result(buf.data());
    while (result.size() > 3 && result.back() == L'\\') result.pop_back();
    return result;
}
static std::wstring ioPath(const std::wstring& path) {
    if (path.rfind(L"\\\\?\\", 0) == 0) return path;
    if (path.rfind(L"\\\\", 0) == 0) return L"\\\\?\\UNC\\" + path.substr(2);
    return L"\\\\?\\" + path;
}
static void fail(const char* action, const std::wstring& path) {
    throw std::runtime_error(std::string(action) + ": " + utf8(path) + " (Windows error " + std::to_string(GetLastError()) + ")");
}
struct Handle {
    HANDLE value;
    explicit Handle(HANDLE h) : value(h) {}
    ~Handle() { if (value != INVALID_HANDLE_VALUE) CloseHandle(value); }
    Handle(const Handle&) = delete;
    Handle& operator=(const Handle&) = delete;
};
static std::wstring executableDirectory() {
    std::vector<wchar_t> buf(32768);
    DWORD n = GetModuleFileNameW(nullptr, buf.data(), static_cast<DWORD>(buf.size()));
    if (!n || n >= buf.size()) throw std::runtime_error("Cannot locate Clean Zip");
    std::wstring s(buf.data(), n);
    return s.substr(0, s.find_last_of(L'\\'));
}
struct Rules {
    std::unordered_set<std::wstring> dirs, extensions, names;
    std::vector<std::wstring> suffixes;
    void load() {
        auto path = executableDirectory() + L"\\CleanZip.rules.txt";
        Handle f(CreateFileW(ioPath(path).c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr));
        if (f.value == INVALID_HANDLE_VALUE) fail("Cannot read exclusion rules", path);
        LARGE_INTEGER size;
        if (!GetFileSizeEx(f.value, &size) || size.QuadPart > 1048576) throw std::runtime_error("Rules file is too large");
        std::string data(static_cast<size_t>(size.QuadPart), '\0');
        DWORD read = 0;
        if (!ReadFile(f.value, data.empty() ? nullptr : &data[0], static_cast<DWORD>(data.size()), &read, nullptr) || read != data.size()) fail("Cannot read rules", path);
        if (data.rfind("\xef\xbb\xbf", 0) == 0) data.erase(0, 3);
        size_t start = 0;
        while (start <= data.size()) {
            auto end = data.find('\n', start);
            auto line = data.substr(start, end == std::string::npos ? end : end - start);
            auto first = line.find_first_not_of(" \t\r");
            if (first != std::string::npos) {
                line = line.substr(first, line.find_last_not_of(" \t\r") - first + 1);
                if (line[0] != '#') {
                    if (line.size() < 3 || line[1] != ':') throw std::runtime_error("Invalid exclusion rule: " + line);
                    auto value = lower(wide(line.substr(2)));
                    switch (line[0]) {
                    case 'd': dirs.insert(value); break;
                    case 'e': extensions.insert(value); break;
                    case 'f': names.insert(value); break;
                    case 's': suffixes.push_back(value); break;
                    default: throw std::runtime_error("Unknown exclusion rule: " + line);
                    }
                }
            }
            if (end == std::string::npos) break;
            start = end + 1;
        }
    }
    bool skip(const std::wstring& name) const {
        auto s = lower(name);
        auto dot = s.find_last_of(L'.');
        if (names.count(s) || (dot != std::wstring::npos && extensions.count(s.substr(dot))) || s.find(L".so.") != std::wstring::npos) return true;
        for (const auto& suffix : suffixes) if (s.size() >= suffix.size() && s.compare(s.size() - suffix.size(), suffix.size(), suffix) == 0) return true;
        return false;
    }
};
struct File { std::wstring relative; uint64_t size; FILETIME modified; };
struct Selection {
    std::vector<File> files;
    size_t dirs = 0, skippedDirs = 0, skippedFiles = 0;
    uint64_t bytes = 0;
    void scan(const std::wstring& root, const Rules& rules) {
        std::vector<std::wstring> pending{L""};
        auto update = Clock::now();
        while (!pending.empty()) {
            auto dir = pending.back(); pending.pop_back(); ++dirs;
            auto path = root + (dir.empty() ? L"" : L"\\" + dir);
            WIN32_FIND_DATAW data;
            HANDLE search = FindFirstFileW(ioPath(path + L"\\*").c_str(), &data);
            if (search == INVALID_HANDLE_VALUE) {
                if (GetLastError() == ERROR_FILE_NOT_FOUND) continue;
                fail("Cannot scan directory", path);
            }
            DWORD error = 0;
            do {
                std::wstring name(data.cFileName);
                if (name == L"." || name == L"..") continue;
                if (data.dwFileAttributes & FILE_ATTRIBUTE_REPARSE_POINT) { ++skippedFiles; continue; }
                auto relative = dir.empty() ? name : dir + L"\\" + name;
                if (data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
                    if (rules.dirs.count(lower(name))) ++skippedDirs;
                    else pending.push_back(relative);
                } else if (rules.skip(name)) ++skippedFiles;
                else {
                    uint64_t size = (uint64_t(data.nFileSizeHigh) << 32) | data.nFileSizeLow;
                    files.push_back({relative, size, data.ftLastWriteTime}); bytes += size;
                }
            } while (FindNextFileW(search, &data));
            error = GetLastError(); FindClose(search);
            if (error != ERROR_NO_MORE_FILES) { SetLastError(error); fail("Cannot enumerate directory", path); }
            if (Clock::now() - update >= std::chrono::milliseconds(500)) {
                printf("\rScanning: %zu folders, %zu selected files   ", dirs, files.size()); fflush(stdout); update = Clock::now();
            }
        }
    }
};
static size_t writeZip(void* opaque, mz_uint64 offset, const void* buffer, size_t size) {
    auto handle = static_cast<Handle*>(opaque)->value;
    LARGE_INTEGER pos; pos.QuadPart = static_cast<LONGLONG>(offset);
    if (!SetFilePointerEx(handle, pos, nullptr, FILE_BEGIN)) return 0;
    DWORD written = 0;
    if (size > MAXDWORD || !WriteFile(handle, buffer, static_cast<DWORD>(size), &written, nullptr)) return 0;
    return written;
}
static size_t readFile(void* opaque, mz_uint64 offset, void* buffer, size_t size) {
    auto handle = static_cast<Handle*>(opaque)->value;
    LARGE_INTEGER pos; pos.QuadPart = static_cast<LONGLONG>(offset);
    if (!SetFilePointerEx(handle, pos, nullptr, FILE_BEGIN)) return 0;
    DWORD count = 0;
    if (size > MAXDWORD || !ReadFile(handle, buffer, static_cast<DWORD>(size), &count, nullptr)) return 0;
    return count;
}
static void zipFiles(const std::wstring& root, const std::wstring& stage, const Selection& selected) {
    Handle out(CreateFileW(ioPath(stage).c_str(), GENERIC_WRITE, 0, nullptr, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, nullptr));
    if (out.value == INVALID_HANDLE_VALUE) fail("Cannot create ZIP", stage);
    mz_zip_archive zip = {}; zip.m_pWrite = writeZip; zip.m_pIO_opaque = &out;
    if (!mz_zip_writer_init_v2(&zip, 0, MZ_ZIP_FLAG_WRITE_ZIP64)) throw std::runtime_error("Cannot initialize ZIP writer");
    auto update = Clock::now(); size_t count = 0;
    try {
        for (const auto& file : selected.files) {
            auto path = root + L"\\" + file.relative;
            Handle in(CreateFileW(ioPath(path).c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr, OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, nullptr));
            if (in.value == INVALID_HANDLE_VALUE) fail("Cannot read source", path);
            LARGE_INTEGER actual;
            if (!GetFileSizeEx(in.value, &actual) || static_cast<uint64_t>(actual.QuadPart) != file.size) throw std::runtime_error("Source changed during ZIP: " + utf8(path));
            auto name = utf8(file.relative); std::replace(name.begin(), name.end(), '\\', '/');
            // Streaming avoids loading entire project files into memory. UTF-8 is the library's default filename encoding.
            if (!mz_zip_writer_add_read_buf_callback(&zip, name.c_str(), readFile, &in, file.size, nullptr, nullptr, 0, MZ_BEST_SPEED, nullptr, 0, nullptr, 0))
                throw std::runtime_error("ZIP failed for " + name + ": " + mz_zip_get_error_string(mz_zip_get_last_error(&zip)));
            ++count;
            if (Clock::now() - update >= std::chrono::milliseconds(500)) {
                printf("\rCompressing: %zu / %zu files   ", count, selected.files.size()); fflush(stdout); update = Clock::now();
            }
        }
        if (!mz_zip_writer_finalize_archive(&zip)) throw std::runtime_error("Cannot finalize ZIP");
        mz_zip_writer_end(&zip);
        if (!FlushFileBuffers(out.value)) fail("Cannot flush ZIP", stage);
    } catch (...) { mz_zip_writer_end(&zip); throw; }
}
static void manifest(const std::wstring& path, const Selection& selected) {
    Handle f(CreateFileW(ioPath(fullPath(path)).c_str(), GENERIC_WRITE, 0, nullptr, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr));
    if (f.value == INVALID_HANDLE_VALUE) fail("Cannot create manifest", path);
    for (const auto& file : selected.files) {
        auto line = utf8(file.relative); std::replace(line.begin(), line.end(), '\\', '/'); line += '\n';
        DWORD written;
        if (!WriteFile(f.value, line.data(), static_cast<DWORD>(line.size()), &written, nullptr) || written != line.size()) fail("Cannot write manifest", path);
    }
}
int wmain(int argc, wchar_t** argv) {
    SetConsoleOutputCP(CP_UTF8);
    std::wstring stage;
    try {
        std::wstring source, output, manifestPath; bool scanOnly = false;
        for (int i = 1; i < argc; ++i) {
            std::wstring arg(argv[i]);
            if (arg == L"--no-ui") continue;
            else if (arg == L"--scan-only") scanOnly = true;
            else if (arg == L"--version") { puts("Clean Zip 2.0.0 (native)"); return 0; }
            else if ((arg == L"--path" || arg == L"--output" || arg == L"--manifest") && i + 1 < argc) {
                auto value = std::wstring(argv[++i]);
                if (arg == L"--path") source = value;
                else if (arg == L"--output") output = value;
                else manifestPath = value;
            } else throw std::runtime_error("Usage: CleanZip.exe --path <folder> [--output <zip>] [--scan-only] [--manifest <file>] [--no-ui]");
        }
        if (source.empty()) throw std::runtime_error("--path is required");
        auto root = fullPath(source);
        auto attributes = GetFileAttributesW(ioPath(root).c_str());
        if (root.size() <= 3 || attributes == INVALID_FILE_ATTRIBUTES || !(attributes & FILE_ATTRIBUTE_DIRECTORY)) throw std::runtime_error("Select a project folder, not a drive root");
        output = output.empty() ? root + L".zip" : fullPath(output);
        auto prefix = lower(root + L"\\");
        if (lower(output).rfind(prefix, 0) == 0 || lower(output) == lower(root)) throw std::runtime_error("Output must be outside the source folder");
        if (!manifestPath.empty() && (lower(fullPath(manifestPath)).rfind(prefix, 0) == 0 || lower(fullPath(manifestPath)) == lower(root))) throw std::runtime_error("Manifest must be outside the source folder");
        auto start = Clock::now(); Rules rules; rules.load(); Selection selected; selected.scan(root, rules);
        printf("\nSelected: %zu files, %.1f MB; skipped: %zu folders, %zu files/links; scan %.2f s\n", selected.files.size(), selected.bytes / 1048576.0, selected.skippedDirs, selected.skippedFiles, std::chrono::duration<double>(Clock::now()-start).count());
        if (!manifestPath.empty()) manifest(manifestPath, selected);
        if (scanOnly || selected.files.empty()) return 0;
        GUID id; if (FAILED(CoCreateGuid(&id))) throw std::runtime_error("Cannot create temporary ZIP name");
        wchar_t buf[40]; StringFromGUID2(id, buf, 40);
        stage = output + L"." + buf + L".tmp.zip";
        zipFiles(root, stage, selected);
        auto target = ioPath(output), temp = ioPath(stage);
        bool exists = GetFileAttributesW(target.c_str()) != INVALID_FILE_ATTRIBUTES;
        BOOL ok = exists ? ReplaceFileW(target.c_str(), temp.c_str(), nullptr, 0, nullptr, nullptr) : MoveFileExW(temp.c_str(), target.c_str(), MOVEFILE_WRITE_THROUGH);
        if (!ok) fail("Cannot commit ZIP; previous output preserved", output);
        stage.clear();
        printf("\nDone: %s\n%zu files; total %.2f s\n", utf8(output).c_str(), selected.files.size(), std::chrono::duration<double>(Clock::now()-start).count());
        return 0;
    } catch (const std::exception& e) {
        fprintf(stderr, "Clean Zip error: %s\n", e.what());
        if (!stage.empty()) DeleteFileW(ioPath(stage).c_str());
        return 1;
    }
}
