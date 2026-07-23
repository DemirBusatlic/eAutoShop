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
        public DraftProductState(AutoShopContext context,IMapper mapper,IServiceProvider serviceProvider): base(context, mapper, serviceProvider)
        {
        }

        public override async Task<ProductModel> Update(Product entity,ProductUpdateRequest request)
        {
            if (request.Name != null)
            {
                entity.Name = request.Name;
            }

            if (request.Price.HasValue)
            {
                entity.Price = request.Price.Value;
            }

            if (request.ProductCategoryId.HasValue)
            {
                entity.ProductCategoryId = request.ProductCategoryId.Value;
            }

            if (request.Description != null)
            {
                entity.Description = request.Description;
            }

            if (!string.IsNullOrWhiteSpace(request.ImageData))
            {
                entity.Image = ParseBase64(request.ImageData);
            }

            if (request.CarModelIds != null)
            {
                await _context.Entry(entity)
                    .Collection(p => p.CarModels)
                    .LoadAsync();

                var ids = request.CarModelIds
                    .Distinct()
                    .ToList();

                var models = await _context.CarModels
                    .Where(x => ids.Contains(x.Id))
                    .ToListAsync();

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

            var discount = request.Discount?? entity.Discount;

            if (discount < 0 || discount > 100)
            {
                throw new UserException("Discount must be between 0 and 100.");
            }

            entity.Discount = discount;

            entity.DiscountedPrice = discount > 0 ? Math.Round(entity.Price * (1 - (discount / 100.0)),2)
             : entity.Price;

            await _context.SaveChangesAsync();

            return _mapper.Map<ProductModel>(entity);
        }

        private static byte[] ParseBase64(string base64)
        {
            try
            {
                var commaIndex = base64.IndexOf(',');

                if (commaIndex >= 0)
                {
                    base64 = base64[(commaIndex + 1)..];
                }

                return Convert.FromBase64String(base64);
            }
            catch
            {
                throw new UserException(
                    "Invalid image format.");
            }
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
