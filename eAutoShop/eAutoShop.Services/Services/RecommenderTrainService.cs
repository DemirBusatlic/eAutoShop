using eAutoShop.Model.Exceptions;
using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using eAutoShop.Services.Interfaces;
using eAutoShop.Services.StateMachineService.OrderStateMachine;
using eAutoShop.Services.Utilities;
using Microsoft.EntityFrameworkCore;
using Microsoft.ML;
using Microsoft.ML.Trainers;

namespace eAutoShop.Services.Services
{
    public class RecommenderTrainService : IRecommenderTrainService
    {
        protected readonly AutoShopContext _context;

        private static readonly MLContext mlContext = new MLContext();

        private static readonly SemaphoreSlim trainingLock =new SemaphoreSlim(1, 1);

        public RecommenderTrainService(AutoShopContext context)
        {
            _context = context;
        }

        public async Task TrainProductsModel()
        {
            await trainingLock.WaitAsync();

            try
            {
                var orders = await _context.Orders
                    .AsNoTracking()
                    .Include(x => x.OrderItems)
                    .Where(x => x.State == OrderStates.Completed)
                    .ToListAsync();

                if (!orders.Any())
                {
                    throw new UserException(
                        "Nema dovoljno završenih narudžbi za " +
                        "treniranje sistema preporuke.");
                }

                var data = new List<ProductEntry>();

                foreach (var order in orders)
                {
                    var productIds = order.OrderItems
                        .Select(x => x.ProductId)
                        .Distinct()
                        .ToList();

                    if (productIds.Count < 2)
                    {
                        continue;
                    }

                    foreach (var productId in productIds)
                    {
                        var relatedProductIds = productIds.Where(id => id != productId);

                        foreach (var relatedProductId in relatedProductIds)
                        {
                            data.Add(
                                new ProductEntry
                                {
                                    ProductId = (uint)productId,
                                    CoPurchaseProductId =(uint)relatedProductId,
                                    Label = 1
                                });
                        }
                    }
                }

                if (!data.Any())
                {
                    throw new UserException(
                        "Nema dovoljno povezanih proizvoda za " +
                        "treniranje sistema preporuke.");
                }

                var trainData =mlContext.Data.LoadFromEnumerable(data);

                var options =new MatrixFactorizationTrainer.Options
                    {
                        MatrixColumnIndexColumnName =nameof(ProductEntry.ProductId),

                        MatrixRowIndexColumnName =nameof(ProductEntry.CoPurchaseProductId),
                        LabelColumnName =nameof(ProductEntry.Label),
                        LossFunction =MatrixFactorizationTrainer
                                .LossFunctionType
                                .SquareLossOneClass,
                        Alpha = 0.01,
                        Lambda = 0.025,
                        NumberOfIterations = 100,
                        C = 0.00001
                    };

                var trainer = mlContext
                    .Recommendation()
                    .Trainers
                    .MatrixFactorization(options);

                var model = trainer.Fit(trainData);

                try
                {
                    var modelsPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory,"RecommenderModels");

                    Directory.CreateDirectory(modelsPath);

                    var productsModelPath = Path.Combine(modelsPath,"productsmodel.zip");

                    mlContext.Model.Save(
                        model,
                        trainData.Schema,
                        productsModelPath);
                }
                catch
                {
                    throw new UserException(
                        "Model preporuka nije moguće sačuvati. " +
                        "Pokušajte ponovo kasnije.");
                }
            }
            finally
            {
                trainingLock.Release();
            }
        }
    }
}