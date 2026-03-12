# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support your target framework. If any packages are flagged, check NuGet.org for updated versions that support the target TFM.

## 3. Build the Solution

Perform a clean build to confirm no errors are introduced at compile time:

```bash
dotnet clean
dotnet build --configuration Release
```

Review all warnings in the build output. While warnings do not block compilation, they may indicate areas where APIs have changed or been deprecated in the new framework.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully. Failures may indicate behavioral differences between the legacy .NET Framework and modern .NET, particularly around areas such as:

- `System.Configuration` usage
- WCF or Remoting dependencies
- Platform-specific APIs (registry access, COM interop, etc.)
- Serialization behavior changes

## 5. Validate Runtime Behavior

Run the application and exercise its primary code paths manually or through integration tests. Pay particular attention to:

- Database connectivity and ADO.NET operations, given the project name (`AdoCore`) suggests data access logic
- Connection string configuration, which may have moved from `App.config` to `appsettings.json` or environment variables
- Any use of `System.Data` providers, ensuring the appropriate NuGet package (e.g., `Microsoft.Data.SqlClient`) is referenced if applicable

## 6. Review Configuration Migration

If the original project used `App.config` or `Web.config`, verify that configuration values have been migrated appropriately. In modern .NET, the recommended approach is `Microsoft.Extensions.Configuration` with `appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "your-connection-string-here"
  }
}
```

Confirm that any code reading configuration values has been updated accordingly.

## 7. Check for Platform-Specific Code

Use the .NET Compatibility Analyzer to identify any remaining platform-specific API calls:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
dotnet build
```

Address any diagnostics reported by the analyzer before considering the migration complete.

## 8. Publish the Application

Once validation is complete, publish the application for your target platform:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Adjust the `--runtime` flag to match your deployment target (e.g., `linux-x64`, `osx-x64`). Use `--self-contained true` if you require the .NET runtime to be bundled with the output.