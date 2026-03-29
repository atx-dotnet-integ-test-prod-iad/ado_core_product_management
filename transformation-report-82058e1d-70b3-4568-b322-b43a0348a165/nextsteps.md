# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command in the root of your solution to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that, while non-blocking, may indicate compatibility concerns worth addressing.

## 3. Run Unit Tests

If the solution contains test projects, execute them to verify that existing functionality behaves as expected after migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Review Target Framework

Open each `.csproj` file and confirm that the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure consistency across all projects in the solution, particularly for shared libraries.

## 5. Check for Runtime Behavioral Differences

Even without build errors, certain APIs behave differently on cross-platform .NET compared to .NET Framework. Pay particular attention to:

- **Globalization and culture handling**: .NET no longer defaults to Windows NLS. If your application relies on specific culture behavior, review the use of `CultureInfo` and consider setting `<InvariantGlobalization>` appropriately in your `.csproj` or `runtimeconfig.json`.
- **Reflection and serialization**: Some reflection-based patterns may behave differently or require explicit configuration.
- **Windows-specific APIs**: If any code paths use Windows-only APIs (e.g., registry access, certain `System.Drawing` features), those paths will fail on non-Windows platforms.

## 6. Test on Target Platform(s)

Run the application on each operating system you intend to support (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a build.

```bash
dotnet run --configuration Release
```

## 7. Review NuGet Package Compatibility

Check that all referenced NuGet packages support the target framework. Packages that were built exclusively for .NET Framework may not function correctly. Use the following command to inspect outdated or incompatible packages:

```bash
dotnet list package --outdated
```

Update packages where newer, cross-platform compatible versions are available.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier for your deployment target (e.g., `win-x64`, `osx-x64`). Use `--self-contained true` if you want to bundle the .NET runtime with the output.