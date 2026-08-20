using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.StateMachineService.ProductStateMachine
{
    public class InitialProductState : BaseProductState
    {
        public InitialProductState(AutoShopContext context,IMapper mapper,IServiceProvider serviceProvider): base(context, mapper, serviceProvider)
        {
        }

        public override async Task<ProductModel> Insert(ProductInsertRequest request)
        {
            var entity = _mapper.Map<Product>(request);

            entity.State = ProductStates.Draft;
            var discount = request.Discount ?? 0;

            if (discount < 0 || discount > 1)
            {
                throw new UserException("Discount must be between 0 and 1."
                );
            }

            entity.Discount = discount;

            entity.DiscountedPrice = discount > 0? Math.Round(entity.Price * (1 - discount), 2): entity.Price;

            entity.CarModels = new List<CarModel>();

            _context.Products.Add(entity);

            if (request.CarModelIds != null && request.CarModelIds.Any())
            {
                await SetProductCarModels( entity, request.CarModelIds);
            }

            await _context.SaveChangesAsync();

            return _mapper.Map<ProductModel>(entity);
        }

        internal async Task SetProductCarModels(Product product,List<int> carModelIds)
        {
            carModelIds ??= new List<int>();

            var ids = carModelIds.Distinct().ToList();

            var models = await _context.CarModels.Where(x => ids.Contains(x.Id)).ToListAsync();

            if (models.Count != ids.Count)
            {
                throw new UserException("One or more car models do not exist.");
            }

            product.CarModels.Clear();

            foreach (var model in models)
            {
                product.CarModels.Add(model);
            }
        }

        public override async Task<List<string>> AllowedActions()
        {
            var list = await base.AllowedActions();

            list.Add(nameof(Insert));

            return list;
        }
    }
}
