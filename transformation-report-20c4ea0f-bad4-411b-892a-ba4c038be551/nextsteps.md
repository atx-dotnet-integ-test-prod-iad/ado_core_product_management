# Next Steps

The solution has no build errors following the transformation. The steps below cover validation and deployment.

## 1. Review the Transformed Project File

Open `AdoCore.csproj` and confirm the following:

- The `<TargetFramework>` element targets a supported cross-platform .NET version, for example `net8.0`.
- Any remaining `<Reference>` elements that previously pointed to Windows-specific assemblies (e.g., `System.Data`, `System.Web`) have been replaced with the appropriate NuGet packages or framework-provided equivalents.
- No `<HintPath>` elements point to absolute paths or paths that only exist on a Windows machine.

## 2. Restore Dependencies

Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating them to their current stable versions via:

```bash
dotnet list package --outdated
dotnet add package <PackageName>
```

## 3. Build the Solution

Perform a clean build to confirm there are no compile-time issues:

```bash
dotnet build --configuration Release
```

Review any warnings that surface during the build, particularly:
- Nullable reference type warnings
- Obsolete API usage warnings
- Platform compatibility warnings (CA1416)

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Pay close attention to any tests that exercise database access, file I/O, or platform-specific behavior, as these are the most likely areas to surface cross-platform issues at runtime.

## 5. Validate on the Target Platform

If the intended deployment target is Linux or macOS, run the build and tests directly on that operating system or on a machine matching the target environment. Specific areas to verify:

- **File path separators**: Ensure no hardcoded backslashes (`\`) exist in path construction. Use `Path.Combine` or `Path.DirectorySeparatorChar` instead.
- **Case sensitivity**: Linux file systems are case-sensitive. Confirm all file and assembly references use the correct casing.
- **Line endings**: Confirm any file parsing logic handles both `\r\n` and `\n`.

## 6. Publish the Application

Once validation passes, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that bundles the .NET runtime:

```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier for your target platform (e.g., `win-x64`, `osx-x64`, `osx-arm64`).

## 7. Verify the Published Output

Navigate to the `./publish` directory and confirm:

- The expected executable or library files are present.
- Any required configuration files (e.g., `appsettings.json`) are included.
- The application starts and connects to its dependencies (databases, services) without errors.