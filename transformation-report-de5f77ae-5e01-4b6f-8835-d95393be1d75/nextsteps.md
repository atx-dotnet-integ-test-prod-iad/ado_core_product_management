# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:
```xml
<TargetFramework>net8.0</TargetFramework>
```
Ensure no projects are still referencing `net4x` or `netstandard` unless that is intentional.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:
```bash
dotnet restore
dotnet build --configuration Release
```
Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:
```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```
Review any failing tests and address them before proceeding.

### 4. Check NuGet Package Compatibility
Open each `.csproj` file and review the `<PackageReference>` entries. For any package that was previously a legacy `.dll` reference or a packages.config entry, confirm the NuGet package version is compatible with the target framework. You can use the following command to check for outdated packages:
```bash
dotnet list package --outdated
```

### 5. Review Removed or Changed APIs
Cross-platform .NET removes or changes certain APIs that were available in .NET Framework. Run the .NET Upgrade Assistant compatibility analyzer or the platform compatibility analyzer to surface any runtime-level issues:
```bash
dotnet tool install -g dotnet-upgrade-assistant
upgrade-assistant analyze <solution>.sln
```
Pay particular attention to:
- `System.Web` usages
- Windows-specific APIs (Registry, WinForms, WPF) if cross-platform execution is required
- `AppDomain`, `BinaryFormatter`, and `Remoting` APIs

### 6. Validate Configuration Files
If the project previously used `app.config` or `web.config`, confirm that settings have been migrated to `appsettings.json` or the appropriate .NET configuration model. Verify that `ConfigurationManager` references have been updated if applicable.

### 7. Test on Target Platform
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that static analysis may not catch.

## Deployment Steps

### 1. Publish the Application
Use the `dotnet publish` command to produce deployment artifacts:
```bash
dotnet publish --configuration Release --output ./publish
```
For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:
```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```
Replace `win-x64` with the appropriate runtime identifier for your target environment (e.g., `linux-x64`, `osx-x64`).

### 2. Verify Published Output
Navigate to the `./publish` directory and confirm all expected files are present, including configuration files, static assets, and any native dependencies.

### 3. Smoke Test the Published Output
Run the published executable directly to confirm it starts and operates correctly outside of the development environment:
```bash
./publish/AdoCore
```
Validate core functionality manually or through integration tests against the published artifacts.