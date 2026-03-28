# Next Steps

The solution has no build errors following the transformation. The steps below cover validation and deployment of the migrated project.

## 1. Review the Migrated Project File

Open `AdoCore.csproj` and confirm the following:

- The `<TargetFramework>` element targets a supported cross-platform .NET version, for example `net8.0`.
- Any remaining `<Reference>` elements that previously pointed to Windows-only assemblies (e.g., `System.Web`, `System.Windows.Forms`) have been replaced with appropriate NuGet packages or removed entirely.
- `<PackageReference>` entries are present in place of any old `packages.config` dependencies.

## 2. Restore NuGet Packages

Run the following command from the solution root to confirm all dependencies resolve correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating to current stable versions.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings that were not present during the initial transformation check:

```bash
dotnet build --configuration Release
```

Review any warnings in the output, particularly those related to nullable reference types, obsolete APIs, or platform compatibility analyzers (CA1416).

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures may indicate runtime behavioral differences between .NET Framework and modern .NET, such as changes in globalization, string handling, or reflection behavior.

## 5. Check for Platform-Specific Code

Use the .NET Compatibility Analyzer or review the build output for `CA1416` warnings. These indicate API calls that are only valid on specific operating systems. If the project is intended to run cross-platform, such calls must be guarded with `OperatingSystem.IsWindows()` checks or replaced with cross-platform alternatives.

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) to confirm consistent behavior. Pay particular attention to:

- File path handling (`Path.Combine` vs. hardcoded separators).
- Registry access, which is Windows-only.
- Any use of `System.Drawing` or `System.Windows.Forms`, which require additional packages or are not available cross-platform.

## 7. Review Configuration Files

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables, as `System.Configuration.ConfigurationManager` has limited support in modern .NET.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --runtime <target-rid> --self-contained false
```

Replace `<target-rid>` with the appropriate Runtime Identifier, for example `win-x64`, `linux-x64`, or `osx-x64`. Use `--self-contained true` if you want to bundle the .NET runtime with the output.