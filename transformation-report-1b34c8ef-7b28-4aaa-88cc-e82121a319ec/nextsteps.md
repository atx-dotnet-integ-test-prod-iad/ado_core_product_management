# Next Steps

The solution has no build errors following the transformation. The steps below cover validation and deployment of the migrated project.

## 1. Review the Migrated Project File

Open `AdoCore.csproj` and confirm the following:

- The `<TargetFramework>` element targets a supported cross-platform .NET version, for example `net8.0`.
- Any remaining `<Reference>` elements pointing to Windows-specific assemblies (e.g., `System.Web`, `System.Windows.Forms`) have been removed or replaced with appropriate NuGet packages.
- `<PackageReference>` entries are present in place of any old `packages.config` dependencies.

## 2. Restore NuGet Packages

Run the following command from the solution root to confirm all dependencies resolve correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating them to their current equivalents.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings introduced by the restored packages:

```bash
dotnet build --configuration Release
```

Review any warnings in the output, particularly those related to nullable reference types or obsolete APIs, as these may indicate areas that require code changes.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures may indicate runtime behavioral differences between the legacy .NET Framework and the current .NET runtime, such as changes in globalization, reflection, or threading behavior.

## 5. Verify Platform-Specific Code

Search the codebase for any APIs that are conditionally available on specific platforms. Common areas to check include:

- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific interop or P/Invoke calls
- `AppDomain` usage, which has a reduced API surface in modern .NET

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package where needed.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a build.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment.

**Framework-dependent publish:**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained publish (example for Linux x64):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deploying to the target environment.