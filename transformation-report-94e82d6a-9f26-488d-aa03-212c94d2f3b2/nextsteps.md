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

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and trace them back to API or behavioral differences between the legacy .NET Framework and the new .NET runtime.

## 4. Check for Runtime-Only Issues

Some issues do not surface at compile time. Pay attention to the following areas:

- **Reflection-based code**: Behavior differences may exist between .NET Framework and modern .NET.
- **Configuration**: `System.Configuration.ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package if used.
- **Database connectivity**: If `AdoCore` implies ADO.NET usage, verify that the database drivers (e.g., `Microsoft.Data.SqlClient`) are the correct cross-platform versions and not the legacy `System.Data.SqlClient`.
- **Platform-specific APIs**: Any Windows-only APIs (e.g., registry access, COM interop) will fail on non-Windows platforms at runtime even if they compile successfully.

## 5. Validate NuGet Package Compatibility

Check that all referenced NuGet packages support the target framework. Run the following to identify any compatibility concerns:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Update packages where necessary using:

```bash
dotnet add package <PackageName> --version <LatestVersion>
```

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime failures.

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime, use:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier for your target environment (e.g., `win-x64`, `osx-x64`).

## 8. Verify Published Output

After publishing, run the output directly from the publish directory to confirm the application starts and functions correctly in its final form before deploying to the target environment.