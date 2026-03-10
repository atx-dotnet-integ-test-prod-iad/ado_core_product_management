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

Review the output for any warnings about packages that do not support the target framework or that have been resolved through compatibility shims.

## 3. Build the Solution

Perform a clean build to confirm the absence of errors is consistent:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types, deprecated APIs, or platform compatibility analyzers (CA1416, etc.).

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` results for any failures or unexpected skips that may indicate behavioral differences between the old and new runtime.

## 5. Check for Windows-Specific API Usage

Because this is a cross-platform migration, run the .NET Platform Compatibility Analyzer by ensuring the following property is present in `AdoCore.csproj`:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
```

Rebuild and look for CA1416 warnings, which indicate calls to APIs that are only supported on specific operating systems. Any such calls should be guarded with `OperatingSystem.IsWindows()` checks or replaced with cross-platform alternatives.

## 6. Validate ADO.NET or Data Access Behavior

Given the project name `AdoCore`, it likely contains data access logic. Confirm the following:

- The database driver NuGet package (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) targets .NET Standard 2.0 or later and is compatible with your chosen TFM.
- Connection strings and any configuration previously stored in `App.config` have been migrated to `appsettings.json` or environment variables, as `System.Configuration.ConfigurationManager` requires the additional `System.Configuration.ConfigurationManager` NuGet package on .NET Core and later.
- If `System.Configuration.ConfigurationManager` is in use, verify the package is referenced:

```xml
<PackageReference Include="System.Configuration.ConfigurationManager" Version="8.0.0" />
```

## 7. Test on Target Operating Systems

If cross-platform support is a goal, run the build and test steps on each intended operating system (Windows, Linux, macOS) to surface any remaining platform-specific issues.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be pre-installed on the target machine:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) for your target environment.

Review the contents of the `./publish` folder and deploy them to the target environment according to your hosting requirements.