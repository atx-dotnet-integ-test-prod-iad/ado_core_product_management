# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy the migrated project.

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

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Failures that did not exist before migration may indicate runtime behavioral differences between .NET Framework and cross-platform .NET.

## 4. Verify Platform-Specific APIs

Review the codebase for any APIs that were available in .NET Framework but have limited or no support in cross-platform .NET. Common areas to check include:

- `System.Web` usage
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage beyond what is supported
- Remoting or binary serialization
- WCF server-side components

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to identify remaining compatibility concerns.

## 5. Run the Application and Perform Functional Testing

Execute the application and walk through its core functionality manually or via integration tests. Pay particular attention to:

- File I/O paths, as path separators differ between Windows and Unix-based systems
- Configuration file loading (e.g., migration from `app.config` to `appsettings.json`)
- Any reflection-based code that may behave differently under the new runtime

## 6. Review Target Framework Monikers

Open each `.csproj` file and confirm that the `<TargetFramework>` element is set to an appropriate and currently supported version, such as `net8.0`. Avoid targeting end-of-life versions like `net5.0` or `net6.0` if long-term support is a requirement.

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 7. Publish the Application

Once validation is complete, publish the application using the following command, adjusting the runtime identifier (`-r`) as appropriate for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true
```

Review the output directory to confirm all required files are present before deploying to the target environment.