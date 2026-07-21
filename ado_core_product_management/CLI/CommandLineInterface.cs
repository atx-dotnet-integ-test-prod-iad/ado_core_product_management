using System;
using System.Threading.Tasks;
using AdoCore.Business;
using AdoCore.Models;

namespace AdoCore.CLI
{
    public class CommandLineInterface
    {
        private readonly ProductService _productService;

        public CommandLineInterface(ProductService productService)
        {
            _productService = productService;
        }

        public async Task ProcessCommandAsync(string[] args)
        {
            if (args.Length == 0)
            {
                ShowHelp();
                return;
            }

            var command = args[0].ToLower();
            try
            {
                switch (command)
                {
                    case "--help":
                    case "-h":
                        ShowHelp();
                        break;
                    case "list":
                        await ListAllProductsAsync();
                        break;
                    case "get":
                        if (args.Length < 2 || !int.TryParse(args[1], out int id))
                        {
                            Console.WriteLine("Error: Please provide a valid product ID");
                            return;
                        }
                        await GetProductByIdAsync(id);
                        break;
                    case "add":
                        if (args.Length < 5)
                        {
                            Console.WriteLine("Error: Please provide all required product details");
                            return;
                        }
                        await AddNewProductAsync(args);
                        break;
                    case "update":
                        if (args.Length < 6)
                        {
                            Console.WriteLine("Error: Please provide all required product details");
                            return;
                        }
                        await UpdateProductAsync(args);
                        break;
                    case "delete":
                        if (args.Length < 2 || !int.TryParse(args[1], out int deleteId))
                        {
                            Console.WriteLine("Error: Please provide a valid product ID");
                            return;
                        }
                        await DeleteProductAsync(deleteId);
                        break;
                    case "stock":
                        if (args.Length < 3 || !int.TryParse(args[1], out int stockId) || !int.TryParse(args[2], out int quantity))
                        {
                            Console.WriteLine("Error: Please provide valid product ID and quantity");
                            return;
                        }
                        await UpdateProductStockAsync(stockId, quantity);
                        break;
                    default:
                        Console.WriteLine($"Unknown command: {command}");
                        ShowHelp();
                        break;
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error: {ex.Message}");
                if (ex.InnerException != null)
                {
                    Console.WriteLine($"Details: {ex.InnerException.Message}");
                }
            }
        }

        private void ShowHelp()
        {
            Console.WriteLine("Usage: dotnet run -- [command] [arguments]");
            Console.WriteLine("\nCommands:");
            Console.WriteLine("  list                    List all products");
            Console.WriteLine("  get <id>               Get product by ID");
            Console.WriteLine("  add <name> <price> <quantity> <description>");
            Console.WriteLine("                          Add new product");
            Console.WriteLine("  update <id> <name> <price> <quantity> <description>");
            Console.WriteLine("                          Update existing product");
            Console.WriteLine("  delete <id>            Delete product");
            Console.WriteLine("  stock <id> <quantity>  Update product stock");
            Console.WriteLine("  --help, -h             Show this help message");
        }

        private async Task ListAllProductsAsync()
        {
            var products = await _productService.GetAllProductsAsync();
            if (products.Count == 0)
            {
                Console.WriteLine("No products found.");
                return;
            }

            foreach (var product in products)
            {
                Console.WriteLine("\n" + product.ToString());
            }
        }

        private async Task GetProductByIdAsync(int id)
        {
            var product = await _productService.GetProductAsync(id);
            if (product == null)
            {
                Console.WriteLine($"Product with ID {id} not found.");
                return;
            }

            Console.WriteLine("\n" + product.ToString());
        }

        private async Task AddNewProductAsync(string[] args)
        {
            var product = new Product
            {
                Name = args[1],
                Price = decimal.Parse(args[2]),
                StockQuantity = int.Parse(args[3]),
                Description = args[4]
            };

            var newId = await _productService.CreateProductAsync(product);
            Console.WriteLine($"Product created successfully with ID: {newId}");
        }

        private async Task UpdateProductAsync(string[] args)
        {
            var product = new Product
            {
                ProductId = int.Parse(args[1]),
                Name = args[2],
                Price = decimal.Parse(args[3]),
                StockQuantity = int.Parse(args[4]),
                Description = args[5]
            };

            await _productService.UpdateProductAsync(product);
            Console.WriteLine("Product updated successfully.");
        }

        private async Task DeleteProductAsync(int id)
        {
            await _productService.DeleteProductAsync(id);
            Console.WriteLine("Product deleted successfully.");
        }

        private async Task UpdateProductStockAsync(int id, int quantity)
        {
            await _productService.UpdateProductStockAsync(id, quantity);
            Console.WriteLine("Stock updated successfully.");
        }
    }
} 