using System.Runtime.InteropServices;
using CleanZip.Shell;

internal static class Program
{
    [DllImport("ole32.dll")] private static extern int CoInitializeEx(IntPtr reserved, uint flags);
    [DllImport("ole32.dll")] private static extern void CoUninitialize();
    [DllImport("ole32.dll")] private static extern int CoCreateInstance(ref Guid clsid, IntPtr outer, uint context, ref Guid iid, [MarshalAs(UnmanagedType.Interface)] out IExplorerCommand command);
    [DllImport("shell32.dll", CharSet = CharSet.Unicode)] private static extern int SHCreateItemFromParsingName(string path, IntPtr context, ref Guid iid, [MarshalAs(UnmanagedType.Interface)] out IShellItem item);
    [DllImport("shell32.dll")] private static extern int SHCreateShellItemArrayFromShellItem(IShellItem item, ref Guid iid, [MarshalAs(UnmanagedType.Interface)] out IShellItemArray array);

    private static void Require(bool value, string message) { if (!value) throw new Exception(message); }
    [STAThread]
    private static void Main(string[] args)
    {
        Marshal.ThrowExceptionForHR(CoInitializeEx(IntPtr.Zero, 2));
        try
        {
            bool installed = args.Contains("--installed");
            IExplorerCommand command;
            if (installed)
            {
                Guid clsid = typeof(Command).GUID, iid = typeof(IExplorerCommand).GUID;
                Marshal.ThrowExceptionForHR(CoCreateInstance(ref clsid, IntPtr.Zero, 4, ref iid, out command));
            }
            else command = new Command();
            Require(command.GetTitle(null, out string title) == 0 && title == "Clean Zip", "Title mismatch");
            string root = Path.Combine(Path.GetTempPath(), "CleanZip-shell-test-" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(root);
            string project = Path.Combine(root, "unicode İ project");
            Directory.CreateDirectory(project);
            File.WriteAllText(Path.Combine(project, "source.cs"), "// source fixture");
            Directory.CreateDirectory(Path.Combine(project, "node_modules"));
            File.WriteAllText(Path.Combine(project, "node_modules", "dependency.js"), "excluded");
            File.WriteAllText(Path.Combine(project, "library.dll"), "excluded");
            try
            {
                Guid itemId = typeof(IShellItem).GUID, arrayId = typeof(IShellItemArray).GUID;
                Marshal.ThrowExceptionForHR(SHCreateItemFromParsingName(project, IntPtr.Zero, ref itemId, out IShellItem folder));
                Marshal.ThrowExceptionForHR(SHCreateShellItemArrayFromShellItem(folder, ref arrayId, out IShellItemArray selection));
                try
                {
                    Require(command.GetState(selection, false, out uint state) == 0 && state == 0, "Folder must be enabled");
                    if (installed)
                    {
                        Marshal.ThrowExceptionForHR(command.Invoke(selection, IntPtr.Zero));
                        string zip = project + ".zip";
                        for (int i = 0; i < 100 && !File.Exists(zip); i++) Thread.Sleep(100);
                        Require(File.Exists(zip), "Invocation did not create a ZIP");
                        using var archive = System.IO.Compression.ZipFile.OpenRead(zip);
                        Require(archive.Entries.Count == 1 && archive.Entries[0].FullName == "source.cs", "Invocation/exclusions mismatch");
                        using var reader = new StreamReader(archive.Entries[0].Open());
                        Require(reader.ReadToEnd() == "// source fixture", "ZIP data mismatch");
                    }
                }
                finally { Marshal.ReleaseComObject(selection); Marshal.ReleaseComObject(folder); }
                Marshal.ThrowExceptionForHR(SHCreateItemFromParsingName(Path.Combine(project, "source.cs"), IntPtr.Zero, ref itemId, out IShellItem file));
                Marshal.ThrowExceptionForHR(SHCreateShellItemArrayFromShellItem(file, ref arrayId, out IShellItemArray fileSelection));
                try { Require(command.GetState(fileSelection, false, out uint state) == 0 && state == 2, "File must be hidden"); }
                finally { Marshal.ReleaseComObject(fileSelection); Marshal.ReleaseComObject(file); }
                Console.WriteLine(installed ? "PASS: installed COM activation, title, folder/file state, Invoke, ZIP contents/data" : "PASS: shell title and native folder/file state");
            }
            finally { Directory.Delete(root, true); }
            if (installed) Marshal.ReleaseComObject(command);
        }
        finally { CoUninitialize(); }
    }
}
