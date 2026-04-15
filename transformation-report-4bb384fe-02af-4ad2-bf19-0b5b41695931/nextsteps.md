# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages and consider updating them to actively maintained versions.

## 3. Build the Solution

Perform a full build to confirm there are no errors or warnings that may have been suppressed during transformation:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types or obsolete APIs, as these can indicate potential runtime issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated to determine whether the failure is due to the migration or a pre-existing issue.

## 5. Validate ADO.NET Functionality

Since this project is named `AdoCore`, it likely involves ADO.NET data access. Manually verify the following:

- **Connection strings** are correctly configured for the target environment, particularly if the project previously used `System.Data` providers that have changed in cross-platform .NET (e.g., `System.Data.SqlClient` replaced by `Microsoft.Data.SqlClient`).
- **Database provider packages** are the cross-platform compatible versions. Replace `System.Data.SqlClient` with `Microsoft.Data.SqlClient` if not already done:

```xml
<PackageReference Include="Microsoft.Data.SqlClient" Version="5.x.x" />
```

- **Data type mappings** behave as expected, particularly around `DateTime`, `decimal`, and binary types which can differ across platforms.

## 6. Check Platform-Specific Code

Search the codebase for any remaining platform-specific APIs that may compile but fail at runtime on non-Windows systems:

- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file paths or path separators
- `System.Drawing` (requires additional native dependencies on Linux/macOS)

Use `RuntimeInformation.IsOSPlatform()` guards where platform-specific code paths are necessary.

## 7. Test on Target Platform

If the goal is cross-platform execution, run the application on each intended target operating system (Windows, Linux, macOS) to catch any runtime issues not surfaced during compilation:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime. For a self-contained deployment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Or for a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

Review the contents of the `publish` output folder to confirm all required files and dependencies are present before deploying to the target environment.