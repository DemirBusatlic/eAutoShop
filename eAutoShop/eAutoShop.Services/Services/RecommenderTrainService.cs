using eAutoShop.Model.Exceptions;
using eAutoShop.Services.Database;
using eAutoShop.Services.Interfaces;
using eAutoShop.Services.Utilities;
using Microsoft.EntityFrameworkCore;
using Microsoft.ML;
using Microsoft.ML.Trainers;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Services
{
    public class RecommenderTrainService : IRecommenderTrainService
    {
        protected readonly AutoShopContext _context;
        private static readonly MLContext mlContext = new MLContext();
        private static readonly object isLocked = new object();

        public RecommenderTrainService(AutoShopContext context)
        {
            _context = context;
        }

        public void TrainProductsModel()
        {
            lock (isLocked)
            {
                var orders = _context.Orders.Include(x => x.OrderItems).ToList();

                if (orders == null || !orders.Any())
                {
                    throw new UserException("Nema dovoljno podataka za treniranje sistema preporuke.");
                }

                var data = new List<ProductEntry>();

                foreach (var order in orders)
                {
                    if (order.OrderItems.Count > 1)
                    {
                        var productIds = order.OrderItems.Select(x => x.ProductId).ToList();

                        productIds.ForEach(productId =>
                        {
                            var relatedProducts = order.OrderItems
                                .Where(x => x.ProductId != productId);

                            foreach (var relatedProduct in relatedProducts)
                            {
                                data.Add(new ProductEntry
                                {
                                    ProductId = (uint)productId,
                                    CoPurchaseProductId = (uint)relatedProduct.ProductId,
                                    Label = 1
                                });
                            }
                        });
                    }
                }

                if (!data.Any())
                {
                    throw new UserException("Nema dovoljno povezanih proizvoda za treniranje sistema preporuke.");
                }

                var trainData = mlContext.Data.LoadFromEnumerable(data);

                var options = new MatrixFactorizationTrainer.Options
                {
                    MatrixColumnIndexColumnName = nameof(ProductEntry.ProductId),
                    MatrixRowIndexColumnName = nameof(ProductEntry.CoPurchaseProductId),
                    LabelColumnName = nameof(ProductEntry.Label),
                    LossFunction = MatrixFactorizationTrainer.LossFunctionType.SquareLossOneClass,
                    Alpha = 0.01,
                    Lambda = 0.025,
                    NumberOfIterations = 100,
                    C = 0.00001
                };

                var trainer = mlContext.Recommendation().Trainers.MatrixFactorization(options);

                var model = trainer.Fit(trainData);

                try
                {
                    string modelsPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "RecommenderModels");
                    Directory.CreateDirectory(modelsPath);

                    string productsModelPath = Path.Combine(modelsPath, "productsmodel.zip");

                    mlContext.Model.Save(model, trainData.Schema, productsModelPath);
                }
                catch
                {
                    throw new UserException("Server je zauzet. Pokušajte ponovo kasnije.");
                }
            }
        }
    }
}
