# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not block compilation.

## 3. Review NuGet Package Versions

Open the `.csproj` file and check that all `<PackageReference>` entries reference versions compatible with your target framework. You can check for outdated packages with:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and trace them back to API or behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Windows-Specific API Usage

Even without build errors, some APIs that compiled successfully may not behave correctly on non-Windows platforms. Search the codebase for usages of the following and verify cross-platform compatibility:

- `System.Windows.Forms` or `System.Drawing` (requires additional packages on non-Windows)
- `Microsoft.Win32` registry access
- Windows-specific file path assumptions (e.g., backslash separators)
- P/Invoke calls to Windows native libraries

## 6. Validate Runtime Behavior

Run the application and exercise its primary workflows manually or through integration tests. Pay particular attention to:

- Database connectivity and ADO.NET operations (given the `AdoCore` project name, this is likely a core concern)
- Connection string formats, which may differ between providers on cross-platform .NET
- Any configuration previously stored in `App.config` or `Web.config`, which should now be migrated to `appsettings.json` or environment variables

## 7. Review Configuration Migration

If the project previously used `System.Configuration.ConfigurationManager`, verify that either:

- The `System.Configuration.ConfigurationManager` NuGet package has been added, or
- Configuration has been migrated to `Microsoft.Extensions.Configuration` with an `appsettings.json` file

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the contents of the `./publish` directory and confirm all required runtime assets and dependencies are present before deploying to the target environment.