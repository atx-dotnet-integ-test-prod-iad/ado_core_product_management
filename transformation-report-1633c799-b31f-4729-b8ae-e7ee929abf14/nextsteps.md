# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Review NuGet Package Versions

Open the `.csproj` file and check that all `<PackageReference>` entries reference versions compatible with your target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available using:

```bash
dotnet add package <PackageName> --version <NewVersion>
```

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --verbosity normal
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform .NET equivalents.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been marked with `[SupportedOSPlatform]` attributes or may throw `PlatformNotSupportedException` at runtime on non-Windows systems. Search the codebase for common Windows-specific APIs such as:

- `System.Windows.Forms`
- `Microsoft.Win32.Registry`
- `System.Drawing` (GDI+ based)
- COM interop calls

If any are found, evaluate whether cross-platform alternatives exist or whether the project scope requires Windows-only execution.

## 6. Run the Application and Perform Smoke Testing

Execute the application directly and verify core functionality:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Walk through the primary use cases of the application to confirm expected behavior.

## 7. Validate on Target Operating Systems

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to identify any OS-specific runtime issues that would not surface during a build.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) as needed. The published output will be located in the `bin/Release/<TargetFramework>/<RuntimeIdentifier>/publish/` directory.