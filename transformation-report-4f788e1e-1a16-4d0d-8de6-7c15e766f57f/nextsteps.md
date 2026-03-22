# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime available in your target environment.

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

Verify there are no warnings that could indicate deprecated APIs or compatibility issues that were silently ignored during transformation.

## 3. Run Existing Tests

If the solution contains test projects, execute them to confirm existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform .NET equivalents.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may compile successfully but behave differently or throw at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Pay particular attention to:
- `System.Data` and ADO.NET provider usage, given the `AdoCore` project name suggests database interaction
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions

## 5. Validate ADO.NET / Database Connectivity

Since the project is named `AdoCore`, confirm that any database drivers or providers used (e.g., `System.Data.SqlClient`, `Npgsql`, `MySql.Data`) have been updated to their cross-platform compatible NuGet packages. The recommended replacement for `System.Data.SqlClient` is:

```bash
dotnet add package Microsoft.Data.SqlClient
```

Update any `using` directives and connection logic accordingly if you make this switch.

## 6. Run the Application and Perform Smoke Testing

Execute the application directly and verify core functionality:

```bash
dotnet run --project AdoCore --configuration Release
```

Manually test the primary workflows, particularly any database read/write operations, to confirm runtime behavior matches the legacy application.

## 7. Publish the Application

Once validation is complete, publish the application for your target environment:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be pre-installed:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target platform (e.g., `linux-x64`, `osx-x64`).

## 8. Review NuGet Package Versions

Open the `.csproj` file and review all `<PackageReference>` entries. Ensure no packages are pinned to versions that target `net4x` only. Use [NuGet.org](https://www.nuget.org) to confirm each package supports your target framework.