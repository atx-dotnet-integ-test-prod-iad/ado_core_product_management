# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and trace them back to API or behavioral differences between the legacy .NET Framework and the new .NET runtime.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time. Pay attention to the following areas that commonly cause runtime failures after migration:

- **Reflection-based code**: Verify that any code using `System.Reflection` behaves as expected, as some behaviors differ between .NET Framework and modern .NET.
- **Configuration**: If the project used `System.Configuration` (e.g., `App.config`), confirm it has been replaced or updated to use `Microsoft.Extensions.Configuration`.
- **Platform-specific APIs**: Search the codebase for any Windows-only APIs (e.g., registry access, COM interop) that may fail on non-Windows platforms.
- **Third-party NuGet packages**: Confirm all packages support the target framework by reviewing their entries on [nuget.org](https://www.nuget.org).

## 5. Review Nullable Reference Types

If nullable reference types are enabled in the project, review any new compiler warnings related to nullability. These are not build errors by default but can indicate potential null reference exceptions at runtime.

```xml
<Nullable>enable</Nullable>
```

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) as needed. Use `--self-contained true` if you want to bundle the .NET runtime with the output.

## 8. Verify Output Artifacts

After publishing, confirm the output directory contains the expected files and that the application starts correctly from the published location before deploying to a production environment.