# Next Steps

The solution has no build errors following the transformation. Below are steps to validate, test, and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no legacy TFMs such as `net472` or `net48` remain unless you intentionally have a multi-targeting setup.

## 2. Restore Dependencies

Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings that may have been suppressed during the transformation:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility analyzers before proceeding.

## 4. Run Existing Tests

If the solution contains test projects, execute them to confirm existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review test output for any failures that may indicate behavioral differences introduced by the migration.

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the built-in platform compatibility warnings to identify any APIs that are Windows-only or otherwise platform-restricted. Pay particular attention to:

- `System.Windows.Forms` or `System.Drawing` references
- COM interop calls
- Registry access (`Microsoft.Win32.Registry`)
- Any P/Invoke declarations targeting Windows-specific libraries

If such APIs exist and cross-platform support is required, plan replacements or use runtime guards such as `OperatingSystem.IsWindows()`.

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS as applicable) to confirm runtime behavior is consistent:

```bash
dotnet run --configuration Release
```

Pay attention to file path separators, environment variable handling, and any platform-specific configuration files.

## 7. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent build as appropriate:

**Framework-dependent:**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Review the contents of the `./publish` directory to confirm all required assets and configuration files are present before deploying to the target environment.