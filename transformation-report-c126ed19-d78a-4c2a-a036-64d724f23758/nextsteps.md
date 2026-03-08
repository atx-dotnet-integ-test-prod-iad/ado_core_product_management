# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

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

Address any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not block the build.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review test results carefully. A successful build does not guarantee that runtime logic is functionally equivalent to the original .NET Framework version.

## 5. Check for Windows-Specific API Usage

Even without build errors, certain APIs may compile successfully but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Run the build again and review any new analyzer warnings related to platform-specific APIs such as the registry, `System.Drawing`, COM interop, or WCF.

## 6. Validate Runtime Behavior

Run the application and exercise its primary code paths. Pay particular attention to:

- **Database connectivity**: ADO.NET connection strings and provider names may differ between .NET Framework and .NET. Confirm the correct provider package (e.g., `Microsoft.Data.SqlClient`) is referenced and that connection strings are valid.
- **Configuration**: `System.Configuration.ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package on .NET. Verify that `app.config` or `appsettings.json` values are being read correctly.
- **Reflection and serialization**: Behavior differences exist between .NET Framework and .NET in these areas.

## 7. Review Removed or Changed APIs

Consult the official .NET migration guide for APIs that were removed or changed from .NET Framework:

- [Breaking changes in .NET](https://learn.microsoft.com/en-us/dotnet/core/compatibility/breaking-changes)
- [.NET Upgrade Assistant documentation](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview)

## 8. Publish the Application

Once validation is complete, publish the application for your target platform:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (RID) for your deployment target. A full list of RIDs is available at:

- [.NET RID Catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog)

Review the contents of the `publish` output directory before deploying to confirm all required assets are present.