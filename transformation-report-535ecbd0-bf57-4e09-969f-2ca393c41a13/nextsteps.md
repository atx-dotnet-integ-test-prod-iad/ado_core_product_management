# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly against the new target framework:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not fully support the target framework (NU1701 warnings in particular).

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings that were not captured during the initial transformation:

```bash
dotnet clean
dotnet build --configuration Release
```

Address any warnings that surface, especially those related to deprecated APIs or platform compatibility.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failures may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been silently replaced or may throw at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
dotnet build
```

Pay particular attention to any usage of:
- `System.Windows.Forms` or `System.Web` namespaces
- Windows Registry access (`Microsoft.Win32.Registry`)
- COM interop
- `AppDomain` APIs with limited cross-platform support

## 6. Run the Application

Execute the application directly to validate runtime behavior:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Test all major code paths, particularly any database access, file I/O, or network operations, as these areas are most likely to surface runtime differences.

## 7. Validate Data Access Layer

Since the project name suggests ADO.NET usage (`AdoCore`), verify the following:

- Connection strings are environment-appropriate and not hardcoded with Windows-specific paths.
- The database driver NuGet packages (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) are the cross-platform compatible versions.
- Any use of `System.Data.OleDb` has been replaced, as it has limited or no support outside of Windows.

## 8. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent release build:

**Framework-dependent:**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Verify the output in the `./publish` directory runs correctly on the target platform.