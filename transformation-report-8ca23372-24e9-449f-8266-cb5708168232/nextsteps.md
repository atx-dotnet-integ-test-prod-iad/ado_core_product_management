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

Check that all NuGet dependencies referenced in `AdoCore.csproj` are compatible with your target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available, particularly those that were carried over from the legacy project.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify that existing functionality behaves as expected after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences in the new runtime or by test setup issues.

## 5. Check for Removed or Changed APIs

Even without build errors, some APIs behave differently between .NET Framework and modern .NET. Pay particular attention to:

- **`System.Data`** and ADO.NET-related classes, since the project name suggests ADO usage. Verify connection string handling, provider factories, and any `DataSet`/`DataTable` usage.
- **`ConfigurationManager`**: This requires the `System.Configuration.ConfigurationManager` NuGet package in modern .NET and is no longer included by default.
- **`AppDomain`**: Some members are no longer supported or throw `PlatformNotSupportedException`.

## 6. Test on Target Operating Systems

Since the goal is cross-platform compatibility, run the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific issues such as:

- File path separator differences (`\` vs `/`)
- Case-sensitive file systems on Linux
- Platform-specific native library dependencies

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate RID (e.g., `win-x64`, `osx-x64`) as needed. Review the output in the `publish` folder before deploying to the target environment.