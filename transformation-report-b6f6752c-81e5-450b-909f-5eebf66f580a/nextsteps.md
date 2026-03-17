# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If the value still references a Windows-only TFM such as `net472` or `net48`, update it accordingly.

## 2. Restore NuGet Packages

Run the following command from the solution root to ensure all dependencies are restored cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or incompatible packages and update them using:

```bash
dotnet list package --outdated
dotnet add package <PackageName>
```

## 3. Build the Solution

Perform a clean build to confirm there are no residual issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or platform compatibility analyzers (CA1416), as these can indicate runtime issues on non-Windows platforms.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences in the new runtime or by platform-specific code that was not fully addressed during transformation.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer to identify any remaining Windows-specific API calls. Build with the following property to surface these warnings:

```bash
dotnet build -p:PlatformTarget=AnyCPU
```

Search the codebase for usages of APIs such as `System.Windows.Forms`, `Microsoft.Win32.Registry`, or `System.Drawing` (non-cross-platform version), and replace them with cross-platform alternatives where applicable.

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) to confirm consistent behavior:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path separators (`\` vs `/`)
- Environment variable access
- Any use of `AppDomain` or reflection-based features that may behave differently across platforms

## 7. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent build as appropriate:

**Framework-dependent:**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish/linux-x64
```

Verify the output in the `./publish` directory runs correctly on the target machine.