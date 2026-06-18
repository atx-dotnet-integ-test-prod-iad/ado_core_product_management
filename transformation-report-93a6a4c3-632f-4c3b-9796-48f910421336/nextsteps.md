# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Review Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this matches the version of the .NET SDK you have installed. You can verify your installed SDKs by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any dependency conflicts or packages that could not be resolved.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to obsolete APIs or platform compatibility (CA1416, etc.), as these may indicate runtime issues on specific operating systems.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures after a cross-platform migration often point to:
- Platform-specific API usage (Windows registry, COM interop, `System.Drawing`, etc.)
- Path separator differences (`\` vs `/`)
- Case-sensitivity differences in file system access

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer to surface any remaining platform-specific calls. This is already included in the .NET SDK. Build with the following property set in the `.csproj` to enable stricter analysis:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Pay particular attention to warnings prefixed with `CA1416` (platform compatibility).

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) to confirm runtime behavior is consistent. At minimum, exercise the primary code paths of `AdoCore` to verify database connectivity and query execution behave as expected, since ADO.NET behavior can differ slightly depending on the database driver and platform.

## 7. Verify Database Driver Compatibility

Confirm that the ADO.NET provider (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) referenced by the project has a version that supports the target .NET TFM. Check the package's NuGet page or release notes to confirm cross-platform support.

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate Runtime Identifier (RID) for your deployment target. A full list of RIDs is available in the [.NET RID Catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).

Use `--self-contained true` if the target machine does not have the .NET runtime installed, keeping in mind this will increase the output size.