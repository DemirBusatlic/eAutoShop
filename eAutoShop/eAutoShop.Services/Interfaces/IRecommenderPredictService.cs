using eAutoShop.Model.Model;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Interfaces
{
    public interface IRecommenderPredictService
    {
        Task<PageResult<ProductModel>> RecommendProduct(int storeItemId);

    }
}
