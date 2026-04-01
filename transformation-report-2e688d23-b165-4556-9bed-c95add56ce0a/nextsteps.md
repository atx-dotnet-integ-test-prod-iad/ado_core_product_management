# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or incompatible packages and update them as needed using:

```bash
dotnet list package --outdated
dotnet add package <PackageName>
```

## 3. Build the Solution

Perform a full build to confirm there are no issues beyond what was reported:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Windows-Specific API Usage

Since this is a cross-platform migration, audit the codebase for APIs that are Windows-specific. Common areas to check include:

- `System.Windows.Forms` or `System.Drawing` (requires additional packages or may not be supported)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions (e.g., hardcoded backslashes)
- COM interop or P/Invoke calls targeting Windows DLLs

Use the .NET Upgrade Assistant or the compatibility analyzer to identify these:

```bash
dotnet add package Microsoft.DotNet.PlatformAbstractions
```

Or run the API compatibility analyzer:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch any runtime issues that do not surface at compile time.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime. For a self-contained deployment:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained true
```

Replace `<runtime-identifier>` with the appropriate value, such as `win-x64`, `linux-x64`, or `osx-x64`.

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

The output will be located in the `bin/Release/<TargetFramework>/publish/` directory.

## 8. Review Configuration Files

Ensure that any `app.config` or `web.config` files have been correctly migrated to `appsettings.json` or environment-based configuration, as the legacy XML-based configuration system has limited support in modern .NET.