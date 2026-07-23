using eAutoShop.Model.Model;
using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.StateMachineService.AutoShopServiceStateMachine
{
    public class HiddenAutoShopServiceState : BaseAutoShopServiceState
    {
        public HiddenAutoShopServiceState(AutoShopContext context,IMapper mapper,IServiceProvider serviceProvider): base(context, mapper, serviceProvider)
        {
        }

        public override async Task<AutoShopServiceModel> Activate(AutoShopService entity)
        {
            entity.State = AutoShopServiceStates.Active;

            await _context.SaveChangesAsync();

            return _mapper.Map<AutoShopServiceModel>(entity);
        }

        public override async Task<List<string>> AllowedActions()
        {
            var list = await base.AllowedActions();

            list.Add(nameof(Activate));

            return list;
        }
    }
}
