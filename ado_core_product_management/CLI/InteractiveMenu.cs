using System;
using System.Threading.Tasks;
using AdoCore.Business;
using AdoCore.Models;

namespace AdoCore.CLI
{
    public class InteractiveMenu
    {
        private readonly ProductService _productService;

        public InteractiveMenu(ProductService productService)
        {
            _productService = productService;
        }

        public async Task RunAsync()
        {
            while (true)
            {
                try
                {
                    ShowMenu();
                    var choice = Console.ReadLine();

                    switch (choice?.ToLower())
                    {
                        case "1":
                            await ListAllProductsAsync();
                            break;
                        case "2":
                            await GetProductByIdAsync();
                            break;
                        case "3":
                            await CreateNewProductAsync();
                            break;
                        case "4":
                            await UpdateExistingProductAsync();
                            break;
                        case "5":
                            await DeleteExistingProductAsync();
                            break;
                        case "6":
                            await UpdateProductStockAsync();
                            break;
                        case "q":
                            return;
                        default:
                            Console.WriteLine("\nInvalid choice. Please try again.");
                            break;
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"\nError: {ex.Message}");
                    if (ex.InnerException != null)
                    {
                        Console.WriteLine($"Details: {ex.InnerException.Message}");
                    }
                }

                Console.WriteLine("\nPress any key to continue...");
                Console.ReadKey();
                Console.Clear();
            }
        }

        private void ShowMenu()
        {
            Console.WriteLine("Product Management System");
            Console.WriteLine("------------------------");
            Console.WriteLine("1. List all products");
            Console.WriteLine("2. Get product by ID");
            Console.WriteLine("3. Create new product");
            Console.WriteLine("4. Update product");
            Console.WriteLine("5. Delete product");
            Console.WriteLine("6. Update product stock");
            Console.WriteLine("Q. Quit");
            Console.Write("\nEnter your choice: ");
        }

        private async Task ListAllProductsAsync()
        {
            var products = await _productService.GetAllProductsAsync();
            if (products.Count == 0)
            {
                Console.WriteLine("\nNo products found.");
                return;
            }

            Console.WriteLine("\nProducts List:");
            Console.WriteLine("-------------");
            foreach (var product in products)
            {
                Console.WriteLine("\n" + product.ToString());
            }
        }

        private async Task GetProductByIdAsync()
        {
            Console.Write("\nEnter product ID: ");
            if (int.TryParse(Console.ReadLine(), out int id))
            {
                var product = await _productService.GetProductAsync(id);
                if (product == null)
                {
                    Console.WriteLine($"\nProduct with ID {id} not found.");
                    return;
                }
                Console.WriteLine("\n" + product.ToString());
            }
            else
            {
                Console.WriteLine("Invalid ID format.");
            }
        }

        private async Task CreateNewProductAsync()
        {
            var product = await GetProductDetailsFromUserAsync();
            var newId = await _productService.CreateProductAsync(product);
            Console.WriteLine($"\nProduct created successfully with ID: {newId}");
        }

        private async Task UpdateExistingProductAsync()
        {
            Console.Write("\nEnter product ID to update: ");
            if (int.TryParse(Console.ReadLine(), out int id))
            {
                var existingProduct = await _productService.GetProductAsync(id);
                if (existingProduct == null)
                {
                    Console.WriteLine($"\nProduct with ID {id} not found.");
                    return;
                }

                var updatedProduct = await GetProductDetailsFromUserAsync();
                updatedProduct.ProductId = id;
                await _productService.UpdateProductAsync(updatedProduct);
                Console.WriteLine("Product updated successfully.");
            }
            else
            {
                Console.WriteLine("Invalid ID format.");
            }
        }

        private async Task DeleteExistingProductAsync()
        {
            Console.Write("\nEnter product ID to delete: ");
            if (int.TryParse(Console.ReadLine(), out int id))
            {
                await _productService.DeleteProductAsync(id);
                Console.WriteLine("Product deleted successfully.");
            }
            else
            {
                Console.WriteLine("Invalid ID format.");
            }
        }

        private async Task UpdateProductStockAsync()
        {
            Console.Write("\nEnter product ID: ");
            if (!int.TryParse(Console.ReadLine(), out int id))
            {
                Console.WriteLine("Invalid ID format.");
                return;
            }

            Console.Write("Enter new stock quantity: ");
            if (!int.TryParse(Console.ReadLine(), out int quantity))
            {
                Console.WriteLine("Invalid quantity format.");
                return;
            }

            await _productService.UpdateProductStockAsync(id, quantity);
            Console.WriteLine("Stock updated successfully.");
        }

        private async Task<Product> GetProductDetailsFromUserAsync()
        {
            Console.Write("\nEnter product name: ");
            var name = Console.ReadLine();

            Console.Write("Enter product description (optional): ");
            var description = Console.ReadLine();

            Console.Write("Enter price: ");
            decimal price = 0;
            decimal.TryParse(Console.ReadLine(), out price);

            Console.Write("Enter stock quantity: ");
            int quantity = 0;
            int.TryParse(Console.ReadLine(), out quantity);

            return new Product
            {
                Name = name,
                Description = string.IsNullOrWhiteSpace(description) ? null : description,
                Price = price,
                StockQuantity = quantity
            };
        }
    }
} 