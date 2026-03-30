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

Ensure there are no warnings that could indicate compatibility issues, such as deprecated APIs or platform-specific code paths.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have changed behavior on non-Windows platforms. Review the code for usage of the following, which are common sources of runtime issues after migration:

- `System.Data` and ADO.NET provider references (relevant given the `AdoCore` project name)
- Windows registry access (`Microsoft.Win32.Registry`)
- `System.Drawing` (requires `System.Drawing.Common` and may have platform restrictions)
- `AppDomain` and reflection-heavy code

## 5. Validate ADO.NET / Database Connectivity

Since the project is named `AdoCore`, confirm that the appropriate database driver NuGet packages are referenced and functional. For example:

- SQL Server: `Microsoft.Data.SqlClient`
- SQLite: `Microsoft.Data.Sqlite`
- PostgreSQL: `Npgsql`

Run integration tests or a manual connection test against your target database to confirm connectivity and query behavior.

## 6. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` are compatible with your target framework. You can audit this with:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Update any outdated or vulnerable packages as appropriate.

## 7. Test on Target Platforms

If cross-platform support is a goal, test the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime exceptions that would not appear at build time.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required assemblies and configuration files are present before deploying to the target environment.