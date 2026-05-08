# Next Steps

The solution has no build errors following the transformation. Below are steps to validate, test, and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If it still references a Windows-only TFM such as `net472` or `net48`, update it accordingly.

## 2. Review NuGet Package Compatibility

Run the following command to check for any packages that may not fully support the target framework:

```bash
dotnet list package --outdated
```

Update any outdated or incompatible packages using:

```bash
dotnet add package <PackageName> --version <LatestVersion>
```

## 3. Restore and Build the Solution

Perform a clean restore and build to confirm no issues exist:

```bash
dotnet restore
dotnet build --configuration Release
```

Verify that the output contains no warnings or errors related to platform compatibility.

## 4. Run Existing Tests

If a test project exists in the solution, execute the test suite:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review the output and address any failing tests before proceeding.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer to identify any remaining Windows-specific API calls that could cause runtime failures on non-Windows platforms. This can be enabled by adding the following to the `.csproj` file:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Rebuild the project and review any new analyzer warnings, particularly those tagged with `CA1416` (platform compatibility).

## 6. Test on Target Platforms

Run the application on each platform you intend to support, for example Linux and macOS, to catch any runtime issues that static analysis may not surface:

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent build as appropriate:

**Framework-dependent:**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Review the contents of the `./publish` directory and confirm all required assets are present before deploying to the target environment.