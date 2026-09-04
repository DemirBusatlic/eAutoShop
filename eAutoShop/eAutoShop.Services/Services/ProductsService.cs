using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using eAutoShop.Services.Interfaces;
using eAutoShop.Services.StateMachineService.ProductStateMachine;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Services
{
    public class ProductsService : BaseCRUDService<ProductModel, Product, ProductSearchObject, ProductInsertRequest, ProductUpdateRequest>, IProductService
    {
        private readonly BaseProductState _baseProductState;

        public ProductsService(AutoShopContext context, IMapper mapper, BaseProductState baseProductState)
            : base(context, mapper)
        {
            _baseProductState = baseProductState;
        }

        public override IQueryable<Product> AddInclude(IQueryable<Product> query, ProductSearchObject? search = null)
        {
            query = query
                .Include(x => x.ProductCategory)
                .Include(x => x.CarModels);

            return query;
        }

        public override IQueryable<Product> AddFilter(IQueryable<Product> query, ProductSearchObject? search = null)
        {
            if (!string.IsNullOrWhiteSpace(search?.Starts))
            {
                query = query.Where(x =>
                    x.Name != null &&
                    x.Name.StartsWith(search.Starts));
            }

            if (!string.IsNullOrWhiteSpace(search?.Contains))
            {
                query = query.Where(x =>
                    x.Name != null &&
                    x.Name.Contains(search.Contains));
            }

            if (!string.IsNullOrWhiteSpace(search?.State))
            {
                var state = search.State
                    .Trim()
                    .ToLowerInvariant();

                query = query.Where(x => x.State == state);
            }

            if (search?.WithDiscount.HasValue == true)
            {
                query = search.WithDiscount.Value
                    ? query.Where(x => x.Discount > 0)
                    : query.Where(x => x.Discount == 0);
            }

            if (search?.ProductCategoryId.HasValue == true &&
                search.ProductCategoryId.Value > 0)
            {
                query = query.Where(x =>
                    x.ProductCategoryId == search.ProductCategoryId.Value);
            }

            if (search?.CarModelIds != null &&
                search.CarModelIds.Count > 0)
            {
                var ids = search.CarModelIds
                    .Distinct()
                    .ToList();

                query = query.Where(x =>
                    x.CarModels.Any(cm => ids.Contains(cm.Id)));
            }
            else if (search?.CarManufacturerId.HasValue == true &&
                     search.CarManufacturerId.Value > 0)
            {
                query = query.Where(x =>
                    x.CarModels.Any(cm =>
                        cm.CarManufacturerId == search.CarManufacturerId.Value));
            }

            query = query.OrderBy(x => x.Name);

            return query;
        }

        public override async Task<ProductModel> Insert(ProductInsertRequest request)
        {
            var state = _baseProductState.CreateState(ProductStates.Initial);

            return await state.Insert(request);
        }

        public override async Task<ProductModel> Update(int id, ProductUpdateRequest request)
        {
            var entity = await _context.Products
                .Include(x => x.CarModels)
                .Include(x => x.ProductCategory)
                .FirstOrDefaultAsync(x => x.Id == id);

            if (entity == null)
            {
                throw new UserException("Entity doesn't exist.");
            }

            var state = _baseProductState.CreateState(entity.State);

            return await state.Update(entity, request);
        }

        public override async Task<bool> Delete(int id)
        {
            var entity = await _context.Products.FirstOrDefaultAsync(x => x.Id == id);

            if (entity == null)
            {
                throw new UserException("Entity doesn't exist.");
            }

            var state = _baseProductState.CreateState(entity.State);

            return await state.Delete(entity);
        }

        public async Task<ProductModel> Activate(int id)
        {
            var entity = await _context.Products
                .Include(x => x.CarModels)
                .Include(x => x.ProductCategory)
                .FirstOrDefaultAsync(x => x.Id == id);

            if (entity == null)
            {
                throw new UserException($"Entity ({id}) doesn't exist!");
            }

            var state = _baseProductState.CreateState(entity.State);

            return await state.Activate(entity);
        }

        public async Task<ProductModel> Hide(int id)
        {
            var entity = await _context.Products.FirstOrDefaultAsync(x => x.Id == id);

            if (entity == null)
            {
                throw new UserException("Entity doesn't exist.");
            }

            var state = _baseProductState.CreateState(entity.State);

            return await state.Hide(entity);
        }

        public async Task<List<string>> AllowedActions(int id)
        {
            var entity = await _context.Products
                .FirstOrDefaultAsync(x => x.Id == id);

            var state = _baseProductState.CreateState(entity?.State ?? ProductStates.Initial);

            return await state.AllowedActions();
        }
    }
}
