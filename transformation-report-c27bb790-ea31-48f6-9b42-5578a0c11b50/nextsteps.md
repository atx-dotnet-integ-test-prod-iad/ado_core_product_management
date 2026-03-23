# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore NuGet Packages
Run the following command from the solution root to ensure all dependencies are restored cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages and consider updating them.

### 3. Build the Solution
Perform a full build to confirm there are no errors:

```bash
dotnet build --configuration Release
```

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework APIs and the new cross-platform .NET runtime.

### 5. Review Removed or Incompatible APIs
Check the code for any APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. Common areas to inspect include:

- `System.Web` usages (not available in cross-platform .NET)
- `AppDomain` members with limited support
- Windows-specific registry or file path assumptions
- `BinaryFormatter` (deprecated and disabled by default)
- `ConfigurationManager` (requires the `System.Configuration.ConfigurationManager` NuGet package)

### 6. Check Platform-Specific Code
If the project previously relied on Windows-specific behavior (e.g., COM interop, Windows registry, NTLM authentication), verify that those code paths are either guarded with runtime checks or replaced with cross-platform alternatives:

```csharp
if (OperatingSystem.IsWindows())
{
    // Windows-specific logic
}
```

### 7. Validate Configuration Files
Ensure that `app.config` or `web.config` settings have been migrated to the appropriate `appsettings.json` or `appsettings.{Environment}.json` files if the project uses the modern `Microsoft.Extensions.Configuration` stack.

### 8. Run the Application
Execute the application directly to confirm runtime behavior matches expectations:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Monitor the output and logs for any runtime exceptions that would not surface at compile time.

### 9. Review Warnings
Even without errors, the build may have produced warnings. Review them with:

```bash
dotnet build --configuration Release 2>&1 | grep -i warning
```

Address any warnings related to obsolete APIs or nullable reference types, as these can indicate future compatibility issues.