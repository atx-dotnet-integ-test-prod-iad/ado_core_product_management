# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

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

Ensure there are no warnings that could indicate compatibility issues, such as deprecated APIs or platform-specific calls.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any remaining Windows-only API calls that may not surface as build errors but could cause runtime failures on non-Windows platforms:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to:
- `System.Windows.Forms` or `System.Web` references
- Registry access (`Microsoft.Win32.Registry`)
- COM interop or P/Invoke calls
- `AppDomain` usage patterns that changed in .NET Core and later

## 5. Validate NuGet Package Compatibility

Review all NuGet dependencies in `AdoCore.csproj` and confirm each package supports the target framework. Packages targeting only `net45` or `net472` may function via compatibility shims but should be replaced with actively maintained alternatives where possible.

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

## 6. Run the Application and Perform Smoke Testing

Execute the application directly and perform basic functional verification:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Test the primary workflows that the application supports, particularly any database access, file I/O, or network communication, as these areas are most likely to exhibit runtime differences.

## 7. Verify Configuration File Handling

If the legacy project used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables where appropriate, and that `ConfigurationManager` calls have been updated to use `Microsoft.Extensions.Configuration` if needed.

## 8. Publish and Verify the Output

Produce a published output and verify it runs correctly on the target platform:

```bash
dotnet publish --configuration Release --output ./publish
```

Navigate to the `./publish` directory and run the output binary directly to confirm it functions as expected outside of the development environment.