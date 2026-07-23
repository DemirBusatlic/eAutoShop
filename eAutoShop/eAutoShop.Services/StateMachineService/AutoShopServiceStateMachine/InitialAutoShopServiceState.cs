using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
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
    public class InitialAutoShopServiceState : BaseAutoShopServiceState
    {
        public InitialAutoShopServiceState(AutoShopContext context,IMapper mapper,IServiceProvider serviceProvider): base(context, mapper, serviceProvider)
        {
        }

        public override async Task<AutoShopServiceModel> Insert(AutoShopServiceInsertRequest request)
        {
            var entity = _mapper.Map<AutoShopService>(request);

            entity.State = AutoShopServiceStates.Draft;

            entity.Discount = request.Discount ?? 0;
            entity.DiscountedPrice = entity.Price - (entity.Price * entity.Discount / 100);

            entity.Image = !string.IsNullOrWhiteSpace(request.ImageData)? Convert.FromBase64String(request.ImageData): Array.Empty<byte>();

            _context.AutoShopServices.Add(entity);

            await _context.SaveChangesAsync();

            return _mapper.Map<AutoShopServiceModel>(entity);
        }

        public override async Task<List<string>> AllowedActions()
        {
            var list = await base.AllowedActions();

            list.Add(nameof(Insert));

            return list;
        }
    }
}
