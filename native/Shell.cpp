#include <windows.h>
#include <shobjidl.h>
#include <shlwapi.h>
#include <string>
#include <vector>
#include <new>

static HMODULE module;
static LONG objects = 0;
static const CLSID commandId = {0xad9a2d5b,0xbb56,0x48a1,{0x84,0x43,0xa3,0x9f,0x9c,0x84,0x65,0xdf}};
template<class T> struct Ptr {
    T* value = nullptr;
    ~Ptr() { if (value) value->Release(); }
    T** put() { return &value; }
    T* operator->() const { return value; }
};
static std::wstring directory() {
    std::vector<wchar_t> buffer(32768);
    DWORD n = GetModuleFileNameW(module, buffer.data(), static_cast<DWORD>(buffer.size()));
    if (!n || n >= buffer.size()) return {};
    std::wstring path(buffer.data(), n);
    path.erase(path.find_last_of(L'\\'));
    path.erase(path.find_last_of(L'\\')); // DLL resides in a versioned modern folder next to the engine.
    return path;
}
class Command final : public IExplorerCommand, public IObjectWithSite {
    LONG references = 1;
    IUnknown* site = nullptr;
    HRESULT folder(IShellItem* item, std::wstring& result) {
        SFGAOF attributes;
        HRESULT hr = item->GetAttributes(SFGAO_FOLDER | SFGAO_FILESYSTEM, &attributes);
        if (FAILED(hr) || (attributes & (SFGAO_FOLDER | SFGAO_FILESYSTEM)) != (SFGAO_FOLDER | SFGAO_FILESYSTEM)) return E_INVALIDARG;
        PWSTR path = nullptr;
        hr = item->GetDisplayName(SIGDN_FILESYSPATH, &path);
        if (SUCCEEDED(hr)) { result = path; CoTaskMemFree(path); }
        return hr;
    }
    HRESULT resolve(IShellItemArray* items, std::wstring& path) {
        if (items) {
            DWORD count; HRESULT hr = items->GetCount(&count);
            if (FAILED(hr) || count > 1) return E_INVALIDARG;
            if (count == 1) {
                Ptr<IShellItem> item;
                hr = items->GetItemAt(0, item.put());
                return FAILED(hr) ? hr : folder(item.value, path);
            }
        }
        if (!site) return E_FAIL;
        Ptr<IServiceProvider> services;
        HRESULT hr = site->QueryInterface(IID_PPV_ARGS(services.put()));
        if (FAILED(hr)) return hr;
        Ptr<IFolderView> view;
        hr = services->QueryService(IID_IFolderView, IID_PPV_ARGS(view.put()));
        if (FAILED(hr)) return hr;
        Ptr<IPersistFolder2> persist;
        hr = view->GetFolder(IID_PPV_ARGS(persist.put()));
        if (FAILED(hr)) return hr;
        PIDLIST_ABSOLUTE pidl = nullptr;
        hr = persist->GetCurFolder(&pidl);
        if (FAILED(hr)) return hr;
        Ptr<IShellItem> item;
        hr = SHCreateItemFromIDList(pidl, IID_PPV_ARGS(item.put()));
        CoTaskMemFree(pidl);
        return FAILED(hr) ? hr : folder(item.value, path);
    }
public:
    Command() { InterlockedIncrement(&objects); }
    ~Command() { if (site) site->Release(); InterlockedDecrement(&objects); }
    IFACEMETHODIMP QueryInterface(REFIID iid, void** out) override {
        if (!out) return E_POINTER;
        *out = nullptr;
        if (iid == IID_IUnknown || iid == IID_IExplorerCommand) *out = static_cast<IExplorerCommand*>(this);
        else if (iid == IID_IObjectWithSite) *out = static_cast<IObjectWithSite*>(this);
        else return E_NOINTERFACE;
        AddRef(); return S_OK;
    }
    IFACEMETHODIMP_(ULONG) AddRef() override { return InterlockedIncrement(&references); }
    IFACEMETHODIMP_(ULONG) Release() override {
        LONG count = InterlockedDecrement(&references); if (!count) delete this; return count;
    }
    IFACEMETHODIMP SetSite(IUnknown* value) override {
        if (value) value->AddRef();
        if (site) site->Release();
        site = value; return S_OK;
    }
    IFACEMETHODIMP GetSite(REFIID iid, void** result) override {
        if (!result) return E_POINTER;
        *result = nullptr;
        return site ? site->QueryInterface(iid, result) : E_FAIL;
    }
    IFACEMETHODIMP GetTitle(IShellItemArray*, PWSTR* title) override { return SHStrDupW(L"Clean Zip", title); }
    IFACEMETHODIMP GetIcon(IShellItemArray*, PWSTR* icon) override {
        try { return SHStrDupW((directory() + L"\\Assets\\CleanZip.ico").c_str(), icon); }
        catch (...) { return E_OUTOFMEMORY; }
    }
    IFACEMETHODIMP GetToolTip(IShellItemArray*, PWSTR* tip) override { return SHStrDupW(L"Zip software project source files", tip); }
    IFACEMETHODIMP GetCanonicalName(GUID* name) override { if (!name) return E_POINTER; *name = commandId; return S_OK; }
    IFACEMETHODIMP GetState(IShellItemArray* items, BOOL, EXPCMDSTATE* state) override {
        if (!state) return E_POINTER;
        *state = ECS_HIDDEN;
        // Resolving one shell item never enumerates or scans the project.
        try { std::wstring path; if (SUCCEEDED(resolve(items, path))) *state = ECS_ENABLED; }
        catch (...) { }
        return S_OK;
    }
    IFACEMETHODIMP Invoke(IShellItemArray* items, IBindCtx*) override {
        try {
            std::wstring path; HRESULT hr = resolve(items, path); if (FAILED(hr)) return hr;
            auto root = directory(), engine = root + L"\\CleanZip.exe";
            // Windows filenames cannot contain a quote; avoid a trailing slash before a closing quote.
            while (path.size() > 3 && path.back() == L'\\') path.pop_back();
            if (path.size() <= 3) return E_INVALIDARG;
            std::wstring args = L"\"" + engine + L"\" --path \"" + path + L"\" --no-ui";
            STARTUPINFOW startup = {}; startup.cb = sizeof(startup); PROCESS_INFORMATION process = {};
            if (!CreateProcessW(engine.c_str(), &args[0], nullptr, nullptr, FALSE, CREATE_NEW_CONSOLE, nullptr, root.c_str(), &startup, &process)) return HRESULT_FROM_WIN32(GetLastError());
            CloseHandle(process.hThread); CloseHandle(process.hProcess); return S_OK;
        } catch (...) { return E_OUTOFMEMORY; }
    }
    IFACEMETHODIMP GetFlags(EXPCMDFLAGS* flags) override { if (!flags) return E_POINTER; *flags = ECF_DEFAULT; return S_OK; }
    IFACEMETHODIMP EnumSubCommands(IEnumExplorerCommand** result) override { if (result) *result = nullptr; return E_NOTIMPL; }
};
class Factory final : public IClassFactory {
    LONG references = 1;
public:
    Factory() { InterlockedIncrement(&objects); }
    ~Factory() { InterlockedDecrement(&objects); }
    IFACEMETHODIMP QueryInterface(REFIID iid, void** out) override {
        if (!out) return E_POINTER; *out = nullptr;
        if (iid != IID_IUnknown && iid != IID_IClassFactory) return E_NOINTERFACE;
        *out = static_cast<IClassFactory*>(this); AddRef(); return S_OK;
    }
    IFACEMETHODIMP_(ULONG) AddRef() override { return InterlockedIncrement(&references); }
    IFACEMETHODIMP_(ULONG) Release() override { LONG n = InterlockedDecrement(&references); if (!n) delete this; return n; }
    IFACEMETHODIMP CreateInstance(IUnknown* outer, REFIID iid, void** out) override {
        if (outer) return CLASS_E_NOAGGREGATION;
        auto command = new (std::nothrow) Command;
        if (!command) return E_OUTOFMEMORY;
        HRESULT hr = command->QueryInterface(iid, out); command->Release(); return hr;
    }
    IFACEMETHODIMP LockServer(BOOL lock) override { if (lock) InterlockedIncrement(&objects); else InterlockedDecrement(&objects); return S_OK; }
};
extern "C" HRESULT WINAPI DllGetClassObject(REFCLSID clsid, REFIID iid, void** out) {
    if (clsid != commandId) return CLASS_E_CLASSNOTAVAILABLE;
    auto factory = new (std::nothrow) Factory;
    if (!factory) return E_OUTOFMEMORY;
    HRESULT hr = factory->QueryInterface(iid, out); factory->Release(); return hr;
}
extern "C" HRESULT WINAPI DllCanUnloadNow() { return InterlockedCompareExchange(&objects, 0, 0) == 0 ? S_OK : S_FALSE; }
BOOL WINAPI DllMain(HINSTANCE instance, DWORD reason, LPVOID) {
    if (reason == DLL_PROCESS_ATTACH) { module = instance; DisableThreadLibraryCalls(instance); }
    return TRUE;
}
