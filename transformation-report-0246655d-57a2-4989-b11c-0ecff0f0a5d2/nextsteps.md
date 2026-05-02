# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net4x` or `netstandard` targets unless that is intentional.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not cause build failures.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding further.

### 4. Check for Removed or Changed APIs
Even with a clean build, some APIs behave differently on cross-platform .NET compared to .NET Framework. Review the code for usage of the following common problem areas:

- `System.Drawing` (requires the `System.Drawing.Common` NuGet package and has platform restrictions on Linux/macOS)
- `AppDomain`, `Remoting`, or `Reflection.Emit` APIs
- Windows Registry access (`Microsoft.Win32.Registry`)
- `System.Web` types (these are not available in cross-platform .NET)
- `BinaryFormatter` (deprecated and disabled by default in .NET 7+)

### 5. Audit NuGet Package Compatibility
Open the `.csproj` files and review all `<PackageReference>` entries. For each package, confirm the version being referenced supports the new target framework. You can use the following command to check for outdated or vulnerable packages:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Update packages where necessary using:

```bash
dotnet add package <PackageName> --version <NewVersion>
```

### 6. Validate Platform-Specific Behavior
If the application is intended to run on Linux or macOS in addition to Windows, test it on those platforms explicitly. Pay attention to:

- File path separators (`\` vs `/`) — use `Path.Combine` and `Path.DirectorySeparatorChar`
- Case sensitivity in file system access
- Environment variable names and availability
- Line ending differences (`\r\n` vs `\n`)

### 7. Review Configuration and App Settings
If the project previously used `App.config` or `Web.config`, confirm that configuration has been migrated to `appsettings.json` and that `Microsoft.Extensions.Configuration` is being used appropriately.

### 8. Publish the Application
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime, use:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (`linux-x64`, `osx-x64`, etc.) as needed.

Verify the contents of the `./publish` folder and run the output executable to confirm the application starts and behaves as expected in the published form.