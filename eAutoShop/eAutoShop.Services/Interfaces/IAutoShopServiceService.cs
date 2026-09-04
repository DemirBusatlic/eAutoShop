using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Database;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Interfaces
{
    public interface IAutoShopServiceService : IBaseCRUDService<AutoShopServiceModel, AutoShopServiceSearchObject, AutoShopServiceInsertRequest, AutoShopServiceUpdateRequest>
    {
        Task<AutoShopServiceModel> Activate(int id);
        Task<AutoShopServiceModel> Hide(int id);
        Task<List<string>> AllowedActions(int id);
    }
}
