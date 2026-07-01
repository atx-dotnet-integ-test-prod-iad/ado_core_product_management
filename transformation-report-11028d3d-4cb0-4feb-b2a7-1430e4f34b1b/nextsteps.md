# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. The following steps outline how to validate, test, and deploy the migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net9.0`). Example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore NuGet Packages

Run the following command from the solution root to ensure all dependencies are restored cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages and consider updating them.

## 3. Build the Solution

Perform a full build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or obsolete API usage.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review the test output and investigate any failures. If test projects do not yet exist, consider adding unit tests targeting the core logic in `AdoCore`.

## 5. Validate Cross-Platform Behavior

Since the goal of the transformation was cross-platform compatibility, run the build and tests on each target operating system (Windows, Linux, macOS) if applicable:

```bash
dotnet build
dotnet test
```

Pay particular attention to:
- File path separators (`/` vs `\`)
- Environment variable access
- Any remaining use of Windows-specific APIs (e.g., registry access, COM interop)

You can use the [.NET Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to detect platform-specific API calls.

## 6. Check for Removed or Changed APIs

Review the code for any APIs that behave differently in cross-platform .NET compared to .NET Framework. The [.NET Upgrade Assistant](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) and the [API compatibility tool](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/api-analyzer) can assist with this.

Common areas to check:
- `System.Configuration` usage (replaced by `Microsoft.Extensions.Configuration`)
- `System.Web` usage (not available in cross-platform .NET)
- WCF client/server usage
- Reflection-based code

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your target runtime (e.g., `win-x64`, `osx-x64`). Review the publish output directory to confirm all required files are present.

## 8. Review Output for Runtime Dependencies

If the application is not self-contained, ensure the target machine has the correct .NET runtime installed. You can verify the required runtime version in the `.csproj` file and cross-reference it with what is installed on the target machine using:

```bash
dotnet --list-runtimes
```