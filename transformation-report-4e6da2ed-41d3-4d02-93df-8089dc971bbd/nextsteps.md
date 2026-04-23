# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this matches the .NET SDK version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts. If any packages previously targeting `.NET Framework` were carried over, check for cross-platform compatible equivalents on [NuGet](https://www.nuget.org).

## 3. Build the Solution

Perform a full build in Release configuration to surface any warnings that may indicate runtime issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify behavioral correctness after migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Failures that did not exist before migration may indicate behavioral differences between .NET Framework and cross-platform .NET, particularly around:

- `System.Data` and ADO.NET provider behavior
- Connection string formats
- Exception types or messages that may have changed

## 5. Validate ADO.NET Functionality

Since the project is named `AdoCore`, it likely involves database access. Verify the following:

- The database provider package (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) is the correct cross-platform version.
- Connection strings are valid in the new environment.
- Any use of `System.Data.OleDb` or `System.Data.Odbc` is reviewed, as these have limited or no support on non-Windows platforms.

Run a manual integration test or a simple connection test against your target database to confirm connectivity.

## 6. Check for Platform-Specific Code

Use the .NET Compatibility Analyzer to identify any remaining platform-specific API calls:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
dotnet build
```

Pay attention to any `CA1416` warnings, which flag Windows-only APIs.

## 7. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to confirm consistent behavior:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application for your target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

Review the contents of the `publish` output folder and deploy to your target environment.