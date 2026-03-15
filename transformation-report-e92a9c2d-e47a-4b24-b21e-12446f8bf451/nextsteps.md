# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on all machines that will build or run this project.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts.

## 3. Build the Solution

Perform a full build to confirm there are no issues beyond what was captured in the initial error report:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete API usage, as these can indicate areas that may cause runtime issues.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release
```

Pay close attention to any tests that interact with file paths, platform-specific APIs, or Windows registry access, as these are common areas where cross-platform issues surface at runtime rather than compile time.

## 5. Check for Platform-Specific API Usage

Even without build errors, runtime failures can occur if the code uses Windows-specific APIs. Search the codebase for usages of the following and verify they are either replaced or guarded with platform checks:

- `Microsoft.Win32` namespace
- `System.Windows.Forms` or `System.Drawing` (unless using the compatible NuGet packages)
- P/Invoke calls to Windows DLLs such as `kernel32.dll`, `user32.dll`, etc.
- `Environment.SpecialFolder` paths that may differ across operating systems

Use the `RuntimeInformation.IsOSPlatform` API to conditionally execute platform-specific code where removal is not feasible.

## 6. Validate Configuration and File Paths

Review any hardcoded file paths or configuration values. Replace Windows-style backslash paths with `Path.Combine` or forward-slash equivalents to ensure compatibility across operating systems.

## 7. Test on Target Platforms

Run the application on each operating system you intend to support (e.g., Linux, macOS) to catch any runtime issues that would not appear on Windows. Pay particular attention to:

- File system case sensitivity (Linux is case-sensitive)
- Line ending differences (`\r\n` vs `\n`)
- Culture and locale-sensitive string operations

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate RID for your deployment target. A full list of runtime identifiers is available in the [.NET RID catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).