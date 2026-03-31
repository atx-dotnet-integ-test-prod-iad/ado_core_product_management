# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or obsolete APIs, as these may indicate areas of the code that could cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute the test suite to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime, such as differences in:
- `System.Text.Encoding` defaults
- `HttpClient` behavior
- File path handling across operating systems
- Reflection behavior changes

## 4. Validate Platform-Specific Code

Review the codebase for any APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. Common areas to check include:

- **Registry access** (`Microsoft.Win32.Registry`) — only available on Windows
- **Windows Communication Foundation (WCF)** — client support exists via `System.ServiceModel`, but server-side hosting is not supported
- **`System.Drawing`** — requires the `System.Drawing.Common` package and may have OS-specific limitations
- **`AppDomain`** — some members are no longer supported
- **`BinaryFormatter`** — disabled by default in .NET 5 and later; migrate to a supported serialization mechanism if in use

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining compatibility concerns.

## 5. Run on Target Platforms

If cross-platform support is a goal, test the application explicitly on each target operating system (Windows, Linux, macOS) to catch platform-specific runtime issues that do not surface during compilation.

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path separators (`/` vs `\`)
- Case sensitivity in file systems
- Environment variable differences
- Line ending differences (`\r\n` vs `\n`)

## 6. Review Target Framework Moniker (TFM)

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If the project needs to support multiple frameworks, consider using `<TargetFrameworks>` (plural):

```xml
<TargetFrameworks>net8.0;net472</TargetFrameworks>
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (`linux-x64`, `osx-x64`, etc.) as needed. Review the contents of the `publish` output folder to confirm all required assets are present before deploying.