# Next Steps

The solution has no build errors following the transformation. The steps below cover validation and deployment of the migrated project.

## 1. Review the Migrated Project File

Open `AdoCore.csproj` and confirm the following:

- The `<TargetFramework>` element targets a supported cross-platform .NET version, for example `net8.0`.
- Any remaining `<Reference>` elements that previously pointed to Windows-only assemblies (e.g., `System.Web`, `System.Windows.Forms`) have been replaced with appropriate NuGet packages or removed.
- `<PackageReference>` entries are present in place of any old `packages.config` dependencies.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages resolve correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating them to current stable versions using:

```bash
dotnet list package --outdated
dotnet add package <PackageName>
```

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Review any warnings in the output. While warnings do not prevent a build from succeeding, they can indicate compatibility issues that may surface at runtime.

## 4. Run the Existing Test Suite

If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully. Failures may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform .NET equivalents.

## 5. Check for Platform-Specific Code

Search the codebase for APIs that are conditionally supported on non-Windows platforms. Common areas to check include:

- Registry access (`Microsoft.Win32.Registry`)
- Windows Event Log (`System.Diagnostics.EventLog`)
- File path assumptions (backslash separators, drive letters)
- `System.Drawing` usage, which requires the `System.Drawing.Common` NuGet package on non-Windows platforms and has known limitations

Use the .NET Compatibility Analyzer to identify these issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
dotnet build
```

## 6. Run the Application and Perform Smoke Testing

Execute the application directly and verify core functionality:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Walk through the primary use cases of the application manually to confirm expected behavior.

## 7. Validate on Target Platforms

If cross-platform support is a goal, run the application on each intended target operating system (Windows, Linux, macOS) to identify any platform-specific runtime failures that would not appear during a Windows-only build.

## 8. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent build as appropriate:

**Framework-dependent:**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish/linux-x64
```

Verify the output in the `./publish` directory and confirm the application runs correctly from that location before distributing or deploying it.