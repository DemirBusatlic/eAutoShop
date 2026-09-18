using eAutoShop.Model.Model;
using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using eAutoShop.Services.Interfaces;
using eAutoShop.Services.Utilities;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.ML;

namespace eAutoShop.Services.Services
{
    public class RecommenderPredictService: IRecommenderPredictService
    {
        private readonly AutoShopContext _context;
        private readonly IMapper _mapper;
        private readonly ILogger<RecommenderPredictService> _logger;

        private static readonly MLContext MlContext = new();

        public RecommenderPredictService(AutoShopContext context, IMapper mapper, ILogger<RecommenderPredictService> logger)
        {
            _context = context;
            _mapper = mapper;
            _logger = logger;
        }

        public async Task<PageResult<ProductModel>>RecommendProductsForUser(int customerId)
        {
            var purchasedProductIds = await _context.Orders
                .AsNoTracking()
                .Where(order =>
                    order.CustomerId == customerId &&
                    order.State == OrderStates.Completed)
                .SelectMany(order => order.OrderItems)
                .Select(orderItem => orderItem.ProductId)
                .Distinct()
                .ToListAsync();

            if (purchasedProductIds.Count == 0)
            {
                return EmptyResult();
            }

            var sourceProductId = purchasedProductIds[
                Random.Shared.Next(purchasedProductIds.Count)];

            var sourceProduct = await _context.Products
                .AsNoTracking()
                .FirstOrDefaultAsync(product =>
                    product.Id == sourceProductId);

            if (sourceProduct == null)
            {
                return EmptyResult();
            }

            var candidateProducts = await _context.Products
                .AsNoTracking()
                .Include(product => product.ProductCategory)
                .Include(product => product.CarModels)
                .ThenInclude(carModel => carModel.CarManufacturer)
                .Where(product =>
                product.State == ProductStates.Active &&
                product.Id != sourceProductId)
                .ToListAsync();

            if (candidateProducts.Count == 0)
            {
                return EmptyResult();
            }

            var candidateProductIds = candidateProducts
                .Select(product => product.Id)
                .ToList();

            var coPurchaseCounts = await _context.Orders
                .AsNoTracking()
                .Where(order =>
                    order.State == OrderStates.Completed &&
                    order.OrderItems.Any(orderItem =>
                        orderItem.ProductId == sourceProductId))
                .SelectMany(order => order.OrderItems
                    .Where(orderItem =>
                        orderItem.ProductId != sourceProductId &&
                        candidateProductIds.Contains(
                            orderItem.ProductId))
                    .Select(orderItem => new
                    {
                        orderItem.ProductId,
                        OrderId = order.Id
                    }))
                .GroupBy(item => item.ProductId)
                .Select(group => new
                {
                    ProductId = group.Key,
                    Count = group
                        .Select(item => item.OrderId)
                        .Distinct()
                        .Count()
                })
                .OrderByDescending(item => item.Count)
                .ThenBy(item => item.ProductId)
                .ToListAsync();

            var productsById = candidateProducts
                .ToDictionary(product => product.Id);

            var rankedProducts = coPurchaseCounts
                .Take(3)
                .Select(item => productsById[item.ProductId])
                .ToList();

            var directRecommendationIds = rankedProducts
                .Select(product => product.Id)
                .ToHashSet();

            if (rankedProducts.Count < 3)
            {
                AddMlRecommendations(
                    sourceProductId,
                    candidateProducts,
                    rankedProducts);
            }

            var mappedProducts =
                _mapper.Map<List<ProductModel>>(rankedProducts);

            var coPurchaseCountByProductId = coPurchaseCounts
                .ToDictionary(
                    item => item.ProductId,
                    item => item.Count);

            foreach (var product in mappedProducts)
            {
                if (directRecommendationIds.Contains(product.Id))
                {
                    var purchaseCount = coPurchaseCountByProductId[product.Id];

                    var purchaseCountText = purchaseCount == 1? "1 put" : $"{purchaseCount} puta";


                    product.RecommendationReason =$"Proizvod „{product.Name}“ kupljen je " + $"{purchaseCountText} zajedno sa proizvodom " + $"„{sourceProduct.Name}“ iz vaše historije kupovine.";
                }
                else
                {
                    product.RecommendationReason =$"Preporučeno na osnovu proizvoda „{sourceProduct.Name}“ " + "iz vaše historije kupovine i sličnih kupovina drugih kupaca.";
                }
            }

            return new PageResult<ProductModel>
            {
                Result = mappedProducts,
                Count = mappedProducts.Count
            };
        }

        private void AddMlRecommendations(int sourceProductId,List<Product> candidateProducts,List<Product> rankedProducts)
        {
            try
            {
                var modelPath = Path.Combine(
                    AppDomain.CurrentDomain.BaseDirectory,
                    "RecommenderModels",
                    "productsmodel.zip");

                var model = MlContext.Model.Load(
                    modelPath,
                    out _);

                var predictionEngine =
                    MlContext.Model.CreatePredictionEngine<
                        ProductEntry,
                        CopurchasePrediction>(model);

                var selectedProductIds = rankedProducts
                    .Select(product => product.Id)
                    .ToHashSet();

                var additionalProducts = candidateProducts
                    .Where(product =>
                        !selectedProductIds.Contains(product.Id))
                    .Select(product =>
                    {
                        var prediction = predictionEngine.Predict(
                            new ProductEntry
                            {
                                ProductId =
                                    (uint)sourceProductId,
                                CoPurchaseProductId =
                                    (uint)product.Id
                            });

                        return new
                        {
                            Product = product,
                            prediction.Score
                        };
                    })
                    .OrderByDescending(item => item.Score)
                    .Take(3 - rankedProducts.Count)
                    .Select(item => item.Product);

                rankedProducts.AddRange(additionalProducts);
            }
            catch (Exception exception)
            {
                _logger.LogWarning(exception,"ML.NET model nije mogao dopuniti preporuke za proizvod {ProductId}.",sourceProductId);
            }
        }

        private static PageResult<ProductModel> EmptyResult()
        {
            return new PageResult<ProductModel>
            {
                Result = new List<ProductModel>(),
                Count = 0
            };
        }
    }
}