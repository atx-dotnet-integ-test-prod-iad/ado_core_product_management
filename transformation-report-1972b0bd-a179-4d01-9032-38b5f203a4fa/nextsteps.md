# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns that did not surface as hard errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may compile but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
dotnet build
```

Pay particular attention to any usage of:
- `System.Windows.Forms` or `System.Drawing` (GDI+)
- `Microsoft.Win32` registry APIs
- COM interop or P/Invoke calls targeting Windows-only libraries

## 5. Run on Target Platforms

If cross-platform support is a goal, run the application on each intended platform (Linux, macOS, Windows) to catch runtime-only issues:

```bash
dotnet run --configuration Release
```

Test all major code paths, particularly those involving file I/O, networking, or database access, as path separators and environment variables differ across platforms.

## 6. Review NuGet Package Compatibility

Confirm that all NuGet dependencies support the target framework. Check the packages listed in `AdoCore.csproj` against their listed supported frameworks on [nuget.org](https://www.nuget.org). Replace any packages that do not support the target TFM with compatible alternatives.

## 7. Validate Database Connectivity (ADO Specific)

Given the project name `AdoCore`, it likely involves ADO.NET data access. Verify the following:

- Connection strings are correctly configured for the target environment.
- The database provider package (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) is the correct cross-platform version.
- Any `System.Data.OleDb` or `System.Data.Odbc` usage is reviewed, as these have limited or no support on non-Windows platforms.

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
# Framework-dependent publish
dotnet publish --configuration Release --output ./publish

# Self-contained publish for a specific runtime
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory and confirm the application runs correctly from that output.