using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Metadata.Internal;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;


namespace eAutoShop.Services.StateMachineService.ProductStateMachine
{
    public class DraftProductState : BaseProductState
    {
        public DraftProductState(AutoShopContext context, IMapper mapper, IServiceProvider serviceProvider) : base(context, mapper, serviceProvider)
        {
        }

        public override async Task<ProductModel> Update(Product entity, ProductUpdateRequest request)
        {
            if (request.Name != null)
            {
                if (string.IsNullOrWhiteSpace(request.Name))
                    throw new UserException("Product name is required.");
                entity.Name = request.Name.Trim();
            }

            if (request.Price.HasValue)
            {
                if (request.Price.Value <= 0)
                    throw new UserException("Product price must be greater than zero.");
                entity.Price = request.Price.Value;
            }

            if (request.ProductCategoryId.HasValue)
            {
                var categoryExists = await _context.ProductCategories.AnyAsync(x => x.Id == request.ProductCategoryId.Value);
                if (!categoryExists)
                    throw new UserException("Selected product category doesn't exist.");
                entity.ProductCategoryId = request.ProductCategoryId.Value;
            }

            if (request.Description != null)
            {
                entity.Description = string.IsNullOrWhiteSpace(request.Description)? null: request.Description.Trim();
            }

            if (!string.IsNullOrWhiteSpace(request.ImageData))
            {
                entity.Image = ImageValidator.Parse(request.ImageData);
            }

            if (request.CarModelIds != null)
            {
                await _context.Entry(entity).Collection(p => p.CarModels).LoadAsync();

                var ids = request.CarModelIds.Distinct().ToList();

                var models = await _context.CarModels.Where(x => ids.Contains(x.Id)).ToListAsync();

                if (models.Count != ids.Count)
                {
                    throw new UserException("One or more car models do not exist.");
                }

                entity.CarModels.Clear();

                foreach (var model in models)
                {
                    entity.CarModels.Add(model);
                }
            }

            var discount = request.Discount ?? entity.Discount;

            if (discount < 0 || discount > 1)
            {
                throw new UserException("Discount must be between 0 and 1.");
            }

            entity.Discount = discount;

            entity.DiscountedPrice = discount > 0 ? Math.Round(entity.Price * (1 - discount), 2) : entity.Price;

            await _context.SaveChangesAsync();

            return _mapper.Map<ProductModel>(entity);
        }

        public override async Task<ProductModel> Activate(Product entity)
        {
            var isValid =
                !string.IsNullOrWhiteSpace(entity.Description) &&
                entity.CarModels != null &&
                entity.CarModels.Any() &&
                entity.ProductCategoryId > 0;

            if (!isValid)
            {
                throw new UserException("Please insert all item details before activating the product.");
            }

            entity.State = ProductStates.Active;

            await _context.SaveChangesAsync();

            return _mapper.Map<ProductModel>(entity);
        }

        public override async Task<bool> Delete(Product entity)
        {
            var isUsedInOrders = await _context.OrderItems.AnyAsync(x => x.ProductId == entity.Id);

            var hasReviews = await _context.ProductReviews.AnyAsync(x => x.ProductId == entity.Id);

            if (isUsedInOrders || hasReviews)
            {
                throw new UserException("Proizvod se ne može obrisati jer je korišten u narudžbama ili recenzijama. Možete ga ostaviti skrivenim.");
            }

            await _context.Entry(entity).Collection(x => x.CarModels).LoadAsync();

            entity.CarModels.Clear();

            _context.Products.Remove(entity);

            await _context.SaveChangesAsync();

            return true;
        }

        public override async Task<List<string>> AllowedActions()
        {
            var list = await base.AllowedActions();

            list.Add(nameof(Update));
            list.Add(nameof(Activate));
            list.Add(nameof(Delete));

            return list;
        }
    }
}
