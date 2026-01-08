# Required VC++ Runtime DLLs

These DLLs are required for the Windows installer to work without requiring users to install VC++ Redistributable.

## Included Files

1. **vcruntime140.dll** (~100 KB)
2. **vcruntime140_1.dll** (~40 KB)

## Why These DLLs?

Flutter Windows apps require the Visual C++ 2015-2022 Runtime. By bundling these DLLs with the installer, users don't need to install the VC++ Redistributable separately.

## Updating DLLs

If you need to update these DLLs, copy from Windows System32:
```batch
copy "C:\Windows\System32\vcruntime140.dll" .
copy "C:\Windows\System32\vcruntime140_1.dll" .
```

Or download from: https://aka.ms/vs/17/release/vc_redist.x64.exe
