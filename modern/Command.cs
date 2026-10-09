using System.Diagnostics;
using System.Runtime.InteropServices;

namespace CleanZip.Shell;

[ComVisible(true), Guid("AD9A2D5B-BB56-48A1-8443-A39F9C8465DF"), ClassInterface(ClassInterfaceType.None)]
public sealed class Command : IExplorerCommand, IObjectWithSite
{
    private object? site;
    private static readonly Guid ClassId = typeof(Command).GUID;
    private static string InstallationDirectory => Path.GetDirectoryName(Path.GetDirectoryName(typeof(Command).Assembly.Location))!;

    public int GetTitle(IShellItemArray? items, out string title) { title = "Clean Zip"; return 0; }
    public int GetIcon(IShellItemArray? items, out string icon) { icon = Path.Combine(InstallationDirectory, "Assets", "CleanZip.ico"); return 0; }
    public int GetToolTip(IShellItemArray? items, out string tip) { tip = "Zip project source files using Clean Zip exclusions"; return 0; }
    public int GetCanonicalName(out Guid name) { name = ClassId; return 0; }
    public int GetFlags(out uint flags) { flags = 0; return 0; }
    public int EnumSubCommands(out IntPtr commands) { commands = IntPtr.Zero; return unchecked((int)0x80004001); }
    public int SetSite(object? value) { site = value; return 0; }
    public int GetSite(ref Guid iid, out IntPtr value)
    {
        value = IntPtr.Zero;
        if (site is null) return unchecked((int)0x80004005);
        IntPtr unknown = Marshal.GetIUnknownForObject(site);
        try { return Marshal.QueryInterface(unknown, in iid, out value); }
        finally { Marshal.Release(unknown); }
    }

    public int GetState(IShellItemArray? items, bool slow, out uint state)
    {
        // Inspect only the selected shell item. Never enumerate project files while opening a menu.
        try { state = ResolvePath(items) is null ? 2u : 0u; }
        catch { state = 2; }
        return 0;
    }

    public int Invoke(IShellItemArray? items, IntPtr bindContext)
    {
        try
        {
            string? path = ResolvePath(items);
            if (path is null) return unchecked((int)0x80070057);
            string engine = Path.Combine(InstallationDirectory, "CleanZip.exe");
            // The existing engine owns scanning/compression and exits without a completion alert.
            var start = new ProcessStartInfo(engine) { UseShellExecute = true, WorkingDirectory = InstallationDirectory };
            start.ArgumentList.Add("--path");
            start.ArgumentList.Add(path);
            start.ArgumentList.Add("--no-ui");
            Process.Start(start);
            return 0;
        }
        catch (Exception error) { return Marshal.GetHRForException(error); }
    }

    private string? ResolvePath(IShellItemArray? items)
    {
        if (items is not null)
        {
            if (items.GetCount(out uint count) < 0 || count > 1) return null;
            if (count == 1)
            {
                if (items.GetItemAt(0, out IShellItem item) < 0) return null;
                try { return FileSystemFolder(item); }
                finally { Marshal.ReleaseComObject(item); }
            }
        }
        // Folder background and Desktop background: obtain the active view from the command's site.
        if (site is not IServiceProvider services) return null;
        Guid folderViewId = typeof(IFolderView).GUID;
        if (services.QueryService(ref folderViewId, ref folderViewId, out object viewObject) < 0) return null;
        try
        {
            var view = (IFolderView)viewObject;
            Guid persistId = typeof(IPersistFolder2).GUID;
            if (view.GetFolder(ref persistId, out object folderObject) < 0) return null;
            try
            {
                if (((IPersistFolder2)folderObject).GetCurFolder(out IntPtr pidl) < 0) return null;
                try
                {
                    Guid shellItemId = typeof(IShellItem).GUID;
                    if (SHCreateItemFromIDList(pidl, ref shellItemId, out IShellItem item) < 0) return null;
                    try { return FileSystemFolder(item); }
                    finally { Marshal.ReleaseComObject(item); }
                }
                finally { Marshal.FreeCoTaskMem(pidl); }
            }
            finally { Marshal.ReleaseComObject(folderObject); }
        }
        finally { Marshal.ReleaseComObject(viewObject); }
    }

    private static string? FileSystemFolder(IShellItem item)
    {
        const uint flags = 0x60000000; // SFGAO_FOLDER | SFGAO_FILESYSTEM
        if (item.GetAttributes(flags, out uint attributes) < 0 || (attributes & flags) != flags) return null;
        return item.GetDisplayName(0x80058000, out string path) < 0 ? null : path; // SIGDN_FILESYSPATH
    }

    [DllImport("shell32.dll", PreserveSig = true)]
    private static extern int SHCreateItemFromIDList(IntPtr pidl, ref Guid iid, [MarshalAs(UnmanagedType.Interface)] out IShellItem item);
}

[ComVisible(true), Guid("A08CE4D0-FA25-44AB-B57C-C7B1C323E0B9"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IExplorerCommand
{
    [PreserveSig] int GetTitle(IShellItemArray? items, [MarshalAs(UnmanagedType.LPWStr)] out string title);
    [PreserveSig] int GetIcon(IShellItemArray? items, [MarshalAs(UnmanagedType.LPWStr)] out string icon);
    [PreserveSig] int GetToolTip(IShellItemArray? items, [MarshalAs(UnmanagedType.LPWStr)] out string tip);
    [PreserveSig] int GetCanonicalName(out Guid name);
    [PreserveSig] int GetState(IShellItemArray? items, [MarshalAs(UnmanagedType.Bool)] bool slow, out uint state);
    [PreserveSig] int Invoke(IShellItemArray? items, IntPtr bindContext);
    [PreserveSig] int GetFlags(out uint flags);
    [PreserveSig] int EnumSubCommands(out IntPtr commands);
}

[ComVisible(true), Guid("FC4801A3-2BA9-11CF-A229-00AA003D7352"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IObjectWithSite
{
    [PreserveSig] int SetSite([MarshalAs(UnmanagedType.IUnknown)] object? site);
    [PreserveSig] int GetSite(ref Guid iid, out IntPtr site);
}

[ComImport, Guid("43826D1E-E718-42EE-BC55-A1E261C37BFE"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IShellItem
{
    [PreserveSig] int BindToHandler(IntPtr context, ref Guid handler, ref Guid iid, out IntPtr result);
    [PreserveSig] int GetParent(out IShellItem parent);
    [PreserveSig] int GetDisplayName(uint kind, [MarshalAs(UnmanagedType.LPWStr)] out string name);
    [PreserveSig] int GetAttributes(uint mask, out uint attributes);
    [PreserveSig] int Compare(IShellItem other, uint hint, out int order);
}

[ComImport, Guid("B63EA76D-1F85-456F-A19C-48159EFA858B"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IShellItemArray
{
    [PreserveSig] int BindToHandler(IntPtr context, ref Guid handler, ref Guid iid, out IntPtr result);
    [PreserveSig] int GetPropertyStore(int flags, ref Guid iid, out IntPtr result);
    [PreserveSig] int GetPropertyDescriptionList(IntPtr key, ref Guid iid, out IntPtr result);
    [PreserveSig] int GetAttributes(uint flags, uint mask, out uint attributes);
    [PreserveSig] int GetCount(out uint count);
    [PreserveSig] int GetItemAt(uint index, out IShellItem item);
    [PreserveSig] int EnumItems(out IntPtr items);
}

[ComImport, Guid("6D5140C1-7436-11CE-8034-00AA006009FA"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
internal interface IServiceProvider
{
    [PreserveSig] int QueryService(ref Guid service, ref Guid iid, [MarshalAs(UnmanagedType.IUnknown)] out object result);
}

[ComImport, Guid("CDE725B0-CCC9-4519-917E-325D72FAB4CE"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
internal interface IFolderView
{
    [PreserveSig] int GetCurrentViewMode(out uint mode);
    [PreserveSig] int SetCurrentViewMode(uint mode);
    [PreserveSig] int GetFolder(ref Guid iid, [MarshalAs(UnmanagedType.IUnknown)] out object folder);
}

[ComImport, Guid("1AC3D9F0-175C-11D1-95BE-00609797EA4F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
internal interface IPersistFolder2
{
    [PreserveSig] int GetClassID(out Guid clsid);
    [PreserveSig] int Initialize(IntPtr pidl);
    [PreserveSig] int GetCurFolder(out IntPtr pidl);
}
