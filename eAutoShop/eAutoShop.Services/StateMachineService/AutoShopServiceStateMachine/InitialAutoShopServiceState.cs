using eAutoShop.Model.Exceptions;
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

            var discount = request.Discount ?? 0;

            if (discount < 0 || discount > 1)
            {
                throw new UserException("Discount must be between 0 and 1.");
            }

            entity.Discount = discount;

            entity.DiscountedPrice = discount > 0? Math.Round(entity.Price * (1 - discount), 2) : entity.Price;

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
