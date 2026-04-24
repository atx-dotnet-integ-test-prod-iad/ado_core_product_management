# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this is consistent with any dependent or consuming projects in the solution.

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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not produce hard errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior has not changed as a result of the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Removed or Changed APIs

Even without build errors, some APIs behave differently on cross-platform .NET. Pay particular attention to the following areas if your project uses them:

- **`System.Data`** and ADO.NET providers: Confirm that any database drivers (e.g., `System.Data.SqlClient` vs `Microsoft.Data.SqlClient`) are the correct NuGet-based versions for cross-platform use.
- **`System.Configuration`**: This is not fully supported on .NET Core and later. Replace usage with `Microsoft.Extensions.Configuration` if applicable.
- **Registry access**: `Microsoft.Win32.Registry` is Windows-only. Wrap any such calls with runtime OS checks if cross-platform support is required.
- **`AppDomain`**: Some members are no longer supported or throw `PlatformNotSupportedException`.

## 5. Validate NuGet Package Versions

Open the `.csproj` file and review all `<PackageReference>` entries. Ensure that:

- No packages are pinned to versions that only support .NET Framework.
- Packages have been updated to their latest stable versions compatible with your target framework.

You can check compatibility using the [NuGet Package Explorer](https://www.nuget.org/) or by running:

```bash
dotnet list package --outdated
```

## 6. Test on Target Operating Systems

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear at compile time.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier:

```bash
# Framework-dependent (requires .NET runtime on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained (includes the runtime)
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Review the contents of the `./publish` directory to confirm all expected files are present before deploying to the target environment.