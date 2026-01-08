# Required VC++ Runtime DLLs

Place the following DLLs in this folder before building the installer:

## Required Files

1. **vcruntime140.dll** (~100 KB)
2. **vcruntime140_1.dll** (~40 KB)

## Where to Get These DLLs

### Option 1: Copy from Windows System (Recommended)
```batch
copy "C:\Windows\System32\vcruntime140.dll" .
copy "C:\Windows\System32\vcruntime140_1.dll" .
```

### Option 2: Extract from VC++ Redistributable
1. Download from: https://aka.ms/vs/17/release/vc_redist.x64.exe
2. Extract using 7-Zip or similar tool
3. Find the DLLs inside the extracted files

## Why These DLLs?

Flutter Windows apps require the Visual C++ 2015-2022 Runtime. By bundling these DLLs with the installer, users don't need to install the VC++ Redistributable separately.

## Note

Do NOT commit the actual DLL files to git - they are binary files and should be added during the build process.
