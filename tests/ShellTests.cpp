#include <windows.h>
#include <shobjidl.h>
#include <cstdio>
#include <string>
static const CLSID id = {0xad9a2d5b,0xbb56,0x48a1,{0x84,0x43,0xa3,0x9f,0x9c,0x84,0x65,0xdf}};
int wmain(int argc, wchar_t** argv) {
    if (argc < 4) { puts("ShellTests <dll|--installed> <folder> <file> [--invoke]"); return 2; }
    HRESULT init = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
    if (FAILED(init)) return 3;
    IExplorerCommand* command = nullptr; HMODULE module = nullptr;
    HRESULT hr;
    if (std::wstring(argv[1]) == L"--installed") hr = CoCreateInstance(id, nullptr, CLSCTX_LOCAL_SERVER, IID_PPV_ARGS(&command));
    else {
        module = LoadLibraryW(argv[1]); if (!module) return 4;
        auto get = reinterpret_cast<HRESULT(WINAPI*)(REFCLSID,REFIID,void**)>(GetProcAddress(module,"DllGetClassObject"));
        if (!get) return 5;
        IClassFactory* factory = nullptr;
        hr = get(id, IID_PPV_ARGS(&factory));
        if (SUCCEEDED(hr)) { hr = factory->CreateInstance(nullptr, IID_PPV_ARGS(&command)); factory->Release(); }
    }
    if (FAILED(hr)) { printf("Activation failed: %08lx\n",hr); return 6; }
    PWSTR title = nullptr; hr = command->GetTitle(nullptr,&title);
    bool ok = SUCCEEDED(hr) && title && std::wstring(title) == L"Clean Zip"; CoTaskMemFree(title);
    for (int index = 2; index < 4; ++index) {
        IShellItem* item = nullptr; IShellItemArray* array = nullptr;
        hr = SHCreateItemFromParsingName(argv[index], nullptr, IID_PPV_ARGS(&item));
        if (SUCCEEDED(hr)) { hr = SHCreateShellItemArrayFromShellItem(item, IID_PPV_ARGS(&array)); item->Release(); }
        EXPCMDSTATE state = ECS_HIDDEN;
        if (SUCCEEDED(hr)) {
            hr = command->GetState(array,FALSE,&state);
            ok = ok && SUCCEEDED(hr) && state == (index == 2 ? ECS_ENABLED : ECS_HIDDEN);
            if (index == 2 && argc > 4 && std::wstring(argv[4]) == L"--invoke") ok = ok && SUCCEEDED(command->Invoke(array,nullptr));
            array->Release();
        } else ok = false;
    }
    command->Release(); if (module) FreeLibrary(module); CoUninitialize();
    puts(ok ? "PASS: native COM activation, title, folder enabled and file hidden" : "FAIL: native shell tests");
    return ok ? 0 : 1;
}
