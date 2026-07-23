using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Services.Database;
using eAutoShop.Services.Interfaces;
using eAutoShop.Services.Utilities;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.ML;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Services
{
    public class RecommenderPredictService : IRecommenderPredictService
    {
        protected readonly AutoShopContext _context;
        protected readonly IMapper _mapper;
        private static readonly MLContext mlContext = new MLContext();

        public RecommenderPredictService(AutoShopContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public async Task<PageResult<ProductModel>> RecommendProduct(int productId)
        {
            try
            {
                DataViewSchema modelSchema;

                string modelsPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "RecommenderModels");
                string productsModelPath = Path.Combine(modelsPath, "productsmodel.zip");

                ITransformer model = mlContext.Model.Load(productsModelPath, out modelSchema);

                var products = await _context.Products.Where(x => x.Id != productId && x.State == "active").ToListAsync();

                var predictionResult = new List<Tuple<Product, float>>();

                var predictionEngine = mlContext.Model
                    .CreatePredictionEngine<ProductEntry, CopurchasePrediction>(model);

                foreach (var product in products)
                {
                    var prediction = predictionEngine.Predict(new ProductEntry
                    {
                        ProductId = (uint)productId,
                        CoPurchaseProductId = (uint)product.Id
                    });

                    predictionResult.Add(new Tuple<Product, float>(product, prediction.Score));
                }

                var finalResults = predictionResult
                    .OrderByDescending(x => x.Item2)
                    .Select(x => x.Item1)
                    .Take(3)
                    .ToList();

                return new PageResult<ProductModel>
                {
                    Result = _mapper.Map<List<ProductModel>>(finalResults),
                    Count = finalResults.Count
                };
            }
            catch
            {
                throw new UserException("Sistem preporuke trenutno nije dostupan.");
            }
        }
    }
}
