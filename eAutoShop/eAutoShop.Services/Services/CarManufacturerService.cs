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
    public class CarManufacturerService: BaseCRUDService<CarManufacturerModel,CarManufacturer,CarManufacturerSearchObject,CarManufacturerInsertRequest,CarManufacturerUpdateRequest>,ICarManufacturerService
    {
        public CarManufacturerService(AutoShopContext context,IMapper mapper): base(context, mapper)
        {
        }

        public override IQueryable<CarManufacturer> AddFilter(IQueryable<CarManufacturer> query,CarManufacturerSearchObject? search = null)
        {
            if (!string.IsNullOrWhiteSpace(search?.Name))
            {
                var name = search.Name.Trim();

                query = query.Where(x => x.Name.Contains(name));
            }

            return query.OrderBy(x => x.Name);
        }

        public override async Task BeforeInsert(CarManufacturer db,CarManufacturerInsertRequest insert)
        {
            var name = insert.Name.Trim();

            var exists = await _context.CarManufacturers.AnyAsync( x => x.Name == name);

            if (exists)
            {
                throw new UserException("Proizvođač sa ovim nazivom već postoji.");
            }

            db.Name = name;

            await base.BeforeInsert(db, insert);
        }

        public override async Task BeforeUpdate(CarManufacturer db,CarManufacturerUpdateRequest update)
        {
            var name = update.Name.Trim();

            var exists = await _context.CarManufacturers.AnyAsync(x => x.Id != db.Id && x.Name == name);

            if (exists)
            {
                throw new UserException("Proizvođač sa ovim nazivom već postoji.");
            }

            db.Name = name;

            await base.BeforeUpdate(db, update);
        }

        public override async Task BeforeRemove(CarManufacturer db)
        {
            var isUsed = await _context.CarModels.AnyAsync(x => x.CarManufacturerId == db.Id);

            if (isUsed)
            {
                throw new UserException("Proizvođača nije moguće obrisati jer ima modele vozila.");
            }

            await base.BeforeRemove(db);
        }
    }
}