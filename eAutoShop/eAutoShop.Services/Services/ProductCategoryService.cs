using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Database;
using eAutoShop.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace eAutoShop.Services.Services
{
    public class ProductCategoryService: BaseCRUDService<ProductCategoryModel,ProductCategory,ProductCategorySearchObject,ProductCategoryInsertRequest,ProductCategoryUpdateRequest>,IProductCategoryService
    {
        public ProductCategoryService(AutoShopContext context,IMapper mapper): base(context, mapper)
        {
        }

        public override IQueryable<ProductCategory> AddFilter(IQueryable<ProductCategory> query,ProductCategorySearchObject? search = null)
        {
            if (!string.IsNullOrWhiteSpace(search?.Name))
            {
                var name = search.Name.Trim();

                query = query.Where(x => x.Name.Contains(name));
            }

            return query.OrderBy(x => x.Name);
        }

        public override async Task BeforeInsert(ProductCategory db,ProductCategoryInsertRequest insert)
        {
            var name = insert.Name.Trim();

            var exists = await _context.ProductCategories.AnyAsync(x => x.Name == name);

            if (exists)
            {
                throw new UserException("Kategorija sa ovim nazivom već postoji.");
            }

            db.Name = name;

            await base.BeforeInsert(db, insert);
        }

        public override async Task BeforeUpdate(ProductCategory db,ProductCategoryUpdateRequest update)
        {
            var name = update.Name.Trim();

            var exists = await _context.ProductCategories.AnyAsync(x => x.Id != db.Id && x.Name == name);

            if (exists)
            {
                throw new UserException("Kategorija sa ovim nazivom već postoji.");
            }

            db.Name = name;

            await base.BeforeUpdate(db, update);
        }

        public override async Task BeforeRemove(ProductCategory db)
        {
            var isUsed = await _context.Products.AnyAsync(x => x.ProductCategoryId == db.Id);

            if (isUsed)
            {
                throw new UserException("Kategoriju nije moguće obrisati jer sadrži proizvode.");
            }

            await base.BeforeRemove(db);
        }
    }
}
