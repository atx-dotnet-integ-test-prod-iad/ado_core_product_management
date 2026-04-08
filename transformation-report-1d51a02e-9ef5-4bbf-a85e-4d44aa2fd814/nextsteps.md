# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore NuGet Packages
Run the following command from the solution root to ensure all dependencies resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved dependencies.

### 3. Build the Solution
Perform a full build to confirm no errors exist in the restored state:

```bash
dotnet build --configuration Release
```

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review test output carefully, paying attention to any tests that were previously passing in the legacy project.

### 5. Check for Platform-Specific API Usage
Even without build errors, some APIs may have been silently replaced or may behave differently on non-Windows platforms. Use the .NET Compatibility Analyzer to surface any remaining concerns:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
dotnet build
```

Review any new analyzer warnings that appear.

### 6. Review `AdoCore.csproj` Specifically
Since `AdoCore` is the most independent project in the solution (listed last), confirm the following manually:

- All referenced NuGet packages have cross-platform compatible versions.
- Any use of `System.Data` or ADO.NET-specific providers (e.g., `System.Data.SqlClient`) has been evaluated and, if necessary, replaced with the cross-platform equivalent such as `Microsoft.Data.SqlClient`.
- Connection string handling and configuration loading (e.g., `ConfigurationManager`) has been updated to use `Microsoft.Extensions.Configuration` if applicable.

### 7. Validate Runtime Behavior
Run the application on the target platform (Linux, macOS, or Windows) and verify:

- Database connections establish correctly.
- Data reads and writes produce expected results.
- Any file path handling uses `Path.Combine` rather than hardcoded separators.

### 8. Deployment
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --runtime <target-rid> --self-contained false
```

Replace `<target-rid>` with the appropriate Runtime Identifier, for example:
- `linux-x64`
- `win-x64`
- `osx-x64`

Review the contents of the `publish` output folder before deploying to the target environment.