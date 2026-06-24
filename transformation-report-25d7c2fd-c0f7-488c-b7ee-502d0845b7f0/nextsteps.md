# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework. Replace any packages that only support `.NET Framework` with their cross-platform equivalents where applicable.

## 3. Build the Solution

Perform a full build to confirm no errors surface during compilation:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings (CA1416).

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify behavioral correctness after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as failures may indicate behavioral differences between .NET Framework and modern .NET (e.g., changes in `System.Data`, threading, or serialization behavior).

## 5. Validate Platform-Specific Code

Search the codebase for APIs that are known to behave differently or are unavailable on cross-platform .NET:

- `System.Web` references (not available outside of ASP.NET Core)
- Windows Registry access (`Microsoft.Win32.Registry`)
- COM interop or P/Invoke calls
- `AppDomain.CreateDomain` (not supported in .NET 5+)
- `BinaryFormatter` (deprecated and disabled by default in .NET 5+)

Run the .NET Upgrade Assistant compatibility analyzer if a deeper audit is needed:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution-file>.sln
```

## 6. Test on Target Platforms

Since the goal is cross-platform support, run and validate the application on each intended operating system (Windows, Linux, macOS):

```bash
dotnet run --configuration Release
```

Pay attention to:
- File path separator differences (`\` vs `/`) — use `Path.Combine` throughout.
- Case-sensitive file systems on Linux.
- Environment variable differences across operating systems.

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime(s).

**Framework-dependent publish:**

```bash
dotnet publish -c Release -o ./publish
```

**Self-contained publish for a specific runtime:**

```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish/linux-x64
dotnet publish -c Release -r win-x64 --self-contained true -o ./publish/win-x64
```

Review the contents of the output directory to confirm all required assets and dependencies are present before distributing or deploying.