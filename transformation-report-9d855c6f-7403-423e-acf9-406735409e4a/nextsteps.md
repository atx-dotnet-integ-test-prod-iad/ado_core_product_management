# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation

### 1. Review the Transformed Project File
Open `AdoCore.csproj` and confirm the following:
- The `<TargetFramework>` element targets a supported cross-platform .NET version, such as `net6.0`, `net7.0`, or `net8.0`.
- Any Windows-specific references (e.g., `System.Windows.Forms`, `Microsoft.VisualBasic`) have been removed or replaced if they are not relevant to the cross-platform goals.
- NuGet package references replace any old `packages.config` or `<HintPath>`-based assembly references.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build
```

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test
```

Review any failing tests and address them before proceeding.

### 4. Run the Application
Execute the application directly to confirm it runs as expected on the target platform:

```bash
dotnet run --project AdoCore.csproj
```

If the project is a library, write a small integration test or console harness to exercise its public API.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any remaining platform-specific API calls that may compile successfully but fail at runtime on non-Windows platforms.

```bash
dotnet add package Microsoft.Windows.Compatibility --version <latest>
```

Only add this package if Windows-specific APIs are intentionally required. Otherwise, replace those APIs with cross-platform alternatives.

### 6. Validate Target Platform Behavior
Test the built output on each platform you intend to support (Windows, Linux, macOS) to catch any runtime issues that do not surface during compilation.

```bash
dotnet publish -r linux-x64 --self-contained
dotnet publish -r osx-x64 --self-contained
dotnet publish -r win-x64 --self-contained
```

Review the published output for each runtime identifier and confirm the application starts and behaves correctly.

### 7. Review Nullable Reference Type Warnings
If the project was migrated from an older .NET Framework codebase, nullable reference type annotations may not be in place. Consider enabling nullable analysis gradually:

```xml
<Nullable>enable</Nullable>
```

Address any resulting warnings to improve code correctness going forward.