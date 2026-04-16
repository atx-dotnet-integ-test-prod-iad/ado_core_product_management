# Next Steps

The transformation appears to have completed successfully. There are no build errors reported across any of the projects in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless that is intentional for multi-targeting.

## 2. Restore Dependencies

Run the following command from the solution root to restore all NuGet packages:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

## 3. Build the Solution

Perform a full build to confirm there are no compilation errors:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types or platform compatibility analyzers.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully. Failures may indicate behavioral differences between .NET Framework and modern .NET, such as changes in globalization, threading, or reflection APIs.

## 5. Check for Platform Compatibility Warnings

Modern .NET includes platform compatibility analyzers. Review any `CA1416` or similar analyzer warnings in the build output. These warnings indicate that certain APIs used in the code are Windows-specific and will not function on Linux or macOS. Refactor those areas if cross-platform support is required.

## 6. Validate Runtime Behavior

Run the application and manually exercise the primary workflows to confirm runtime behavior matches expectations from the legacy version. Pay particular attention to:

- File I/O paths, as path separator differences can cause issues across operating systems.
- Configuration file loading, particularly if `app.config` or `web.config` files were used previously.
- Any use of `System.Drawing`, COM interop, or Windows Registry access, which may not be available on non-Windows platforms.

## 7. Review Removed or Changed APIs

Consult the [.NET Upgrade Assistant compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) to identify any APIs that were removed or changed between .NET Framework and modern .NET. The `.NET Portability Analyzer` tool can also be run against the assemblies to produce a detailed compatibility report:

```bash
dotnet tool install -g dotnet-apiport
apiport analyze -f ./bin/Release/net8.0/AdoCore.dll
```

## 8. Publish the Application

Once validation is complete, publish the application using the following command, adjusting the runtime identifier (`-r`) as needed for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

For a self-contained deployment that bundles the .NET runtime:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true
```

The published output will be located in the `bin/Release/net8.0/<runtime>/publish/` directory and can be deployed to the target environment.