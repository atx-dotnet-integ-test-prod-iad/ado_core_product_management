# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework. Replace any packages that only support `.NET Framework` with their cross-platform equivalents if warnings are present.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review the build output for any warnings, particularly:
- `CS0618` (obsolete API usage)
- `CS8600`–`CS8625` (nullable reference type warnings, if nullable is enabled)
- Platform compatibility warnings (e.g., `CA1416`)

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Pay attention to any tests that were previously passing and are now failing, as these may indicate behavioral differences between .NET Framework and modern .NET.

## 5. Check for Windows-Specific API Usage

Since this is a cross-platform migration, audit the code for APIs that are Windows-only. You can use the .NET Compatibility Analyzer by ensuring your project has the following in the `.csproj`:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Rebuild and review any `CA1416` warnings, which flag Windows-specific API calls that will not function on Linux or macOS.

## 6. Validate ADO-Specific Functionality

Given the project name `AdoCore`, it likely involves ADO.NET data access. Verify the following:

- Connection strings are environment-appropriate and not hardcoded for a Windows environment.
- Any use of `System.Data.OleDb` or `System.Data.Odbc` is reviewed, as these have limited or no support on non-Windows platforms.
- If `System.Data.SqlClient` was used, confirm migration to `Microsoft.Data.SqlClient`, which is the actively maintained cross-platform package:

```bash
dotnet add package Microsoft.Data.SqlClient
```

Update any `using System.Data.SqlClient;` references to `using Microsoft.Data.SqlClient;` throughout the codebase.

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch any runtime platform-specific issues that static analysis may not surface.

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application for your target platform:

**Framework-dependent (requires .NET runtime on target machine):**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, `osx-arm64`, etc.) as needed. A full list of runtime identifiers is available in the [.NET RID Catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).