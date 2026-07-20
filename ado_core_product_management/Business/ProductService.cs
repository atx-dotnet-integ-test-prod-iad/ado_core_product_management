using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using AdoCore.DataAccess;
using AdoCore.Models;

namespace AdoCore.Business
{
    public class ProductService
    {
        private readonly ProductRepository _repository;

        public ProductService(ProductRepository repository)
        {
            _repository = repository;
        }

        public async Task<List<Product>> GetAllProductsAsync()
        {
            return await _repository.GetAllProductsAsync();
        }

        public async Task<Product> GetProductAsync(int productId)
        {
            return await _repository.GetProductByIdAsync(productId);
        }

        public async Task<int> CreateProductAsync(Product product)
        {
            ValidateProduct(product);

            return await _repository.InsertProductAsync(product);
        }

        public async Task UpdateProductAsync(Product product)
        {
            ValidateProduct(product);

            await _repository.UpdateProductAsync(product);
        }

        public async Task DeleteProductAsync(int productId)
        {
            await _repository.DeleteProductAsync(productId);
        }

        public async Task UpdateProductStockAsync(int productId, int newQuantity)
        {
            if (newQuantity < 0)
            {
                throw new ArgumentException("Quantity cannot be negative");
            }

            var product = await _repository.GetProductByIdAsync(productId);
            if (product == null)
            {
                throw new ArgumentException($"Product with ID {productId} not found.");
            }

            product.StockQuantity = newQuantity;
            await _repository.UpdateProductAsync(product);
        }

        private void ValidateProduct(Product product)
        {
            if (string.IsNullOrWhiteSpace(product.Name))
            {
                throw new ArgumentException("Product name is required");
            }

            if (product.Price < 0)
            {
                throw new ArgumentException("Product price cannot be negative");
            }

            if (product.StockQuantity < 0)
            {
                throw new ArgumentException("Product stock quantity cannot be negative");
            }
        }
    }
} 