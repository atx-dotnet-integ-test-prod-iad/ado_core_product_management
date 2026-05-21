# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

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

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Removed or Changed APIs

Cross-platform .NET removed several APIs that existed in .NET Framework. Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` compatibility shim where needed. Pay particular attention to:

- `System.Web` usages (not available in .NET Core/.NET 5+)
- `AppDomain` APIs with limited support
- Windows-only APIs (e.g., registry access, WCF server-side, Windows Forms if targeting non-Windows)

Run the compatibility analyzer:

```bash
dotnet add package Microsoft.DotNet.ApiCompat
```

## 5. Validate NuGet Package Versions

Open the `.csproj` file and review all `<PackageReference>` entries. Ensure all packages target compatible versions for your selected .NET framework. You can check for outdated packages with:

```bash
dotnet list package --outdated
```

Update packages where necessary using:

```bash
dotnet add package <PackageName> --version <LatestVersion>
```

## 6. Test on Target Platforms

Since the goal is cross-platform support, run the application on each intended platform (Windows, Linux, macOS) to catch any platform-specific runtime issues that would not appear at build time.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application for your target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

For a framework-dependent deployment:

```bash
dotnet publish -c Release -o ./publish
```

Review the contents of the `./publish` directory to confirm all required files and dependencies are present before deploying to the target environment.