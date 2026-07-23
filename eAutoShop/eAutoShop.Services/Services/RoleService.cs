using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Database;
using eAutoShop.Services.Interfaces;
using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Services
{
    public class RoleService : BaseCRUDService<RoleModel,Role,RoleSearchObject,RoleInsertRequest,RoleUpdateRequest>, IRoleService
    {
        public RoleService(AutoShopContext context, IMapper mapper) : base(context, mapper){ }
    }
}
