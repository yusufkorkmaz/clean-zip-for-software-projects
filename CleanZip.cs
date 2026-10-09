using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Text;
using System.Windows.Forms;

public static class CleanZip {
    static readonly HashSet<string> directories = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
    static readonly HashSet<string> extensions = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
    static readonly HashSet<string> names = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
    static readonly List<string> suffixes = new List<string>();
    static readonly List<FileInfo> files = new List<FileInfo>();
    static int scanned, skippedDirectories, skippedFiles;
    static long bytes;
    static string root;
    static string Relative(FileInfo file) { return file.FullName.Substring(root.Length + 1); }
    static string Quote(string value) { return "\"" + value + "\""; }
    static void LoadRules() {
        string path = System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "CleanZip.rules.txt");
        foreach (string line in File.ReadAllLines(path)) {
            string rule = line.Trim();
            if (rule.Length < 3 || rule.StartsWith("#")) continue;
            string value = rule.Substring(2);
            switch (rule.Substring(0, 2)) {
                case "d:": directories.Add(value); break;
                case "e:": extensions.Add(value); break;
                case "f:": names.Add(value); break;
                case "s:": suffixes.Add(value); break;
                default: throw new InvalidDataException("Unknown rule: " + rule);
            }
        }
    }
    static bool MatchesSuffix(string name) {
        foreach (string suffix in suffixes)
            if (name.EndsWith(suffix, StringComparison.OrdinalIgnoreCase)) return true;
        return false;
    }
    static void Scan() {
        var pending = new Stack<DirectoryInfo>();
        pending.Push(new DirectoryInfo(root));
        var timer = Stopwatch.StartNew();
        long lastUpdate = 0;
        while (pending.Count != 0) {
            var directory = pending.Pop();
            scanned++;
            foreach (FileSystemInfo item in directory.EnumerateFileSystemInfos()) {
                if ((item.Attributes & FileAttributes.ReparsePoint) != 0) {
                    skippedFiles++;
                    continue;
                }
                if ((item.Attributes & FileAttributes.Directory) != 0) {
                    if (directories.Contains(item.Name)) skippedDirectories++;
                    else pending.Push((DirectoryInfo)item);
                } else {
                    var file = (FileInfo)item;
                    if (extensions.Contains(file.Extension) || names.Contains(file.Name) || MatchesSuffix(file.Name) ||
                        file.Name.IndexOf(".so.", StringComparison.OrdinalIgnoreCase) >= 0) {
                        skippedFiles++;
                        continue;
                    }
                    files.Add(file);
                    bytes += file.Length;
                }
            }
            if (timer.ElapsedMilliseconds - lastUpdate >= 500) {
                Console.Write("\rTaraniyor: {0} klasor, {1} secilen dosya   ", scanned, files.Count);
                lastUpdate = timer.ElapsedMilliseconds;
            }
        }
        Console.WriteLine("\nTarama: {0:F2} sn | {1} dosya | {2:F1} MB", timer.Elapsed.TotalSeconds, files.Count, bytes / 1048576.0);
        Console.WriteLine("Haric: {0} klasor (iclerine girilmedi), {1} dosya/baglanti", skippedDirectories, skippedFiles);
    }
    static void Preview() {
        Console.WriteLine("\nSecilen uzantilar:");
        foreach (var group in files.GroupBy(f => f.Extension.ToLowerInvariant()).OrderByDescending(g => g.Sum(f => f.Length)).Take(15))
            Console.WriteLine("{0,-16} {1,7} dosya {2,10:F1} MB", group.Key == "" ? "(uzantisiz)" : group.Key, group.Count(), group.Sum(f => f.Length) / 1048576.0);
        Console.WriteLine("\nEn buyuk secilen dosyalar:");
        foreach (var file in files.OrderByDescending(f => f.Length).Take(15))
            Console.WriteLine("{0,10:F1} MB  {1}", file.Length / 1048576.0, Relative(file));
    }
    static void Compress(string stage) {
        string sevenZip = System.IO.Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "7-Zip", "7z.exe");
        if (File.Exists(sevenZip)) {
            string list = System.IO.Path.Combine(System.IO.Path.GetTempPath(), "CleanZip-" + Guid.NewGuid().ToString("N") + ".txt");
            try {
                File.WriteAllLines(list, files.Select(Relative), new UTF8Encoding(false));
                var start = new ProcessStartInfo(sevenZip,
                    "a -tzip -mx=1 -mcu=on -mmt=on -scsUTF-8 -spd -bsp1 -bso1 -bse1 " + Quote(stage) + " @" + Quote(list));
                start.UseShellExecute = false;
                start.WorkingDirectory = root;
                using (Process process = Process.Start(start)) {
                    process.WaitForExit();
                    if (process.ExitCode != 0) throw new IOException("7-Zip exit code: " + process.ExitCode);
                }
            } finally { if (File.Exists(list)) File.Delete(list); }
        } else {
            Console.WriteLine("7-Zip bulunamadi, .NET ile zipleniyor...");
            var timer = Stopwatch.StartNew();
            long lastUpdate = 0;
            using (var archive = ZipFile.Open(stage, ZipArchiveMode.Create)) {
                int count = 0;
                foreach (var file in files) {
                    archive.CreateEntryFromFile(file.FullName, Relative(file).Replace('\\', '/'), CompressionLevel.Fastest);
                    count++;
                    if (timer.ElapsedMilliseconds - lastUpdate >= 500) {
                        Console.Write("\rZipleniyor: {0}/{1}   ", count, files.Count);
                        lastUpdate = timer.ElapsedMilliseconds;
                    }
                }
            }
        }
    }
    public static int Main(string[] args) {
        bool noUI = false, scanOnly = false;
        string source = null, manifest = null, stage = null, outputOverride = null;
        var total = Stopwatch.StartNew();
        try {
            Console.WriteLine("Clean Zip baslatildi...");
            for (int i = 0; i < args.Length; i++) {
                switch (args[i]) {
                    case "--path": source = args[++i]; break;
                    case "--no-ui": noUI = true; break;
                    case "--scan-only": scanOnly = true; noUI = true; break;
                    case "--manifest": manifest = args[++i]; break;
                    case "--output": outputOverride = args[++i]; break;
                    default: throw new ArgumentException("Unknown argument: " + args[i]);
                }
            }
            if (source == null) throw new ArgumentException("--path is required.");
            root = System.IO.Path.GetFullPath(source).TrimEnd('\\', '/');
            if (!Directory.Exists(root) || root.Length < 4) throw new ArgumentException("Select a project directory.");
            Console.WriteLine("Proje: " + root);
            LoadRules();
            Scan();
            if (manifest != null) File.WriteAllLines(manifest, files.Select(f => Relative(f).Replace('\\', '/')), new UTF8Encoding(false));
            if (scanOnly) { Preview(); return 0; }
            if (files.Count == 0) { Console.WriteLine("Zip olusturulmadi: eklenecek dosya yok."); return 0; }
            string output = outputOverride == null ? root + ".zip" : System.IO.Path.GetFullPath(outputOverride);
            if (output.StartsWith(root + System.IO.Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase))
                throw new ArgumentException("Output must be outside the source directory.");
            stage = output + "." + Guid.NewGuid().ToString("N") + ".tmp.zip";
            var compress = Stopwatch.StartNew();
            Compress(stage);
            if (File.Exists(output)) File.Replace(stage, output, null);
            else File.Move(stage, output);
            stage = null;
            string summary = String.Format("Zip: {0}\nEklenen: {1} dosya\nSikistirma: {2:F2} sn\nToplam: {3:F2} sn", output, files.Count, compress.Elapsed.TotalSeconds, total.Elapsed.TotalSeconds);
            Console.WriteLine("\nTamamlandi.\n" + summary);
            if (!noUI) MessageBox.Show(summary, "Clean Zip");
            return 0;
        } catch (Exception error) {
            Console.Error.WriteLine("Clean Zip hata: " + error.Message);
            if (!noUI) MessageBox.Show(error.Message, "Clean Zip hata", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        } finally { if (stage != null && File.Exists(stage)) File.Delete(stage); }
    }
}
