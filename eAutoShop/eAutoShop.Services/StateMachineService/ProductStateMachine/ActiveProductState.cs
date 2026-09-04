using eAutoShop.Model.Model;
using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.StateMachineService.ProductStateMachine
{
    public class ActiveProductState : BaseProductState
    {
        public ActiveProductState(AutoShopContext context, IMapper mapper, IServiceProvider serviceProvider) : base(context, mapper, serviceProvider)
        {
        }

        public override async Task<ProductModel> Hide(Product entity)
        {
            entity.State = ProductStates.Draft;

            await _context.SaveChangesAsync();

            return _mapper.Map<ProductModel>(entity);
        }

        public override async Task<List<string>> AllowedActions()
        {
            var list = await base.AllowedActions();

            list.Add(nameof(Hide));

            return list;
        }
    }
}
