# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to the intended cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that may have platform-specific limitations.

## 3. Build the Solution

Perform a full build to confirm there are no errors:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types or obsolete APIs, as these can indicate compatibility concerns.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release
```

Review the test results carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Verify Platform-Specific API Usage

Check the codebase for any APIs that were available in .NET Framework but are not available or behave differently in cross-platform .NET. Common areas to review include:

- `System.Data` and ADO.NET provider usage (relevant given the `AdoCore` project name)
- Database connection strings and driver compatibility (e.g., ensure you are using a compatible NuGet-based ADO.NET provider such as `Microsoft.Data.SqlClient` instead of `System.Data.SqlClient` where applicable)
- `ConfigurationManager` usage, which requires the `System.Configuration.ConfigurationManager` NuGet package in cross-platform .NET
- Any use of `AppDomain`, `Remoting`, or `COM Interop`

## 6. Test on Target Platforms

Since the goal is cross-platform support, run and validate the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime issues:

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application for your target platform. For a self-contained deployment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the contents of the publish output directory to confirm all required files are present before deploying to the target environment.