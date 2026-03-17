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

## 3. Review NuGet Package Versions

Check that all NuGet dependencies referenced in `AdoCore.csproj` are compatible with your target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Run Existing Tests

If the solution contains test projects, execute the test suite to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review any failing tests and determine whether they are caused by API differences between the legacy .NET Framework and the new .NET version.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs that compiled successfully may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Search the codebase for usage of the following common problem areas:

- `System.Web` namespaces
- `Microsoft.Win32` registry access
- Windows Communication Foundation (WCF) server-side APIs
- `AppDomain.CreateDomain`
- `BinaryFormatter`

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package to identify these at analysis time.

## 6. Run the Application and Perform Smoke Testing

Start the application and exercise its primary code paths:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Verify that core functionality behaves as expected and that no runtime exceptions surface that were not present in the original project.

## 7. Validate Configuration Files

Ensure that any `app.config` or `web.config` files have been properly migrated to `appsettings.json` or environment-based configuration using `Microsoft.Extensions.Configuration`. Legacy XML-based configuration is not automatically processed in .NET.

## 8. Publish the Application

Once validation is complete, publish the application using the following command:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assemblies and configuration files are present before deploying to the target environment.