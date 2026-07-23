using eAutoShop.Model.SearchObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Interfaces
{
    public interface IBaseCRUDService<T, TSearch, TInsert, TUpdate>: IService<T, TSearch>where T : class where TSearch : BaseSearchObject, new()where TInsert : class where TUpdate : class
    {
        Task<T> Insert(TInsert insert);

        Task<T> Update(int id, TUpdate update);

        Task<bool> Delete(int id);
    }
}
