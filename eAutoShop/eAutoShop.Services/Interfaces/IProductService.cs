using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Interfaces
{
    public interface IProductService : IBaseCRUDService<ProductModel, ProductSearchObject, ProductInsertRequest, ProductUpdateRequest>
    {
        Task<ProductModel> Activate(int id);
        Task<ProductModel> Hide(int id);
        Task<List<string>> AllowedActions(int id);
    }
}
