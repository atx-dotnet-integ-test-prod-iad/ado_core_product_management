using System;
using System.Threading.Tasks;
using AdoCore.Business;
using AdoCore.CLI;
using AdoCore.DataAccess;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace AdoCore
{
    class Program
    {
        static async Task Main(string[] args)
        {
            var configuration = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json", optional: false)
                .Build();

            var services = new ServiceCollection();
            ConfigureServices(services, configuration);
            var serviceProvider = services.BuildServiceProvider();

            if (args.Length > 0)
            {
                var cli = serviceProvider.GetRequiredService<CommandLineInterface>();
                await cli.ProcessCommandAsync(args);
            }
            else
            {
                var menu = serviceProvider.GetRequiredService<InteractiveMenu>();
                await menu.RunAsync();
            }
        }

        private static void ConfigureServices(IServiceCollection services, IConfiguration configuration)
        {
            services.AddSingleton(configuration);
            services.AddScoped<ProductRepository>();
            services.AddScoped<ProductService>();
            services.AddScoped<CommandLineInterface>();
            services.AddScoped<InteractiveMenu>();
        }
    }
} 