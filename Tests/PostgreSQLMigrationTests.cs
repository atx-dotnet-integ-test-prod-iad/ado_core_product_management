using System;
using Xunit;

namespace AdoCore.Tests
{
    /// <summary>
    /// Integration tests to verify PostgreSQL migration.
    /// These tests validate the conversion from SQL Server to PostgreSQL.
    /// </summary>
    public class PostgreSQLMigrationTests
    {
        [Fact]
        public void PostgreSQL_NpgsqlPackage_IsInstalled()
        {
            // Arrange & Act
            var npgsqlType = Type.GetType("Npgsql.NpgsqlConnection, Npgsql");

            // Assert
            Assert.NotNull(npgsqlType);
        }

        [Fact]
        public void PostgreSQL_NpgsqlConnectionClass_IsAvailable()
        {
            // Arrange & Act
            var npgsqlConnectionType = Type.GetType("Npgsql.NpgsqlConnection, Npgsql");

            // Assert
            Assert.NotNull(npgsqlConnectionType);
            Assert.Equal("NpgsqlConnection", npgsqlConnectionType.Name);
        }

        [Fact]
        public void PostgreSQL_NpgsqlCommandClass_IsAvailable()
        {
            // Arrange & Act
            var npgsqlCommandType = Type.GetType("Npgsql.NpgsqlCommand, Npgsql");

            // Assert
            Assert.NotNull(npgsqlCommandType);
            Assert.Equal("NpgsqlCommand", npgsqlCommandType.Name);
        }

        [Fact]
        public void PostgreSQL_NpgsqlDataReaderClass_IsAvailable()
        {
            // Arrange & Act
            var npgsqlDataReaderType = Type.GetType("Npgsql.NpgsqlDataReader, Npgsql");

            // Assert
            Assert.NotNull(npgsqlDataReaderType);
            Assert.Equal("NpgsqlDataReader", npgsqlDataReaderType.Name);
        }

        [Fact]
        public void PostgreSQL_NpgsqlParameterClass_IsAvailable()
        {
            // Arrange & Act
            var npgsqlParameterType = Type.GetType("Npgsql.NpgsqlParameter, Npgsql");

            // Assert
            Assert.NotNull(npgsqlParameterType);
            Assert.Equal("NpgsqlParameter", npgsqlParameterType.Name);
        }

        [Fact]
        public void PostgreSQL_NpgsqlTransactionClass_IsAvailable()
        {
            // Arrange & Act
            var npgsqlTransactionType = Type.GetType("Npgsql.NpgsqlTransaction, Npgsql");

            // Assert
            Assert.NotNull(npgsqlTransactionType);
            Assert.Equal("NpgsqlTransaction", npgsqlTransactionType.Name);
        }

        [Fact]
        public void SQLServer_SqlClientPackage_IsNotInstalled()
        {
            // Arrange & Act
            var sqlConnectionType = Type.GetType("Microsoft.Data.SqlClient.SqlConnection, Microsoft.Data.SqlClient");

            // Assert
            Assert.Null(sqlConnectionType);
        }

        [Fact]
        public void SQLServer_SystemDataSqlClient_IsNotUsed()
        {
            // Arrange & Act
            var legacySqlConnectionType = Type.GetType("System.Data.SqlClient.SqlConnection, System.Data.SqlClient");

            // Assert
            // Should be null as we've migrated away from SQL Server
            Assert.Null(legacySqlConnectionType);
        }
    }
}
