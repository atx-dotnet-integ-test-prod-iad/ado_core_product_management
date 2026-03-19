# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this matches the version of the .NET SDK you have installed. You can check your installed SDKs by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not support the target framework or that have been replaced by inbox .NET APIs.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface at this stage, particularly those related to obsolete APIs or platform compatibility analyzers (CA1416, etc.).

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release
```

Review test output for failures that may indicate runtime behavioral differences between .NET Framework and cross-platform .NET.

## 5. Check for Windows-Specific API Usage

Use the .NET Compatibility Analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining calls to Windows-only APIs (e.g., registry access, `System.Drawing`, COM interop). Run the following to surface platform compatibility diagnostics:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Replace or conditionally compile any Windows-specific code paths if cross-platform execution is required.

## 6. Validate Runtime Behavior

Run the application against a representative set of inputs or scenarios:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path handling (`Path.Combine` vs. hardcoded separators)
- Encoding defaults (UTF-8 is the default in .NET, not the system code page)
- Reflection behavior changes between .NET Framework and .NET

## 7. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent build as appropriate for your deployment target.

**Framework-dependent:**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory and confirm the application starts correctly in the target environment before promoting to production.