using eAutoShop.Model.Model;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Dynamic.Core;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Interfaces
{
        public interface IService<T, TSearch> where TSearch : class
        {
            Task<PageResult<T>> Get(TSearch? search = null);
            Task<T> GetById(int id);
        }
    
}
