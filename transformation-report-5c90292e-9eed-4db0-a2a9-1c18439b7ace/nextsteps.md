# Next Steps

## Summary

The solution appears to have transformed successfully. No build errors were detected in any of the projects, including `AdoCore.csproj`. The following steps outline how to validate, test, and deploy the migrated project.

---

## 1. Review the Transformed Project File

Open `AdoCore.csproj` and confirm the following:

- The `<TargetFramework>` element targets a supported cross-platform .NET version, such as `net8.0` or `net9.0`.
- Any previously Windows-specific references (e.g., `System.Web`, COM references, or Windows registry APIs) have been removed or replaced with cross-platform equivalents.
- NuGet package references are present in `<PackageReference>` format rather than the legacy `packages.config` format.

---

## 2. Restore NuGet Packages

Run the following command from the solution root to ensure all dependencies are resolved:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved dependencies.

---

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete API usage, as these can indicate compatibility concerns.

---

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee runtime correctness, so test coverage is important here.

---

## 5. Validate Cross-Platform Behavior

If the intent is to run on non-Windows platforms, perform the following:

- Run the application or test suite on the target platform (Linux or macOS) to surface any platform-specific runtime issues.
- Check for any usage of `System.Runtime.InteropServices.RuntimeInformation.IsOSPlatform` guards that may have been added during transformation, and verify they behave as expected.
- Look for any file path handling code that uses hardcoded backslashes (`\`) and replace with `Path.Combine` or `Path.DirectorySeparatorChar` where applicable.

---

## 6. Check for Removed or Changed APIs

Some .NET Framework APIs are not available in cross-platform .NET. Use the .NET Upgrade Assistant compatibility analyzer or the following command to check for any remaining compatibility issues:

```bash
dotnet tool install -g dotnet-compatibility
```

Alternatively, review the [.NET API compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) for APIs that were removed or changed between .NET Framework and modern .NET.

---

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, such as `win-x64`, `linux-x64`, or `osx-x64`.

Review the publish output directory to confirm all required files are present before deployment.