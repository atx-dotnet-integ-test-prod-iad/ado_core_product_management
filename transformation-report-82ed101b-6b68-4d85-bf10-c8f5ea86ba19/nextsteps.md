# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. Run the following to confirm your SDK version:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages that may need to be updated.

## 3. Build the Solution

Perform a full build in Release configuration to confirm there are no errors or warnings that were not present during the initial transformation check:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or obsolete API usage.

## 4. Run the Test Suite

If the solution contains test projects, execute all tests to verify that behavior has not changed after the transformation:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Even without build errors, certain APIs that compiled successfully may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Review the code for usage of the following:

- `System.Windows.Forms` or `System.Drawing` (GDI+)
- `Microsoft.Win32` registry access
- COM interop or P/Invoke calls targeting Windows-specific libraries
- `AppDomain` APIs with limited cross-platform support

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package to identify these at analysis time rather than at runtime.

## 6. Run the Application and Perform Smoke Testing

Execute the application directly and perform basic functional testing across the primary workflows:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Verify that database connections, file I/O, and any external service integrations behave as expected.

## 7. Validate Configuration Files

Check that any `App.config` or `Web.config` files have been correctly migrated to `appsettings.json` or environment-based configuration. The legacy `ConfigurationManager` API is available via the `System.Configuration.ConfigurationManager` NuGet package, but migrating to `Microsoft.Extensions.Configuration` is the recommended approach for cross-platform .NET.

## 8. Publish the Application

Once validation is complete, publish the application for your target environment:

**Framework-dependent deployment:**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained deployment (example for Linux x64):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files and dependencies are present before deploying to the target environment.