# ADO.NET Core SQL Server Data Management Application

This is a .NET Core application demonstrating modern ADO.NET integration with SQL Server, following best practices for data access and application architecture.

## Prerequisites

- Visual Studio 2022 or later
- .NET 9.0 SDK or later
- SQL Server 2019 or later (Developer Edition is free and recommended for development)
- SQL Server Management Studio (SSMS) or Azure Data Studio

## Project Structure

```
AdoCore/
├── DataAccess/
│   └── ProductRepository.cs
├── Models/
│   └── Product.cs
├── Business/
│   └── ProductService.cs
├── CLI/
│   ├── CommandLineInterface.cs
│   └── InteractiveMenu.cs
├── Program.cs
├── AdoCore.csproj
└── appsettings.json
```

## Setup Instructions

### Option 1: Using Visual Studio

1. **Open the Project**:
   - Open Visual Studio 2022
   - Select "Open a project or solution"
   - Navigate to the project folder and select `AdoCore.csproj`

2. **Restore NuGet Packages**:
   - Right-click on the solution in Solution Explorer
   - Select "Restore NuGet Packages"

3. **Database Setup**:
   - Open SQL Server Management Studio (SSMS) or Azure Data Studio
   - Connect to your local SQL Server instance
   - Open and run the script: `Database/Scripts/01_InitialSetup.sql`

4. **Update Connection String**:
   - In Solution Explorer, open `appsettings.json`
   - Update the connection string if needed:
   ```json
   {
     "ConnectionStrings": {
       "DevConnection": "Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True",
       "ProdConnection": "your-production-connection-string"
     },
     "Environment": "Development"
   }
   ```

5. **Run the Application**:
   - Press F5 to run in debug mode
   - Or press Ctrl+F5 to run without debugging
   - The application will start in interactive mode

### Option 2: Using Command Line

1. **Prerequisites Check**:
   ```bash
   # Verify .NET 9.0 SDK is installed
   dotnet --version
   # Should show 9.0.x
   ```

2. **Database Setup**:
   ```bash
   # Open SQL Server Management Studio (SSMS) or Azure Data Studio
   # Connect to your local SQL Server instance
   # Open and run the script: Database/Scripts/01_InitialSetup.sql
   ```

3. **Project Setup**:
   ```bash
   # Navigate to project directory
   cd D:\ado_core

   # Restore NuGet packages
   dotnet restore

   # Update connection string in appsettings.json if needed
   # Current connection string is:
   # "Server=localhost;Database=ProductManagement;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True"
   ```

4. **Build and Run**:
   ```bash
   # Build the project
   dotnet build

   # Run in interactive mode
   dotnet run

   # Or run with CLI commands
   dotnet run -- list
   ```

## Running the Application

The application can be run in two modes: Interactive (menu-driven) and Command-Line Interface (CLI).

### Interactive Mode

1. Run the application without any arguments:
   ```bash
   dotnet run
   ```
2. You'll see the main menu with these options:
   ```
   Product Management System
   ------------------------
   1. List all products
   2. Get product by ID
   3. Create new product
   4. Update product
   5. Delete product
   6. Update product stock
   Q. Quit
   ```

### Command-Line Interface (CLI)

The application supports the following commands:

```bash
# Show help
dotnet run -- --help

# List all products
dotnet run -- list

# Get product by ID
dotnet run -- get 1

# Add new product
dotnet run -- add "Gaming Mouse" 49.99 10 "High-performance gaming mouse"

# Update product
dotnet run -- update 1 "Gaming Mouse Pro" 59.99 15 "Updated gaming mouse"

# Delete product
dotnet run -- delete 1

# Update stock quantity
dotnet run -- stock 1 20
```

## Key Features

- Modern async/await patterns for all database operations
- Proper resource management with IAsyncDisposable
- Dependency injection for configuration
- Transaction support with async operations
- Parameterized queries for security
- Connection pooling and management
- Error handling and logging

## Testing the Application

1. Try listing products:
   ```bash
   dotnet run -- list
   ```

2. Add a new product:
   ```bash
   dotnet run -- add "Test Product" 29.99 5 "Test Description"
   ```

3. View the product details:
   ```bash
   dotnet run -- get 1
   ```

## Troubleshooting

If you encounter errors:
1. Verify SQL Server is running (check Services)
2. Confirm your connection string matches your SQL Server instance name
3. Ensure the `ProductManagement` database was created successfully
4. Check you have appropriate permissions to access the database
5. Make sure all required NuGet packages are restored:
   ```bash
   dotnet restore
   ```

## Required NuGet Packages

- Microsoft.Data.SqlClient
- Microsoft.Extensions.Configuration
- Microsoft.Extensions.Configuration.Json
- Microsoft.Extensions.DependencyInjection

## Security Considerations

- All database queries use parameterization to prevent SQL injection
- Connection strings are stored securely in configuration
- Proper error handling and logging is implemented
- All database resources are properly disposed using async patterns
- TrustServerCertificate option for development environments

## Best Practices Implemented

- Modern async/await patterns
- Proper resource disposal with IAsyncDisposable
- Transaction management with async support
- Error handling and logging
- Configuration management using .NET Core's IConfiguration
- Security best practices
- Dependency injection
- Separation of concerns (layered architecture)

## Deployment to AWS EC2

1. Ensure SQL Server is installed and configured on the EC2 instance
2. Update the production connection string in appsettings.json
3. Deploy the application using Visual Studio's Publish feature 