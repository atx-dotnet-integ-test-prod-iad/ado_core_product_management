# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. Run the following to confirm your SDK version:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings related to deprecated or unlisted packages and consider updating them.

## 3. Build the Solution

Perform a full build in Release configuration to confirm there are no configuration-specific issues:

```bash
dotnet build --configuration Release
```

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify runtime behavior matches expectations from the legacy project:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform .NET equivalents.

## 5. Check for Platform-Specific API Usage

Even without build errors, certain APIs may have been available in .NET Framework but behave differently or throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for such usage:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to:
- `System.Data` and ADO.NET provider registrations, which are relevant given the `AdoCore` project name.
- Windows Registry access (`Microsoft.Win32.Registry`).
- COM interop or P/Invoke calls.

## 6. Validate ADO.NET Provider Configuration

Since this project is named `AdoCore`, confirm that any database providers (e.g., SQL Server, SQLite, PostgreSQL) are referenced via their cross-platform NuGet packages rather than relying on machine-level or GAC-registered drivers. For example, for SQL Server:

```xml
<PackageReference Include="Microsoft.Data.SqlClient" Version="5.x.x" />
```

Avoid using the legacy `System.Data.SqlClient` where possible, as `Microsoft.Data.SqlClient` is the actively maintained cross-platform replacement.

## 7. Run on Target Platforms

If cross-platform support is a goal, test execution on each intended platform (Windows, Linux, macOS) to surface any runtime-only issues:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

Review the contents of the `publish` output directory to confirm all required assemblies and configuration files are present before deploying to the target environment.