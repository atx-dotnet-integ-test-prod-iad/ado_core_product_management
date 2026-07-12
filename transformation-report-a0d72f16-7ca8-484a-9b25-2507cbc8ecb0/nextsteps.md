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

## 3. Review NuGet Package Versions

Check that all NuGet dependencies referenced in `AdoCore.csproj` are compatible with the target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger trx
```

Review the test results output and address any failing tests before proceeding.

## 5. Check for Removed or Changed APIs

Even without build errors, some APIs behave differently in cross-platform .NET compared to .NET Framework. Pay particular attention to:

- **Database/ADO.NET usage**: Since the project is named `AdoCore`, verify that all `System.Data` and ADO.NET provider calls function correctly on the target platform.
- **Connection string handling**: Ensure connection strings are compatible with the ADO.NET providers being used.
- **Platform-specific code**: Search for any `#if` preprocessor directives or `RuntimeInformation` checks that may have been introduced or need to be introduced.

## 6. Perform Runtime Validation

Run the application against a representative workload or dataset to confirm correct runtime behavior:

```bash
dotnet run --configuration Release
```

Check application logs for any runtime exceptions, particularly around database connectivity and data operations.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment target.

## 8. Verify Output Artifacts

After publishing, inspect the output directory (typically `bin/Release/net8.0/publish/`) to confirm all required assemblies, configuration files, and dependencies are present before deploying to the target environment.