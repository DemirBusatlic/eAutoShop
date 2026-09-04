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
    public class HiddenAutoShopServiceState : BaseAutoShopServiceState
    {
        public HiddenAutoShopServiceState(AutoShopContext context, IMapper mapper, IServiceProvider serviceProvider) : base(context, mapper, serviceProvider)
        {
        }

        public override async Task<AutoShopServiceModel> Update(AutoShopService entity, AutoShopServiceUpdateRequest request)
        {
            if (request.ImageData != null)
            {
                entity.Image = !string.IsNullOrWhiteSpace(request.ImageData) ? Convert.FromBase64String(request.ImageData) : Array.Empty<byte>();
            }

            _mapper.Map(request, entity);

            var discount = request.Discount ?? entity.Discount;

            if (discount < 0 || discount > 1)
            {
                throw new UserException("Discount must be between 0 and 1.");
            }

            entity.Discount = discount;

            entity.DiscountedPrice = discount > 0 ? Math.Round(entity.Price * (1 - discount), 2) : entity.Price;

            await _context.SaveChangesAsync();

            return _mapper.Map<AutoShopServiceModel>(entity);
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
