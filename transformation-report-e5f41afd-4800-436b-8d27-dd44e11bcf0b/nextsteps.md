# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on all machines where the project will run or be built.

## 2. Restore Dependencies

Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts.

## 3. Build the Solution

Perform a clean build to confirm there are no residual issues:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent runtime issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failures should be investigated before proceeding.

## 5. Validate Platform-Specific Behavior

If the original project used any Windows-specific APIs (e.g., `System.Drawing`, `Microsoft.Win32`, COM interop, or the Windows registry), verify that those code paths function correctly on your target platform(s). Some APIs are annotated with `[SupportedOSPlatform]` and will produce warnings or fail at runtime on non-Windows systems.

## 6. Check for Removed or Changed APIs

Use the .NET Upgrade Assistant compatibility analyzer or review the [.NET API compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) to confirm that no APIs used in `AdoCore` were removed or had breaking changes in the target .NET version.

## 7. Test Runtime Behavior

Run the application manually and exercise the primary workflows, particularly any database access or ADO.NET-related functionality implied by the project name. Confirm that connection strings, provider registrations, and data access patterns work as expected under the new runtime.

## 8. Review Output Artifacts

Check that the build output in the `bin/Release` folder contains the expected assemblies and that no unnecessary platform-specific binaries are included.

## 9. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deploying to the target environment.