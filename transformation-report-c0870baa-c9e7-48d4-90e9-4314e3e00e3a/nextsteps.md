# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build context:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility, as these can indicate subtle issues introduced during migration.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests that previously passed may indicate a behavioral difference between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Verify Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure consistency across all projects in the solution, particularly for shared libraries.

## 5. Check for Windows-Specific APIs

If the application previously ran on .NET Framework, some APIs used may be Windows-specific. Run the .NET Compatibility Analyzer to identify any such usages:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review any reported diagnostics and replace Windows-only APIs with cross-platform alternatives where applicable.

## 6. Review Configuration Files

.NET Framework projects often relied on `App.config` or `Web.config`. Confirm that any configuration values have been properly migrated to `appsettings.json` or environment variables, and that `Microsoft.Extensions.Configuration` is being used where appropriate.

## 7. Validate Runtime Behavior

Run the application manually and exercise its primary workflows. Pay particular attention to:

- File path handling, as path separators differ between Windows and Unix-based systems.
- Culture and encoding defaults, which may differ between .NET Framework and modern .NET.
- Reflection-based code, which may behave differently due to changes in the type system.

## 8. Publish the Application

Once validation is complete, publish the application using the following command:

```bash
dotnet publish --configuration Release --output ./publish
```

If targeting a specific runtime, include the runtime identifier:

```bash
dotnet publish --configuration Release -r linux-x64 --self-contained true --output ./publish
```

Review the contents of the output directory to confirm all required assets are present before deploying to the target environment.