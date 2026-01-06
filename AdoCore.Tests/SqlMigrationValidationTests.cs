using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using Xunit;

namespace AdoCore.Tests
{
    /// <summary>
    /// Tests to validate that SQL statement migration was performed correctly
    /// and all statements were processed through the DMS and SQL Equivalency tools.
    /// These tests verify transformation artifacts and migration documentation.
    /// </summary>
    public class SqlMigrationValidationTests
    {
        private readonly string _projectRoot;

        public SqlMigrationValidationTests()
        {
            // Navigate up from test output directory to find source code root
            _projectRoot = FindProjectRoot(AppDomain.CurrentDomain.BaseDirectory);
        }

        private string FindProjectRoot(string startPath)
        {
            var directory = new DirectoryInfo(startPath);
            while (directory != null)
            {
                if (File.Exists(Path.Combine(directory.FullName, "AdoCore.csproj")))
                {
                    return directory.FullName;
                }
                directory = directory.Parent;
            }
            throw new DirectoryNotFoundException("Could not find project root containing AdoCore.csproj");
        }

        [Fact]
        public void ExtractedStatementsFile_Exists()
        {
            // Arrange
            var filePath = Path.Combine(_projectRoot, "extracted_statements.sql");

            // Act & Assert
            Assert.True(File.Exists(filePath),
                $"extracted_statements.sql should exist at {filePath}");
        }

        [Fact]
        public void ConvertedStatementsFile_Exists()
        {
            // Arrange
            var filePath = Path.Combine(_projectRoot, "converted_statements.sql");

            // Act & Assert
            Assert.True(File.Exists(filePath),
                $"converted_statements.sql should exist at {filePath}");
        }

        [Fact]
        public void DmsConversionLogFile_Exists()
        {
            // Arrange
            var filePath = Path.Combine(_projectRoot, "dms_conversion_log.json");

            // Act & Assert
            Assert.True(File.Exists(filePath),
                $"dms_conversion_log.json should exist at {filePath}");
        }

        [Fact]
        public void SqlEquivalencyReportFile_Exists()
        {
            // Arrange
            var filePath = Path.Combine(_projectRoot, "sql_equivalency_validation_report.json");

            // Act & Assert
            Assert.True(File.Exists(filePath),
                $"sql_equivalency_validation_report.json should exist at {filePath}");
        }

        [Fact]
        public void FinalMigrationReportFile_Exists()
        {
            // Arrange
            var filePath = Path.Combine(_projectRoot, "final_migration_report.md");

            // Act & Assert
            Assert.True(File.Exists(filePath),
                $"final_migration_report.md should exist at {filePath}");
        }

        [Fact]
        public void DmsConversionLog_ContainsAllExpectedStatements()
        {
            // Arrange
            var filePath = Path.Combine(_projectRoot, "dms_conversion_log.json");
            var jsonContent = File.ReadAllText(filePath);
            var doc = JsonDocument.Parse(jsonContent);
            var root = doc.RootElement;

            // Expected method names based on ProductRepository
            var expectedMethods = new HashSet<string>
            {
                "GetAllProductsAsync",
                "GetProductByIdAsync",
                "InsertProductAsync",
                "UpdateProductAsync",
                "DeleteProductAsync",
                "GetProductsByPriceRangeAsync",
                "GetLowStockProductsAsync"
            };

            // Act - Extract method names from statements
            var foundMethods = new HashSet<string>();
            if (root.TryGetProperty("statements", out var statements))
            {
                foreach (var statement in statements.EnumerateArray())
                {
                    if (statement.TryGetProperty("method_name", out var methodName))
                    {
                        foundMethods.Add(methodName.GetString());
                    }
                }
            }

            // Assert
            Assert.Equal(expectedMethods.Count, foundMethods.Count);
            Assert.True(expectedMethods.SetEquals(foundMethods),
                $"Expected all 7 methods to be documented. Missing: {string.Join(", ", expectedMethods.Except(foundMethods))}");
        }

        [Fact]
        public void SqlEquivalencyReport_ContainsAllExpectedStatements()
        {
            // Arrange
            var filePath = Path.Combine(_projectRoot, "sql_equivalency_validation_report.json");
            var jsonContent = File.ReadAllText(filePath);
            var doc = JsonDocument.Parse(jsonContent);
            var root = doc.RootElement;

            // Act
            Assert.True(root.TryGetProperty("number_of_statements_processed", out var processedCount),
                "Report should contain number_of_statements_processed");

            var statementCount = processedCount.GetInt32();

            // Assert - Should have 7 statements (one for each repository method)
            Assert.Equal(7, statementCount);
        }

        [Fact]
        public void SqlEquivalencyReport_ContainsRequiredMetrics()
        {
            // Arrange
            var filePath = Path.Combine(_projectRoot, "sql_equivalency_validation_report.json");
            var jsonContent = File.ReadAllText(filePath);
            var doc = JsonDocument.Parse(jsonContent);
            var root = doc.RootElement;

            // Act & Assert
            Assert.True(root.TryGetProperty("number_of_statements_processed", out _),
                "Report should contain number_of_statements_processed");

            Assert.True(root.TryGetProperty("number_of_statements_equivalent", out _),
                "Report should contain number_of_statements_equivalent");

            Assert.True(root.TryGetProperty("number_of_statements_non_equivalent", out _),
                "Report should contain number_of_statements_non_equivalent");

            Assert.True(root.TryGetProperty("number_of_statements_with_equivalency_error", out _),
                "Report should contain number_of_statements_with_equivalency_error");

            Assert.True(root.TryGetProperty("statement_details", out var details) && details.ValueKind == JsonValueKind.Array,
                "Report should contain statement_details array");
        }

        [Fact]
        public void SqlEquivalencyReport_AllStatementsHaveConversionMethod()
        {
            // Arrange
            var filePath = Path.Combine(_projectRoot, "sql_equivalency_validation_report.json");
            var jsonContent = File.ReadAllText(filePath);
            var doc = JsonDocument.Parse(jsonContent);
            var root = doc.RootElement;

            // Act
            root.TryGetProperty("statement_details", out var details);

            // Assert
            foreach (var statement in details.EnumerateArray())
            {
                Assert.True(statement.TryGetProperty("conversion_method", out var method),
                    "Each statement should have a conversion_method");

                var methodValue = method.GetString();
                Assert.True(
                    methodValue == "DMS_TOOL" || methodValue == "MANUAL_AFTER_DMS_FAILURE",
                    $"Conversion method should be either DMS_TOOL or MANUAL_AFTER_DMS_FAILURE, got: {methodValue}");
            }
        }

        [Fact]
        public void SqlEquivalencyReport_AllStatementsHaveEquivalencyStatus()
        {
            // Arrange
            var filePath = Path.Combine(_projectRoot, "sql_equivalency_validation_report.json");
            var jsonContent = File.ReadAllText(filePath);
            var doc = JsonDocument.Parse(jsonContent);
            var root = doc.RootElement;

            // Act
            root.TryGetProperty("statement_details", out var details);

            // Assert
            foreach (var statement in details.EnumerateArray())
            {
                Assert.True(statement.TryGetProperty("equivalency_status", out var status),
                    "Each statement should have an equivalency_status");

                var statusValue = status.GetString();
                Assert.True(
                    statusValue == "EQUIVALENT" ||
                    statusValue == "NOT_EQUIVALENT" ||
                    statusValue == "ERROR",
                    $"Equivalency status should be EQUIVALENT, NOT_EQUIVALENT, or ERROR, got: {statusValue}");
            }
        }

        [Fact]
        public void SqlEquivalencyReport_AllStatementsHaveToolOutput()
        {
            // Arrange
            var filePath = Path.Combine(_projectRoot, "sql_equivalency_validation_report.json");
            var jsonContent = File.ReadAllText(filePath);
            var doc = JsonDocument.Parse(jsonContent);
            var root = doc.RootElement;

            // Act
            root.TryGetProperty("statement_details", out var details);

            // Assert
            foreach (var statement in details.EnumerateArray())
            {
                Assert.True(statement.TryGetProperty("equivalency_tool_output", out var output),
                    "Each statement should have equivalency_tool_output");

                // Verify it's not null or empty
                Assert.NotEqual(JsonValueKind.Null, output.ValueKind);
            }
        }

        [Fact]
        public void ConvertedStatements_ContainPostgreSQLSyntax()
        {
            // Arrange
            var filePath = Path.Combine(_projectRoot, "converted_statements.sql");
            var content = File.ReadAllText(filePath);

            // Act & Assert - Check for PostgreSQL-specific syntax
            Assert.DoesNotContain("SCOPE_IDENTITY()", content);

            Assert.DoesNotContain("GETDATE()", content);

            // PostgreSQL equivalents should be present
            Assert.Contains("CURRENT_TIMESTAMP", content);
        }

        [Fact]
        public void ProductRepository_DoesNotContainSqlServerSyntax()
        {
            // Arrange
            var filePath = Path.Combine(_projectRoot, "DataAccess", "ProductRepository.cs");
            var content = File.ReadAllText(filePath);

            // Act & Assert
            Assert.DoesNotContain("SqlConnection", content);

            Assert.DoesNotContain("SqlCommand", content);

            Assert.DoesNotContain("SqlDataReader", content);

            Assert.DoesNotContain("Microsoft.Data.SqlClient", content);

            Assert.Contains("Npgsql", content);
        }

        [Fact]
        public void ProjectFile_UsesNpgsqlPackage()
        {
            // Arrange
            var filePath = Path.Combine(_projectRoot, "AdoCore.csproj");
            var content = File.ReadAllText(filePath);

            // Act & Assert
            Assert.Contains("Npgsql", content);

            Assert.DoesNotContain("Microsoft.Data.SqlClient", content);

            Assert.DoesNotContain("System.Data.SqlClient", content);
        }

        [Fact]
        public void ConnectionStrings_UsePostgreSQLFormat()
        {
            // Arrange
            var filePath = Path.Combine(_projectRoot, "appsettings.json");
            var content = File.ReadAllText(filePath);

            // Act & Assert
            Assert.Contains("Host=", content);

            Assert.DoesNotContain("Server=", content);

            Assert.DoesNotContain("Integrated Security", content);

            Assert.Contains("Username=", content);
        }
    }
}
