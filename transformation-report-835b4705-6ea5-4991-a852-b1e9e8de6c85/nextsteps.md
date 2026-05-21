# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`).

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not cause build failures.

## 3. Review NuGet Package Versions

Open the `.csproj` file and check that all `<PackageReference>` entries reference current, stable versions compatible with your target framework. Use the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available, particularly those that were previously Windows-specific and may have cross-platform alternatives.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after the migration:

```bash
dotnet test --configuration Release
```

Review any failing tests and determine whether they are caused by API differences between .NET Framework and modern .NET.

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining platform-specific calls (e.g., registry access, Windows-only APIs):

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze
```

Address any flagged APIs by replacing them with cross-platform equivalents or adding runtime platform guards using `RuntimeInformation.IsOSPlatform`.

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) to confirm consistent behavior:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path separators (`/` vs `\`)
- Environment variable access
- Any use of `AppDomain`, `Thread.CurrentThread.CurrentCulture`, or reflection-based operations

## 7. Publish the Application

Once runtime validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate RID (e.g., `win-x64`, `osx-x64`) as needed. Review the publish output directory to confirm all required assets are present.

## 8. Review Output Artifacts

Confirm that the published output does not include any unintended Windows-specific binaries or configuration files that may have carried over from the legacy project.