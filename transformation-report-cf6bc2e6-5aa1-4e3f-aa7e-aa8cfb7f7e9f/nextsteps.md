# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
</Project>
```

## 2. Restore and Build

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues.

## 3. Review NuGet Package Compatibility

Check all NuGet dependencies in `AdoCore.csproj` to confirm they target .NET Standard 2.0+ or the specific .NET version you are using. Run the following to list outdated packages:

```bash
dotnet list package --outdated
```

Update any outdated packages as needed:

```bash
dotnet add package <PackageName> --version <NewVersion>
```

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address the underlying issues before proceeding.

## 5. Validate Runtime Behavior

Run the application locally to confirm it behaves as expected:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

If the project is a library rather than an executable, write or run integration tests that exercise the public API surface.

## 6. Check for Platform-Specific Code

Search the codebase for any APIs that were Windows-specific in the legacy .NET Framework project. Common areas to check include:

- `System.Windows.Forms` or `System.Drawing` usage
- Registry access (`Microsoft.Win32.Registry`)
- COM interop
- `AppDomain` usage

If any of these are found, either replace them with cross-platform alternatives or add the appropriate `<RuntimeIdentifier>` to restrict deployment to Windows if cross-platform support is not required.

## 7. Publish the Application

Once validation is complete, publish the application using the desired runtime identifier. For a self-contained, platform-specific publish:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true
```

For a framework-dependent publish:

```bash
dotnet publish --configuration Release
```

The output will be placed in the `bin/Release/<TargetFramework>/publish/` directory. Verify the output artifacts are complete before deploying to the target environment.