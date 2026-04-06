# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-specific TFM such as `net472` or `net48`, update it accordingly.

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Verify that no warnings or errors appear in the output. Pay attention to any `NU` prefixed NuGet warnings, as they may indicate package compatibility issues that did not surface as hard errors.

## 3. Check for Platform-Specific API Usage

Even without build errors, the code may contain Windows-specific APIs that will fail at runtime on Linux or macOS. Run the .NET Platform Compatibility Analyzer by ensuring the following is present in `AdoCore.csproj`:

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisMode>All</AnalysisMode>
</PropertyGroup>
```

Rebuild and review any `CA1416` warnings, which indicate platform-specific API calls.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to confirm runtime behavior is intact:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and modern .NET (e.g., changes in globalization, threading, or serialization defaults).

## 5. Validate Globalization Behavior

Modern .NET uses ICU libraries for globalization by default rather than NLS (used by .NET Framework). If `AdoCore` performs string comparisons, sorting, or culture-sensitive formatting, verify the output is still correct. If NLS behavior is required, add the following to `AdoCore.csproj`:

```xml
<ItemGroup>
  <RuntimeHostConfigurationOption Include="System.Globalization.UseNls" Value="true" Enabled="true" />
</ItemGroup>
```

## 6. Review NuGet Package Compatibility

Check that all referenced NuGet packages support the target framework. Run:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform support. Also run:

```bash
dotnet list package --vulnerable
```

to identify any packages with known security vulnerabilities.

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application or test suite on each intended operating system (Windows, Linux, macOS) to catch any runtime-only platform issues that static analysis may not surface.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime, use:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Replace `linux-x64` with the appropriate Runtime Identifier (RID) for your target environment. A full list of RIDs is available in the [.NET RID Catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).