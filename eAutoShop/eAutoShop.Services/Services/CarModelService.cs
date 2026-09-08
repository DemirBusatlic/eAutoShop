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
    public class CarModelService: BaseCRUDService<CarModelModel,CarModel,CarModelSearchObject,CarModelInsertRequest,CarModelUpdateRequest>,ICarModelService
    {
        public CarModelService(AutoShopContext context,IMapper mapper): base(context, mapper)
        {
        }

        public override IQueryable<CarModel> AddInclude(IQueryable<CarModel> query, CarModelSearchObject? search = null)
        {
            return query.Include(x => x.CarManufacturer);
        }

        public override IQueryable<CarModel> AddFilter(IQueryable<CarModel> query,CarModelSearchObject? search = null)
        {
            if (!string.IsNullOrWhiteSpace(search?.Name))
            {
                var name = search.Name.Trim();

                query = query.Where(x => x.Name.Contains(name));
            }

            if (search?.CarManufacturerId != null)
            {
                query = query.Where(
                    x => x.CarManufacturerId ==
                         search.CarManufacturerId);
            }

            return query
                .OrderBy(x => x.CarManufacturer.Name)
                .ThenBy(x => x.Name)
                .ThenBy(x => x.ModelYear);
        }

        public override async Task BeforeInsert(CarModel db, CarModelInsertRequest insert)
        {
            await ValidateManufacturer(insert.CarManufacturerId);

            var name = insert.Name.Trim();
            var modelYear = insert.ModelYear.Trim();

            var exists = await _context.CarModels.AnyAsync(
                x => x.Name == name &&
                     x.ModelYear == modelYear &&
                     x.CarManufacturerId ==
                     insert.CarManufacturerId);

            if (exists)
            {
                throw new UserException(
                    "Ovaj model vozila već postoji.");
            }

            db.Name = name;
            db.ModelYear = modelYear;

            await base.BeforeInsert(db, insert);
        }

        public override async Task BeforeUpdate(CarModel db, CarModelUpdateRequest update)
        {
            await ValidateManufacturer(update.CarManufacturerId);

            var name = update.Name.Trim();
            var modelYear = update.ModelYear.Trim();

            var exists = await _context.CarModels.AnyAsync(
                x => x.Id != db.Id &&
                     x.Name == name &&
                     x.ModelYear == modelYear &&
                     x.CarManufacturerId ==
                     update.CarManufacturerId);

            if (exists)
            {
                throw new UserException(
                    "Ovaj model vozila već postoji.");
            }

            db.Name = name;
            db.ModelYear = modelYear;

            await base.BeforeUpdate(db, update);
        }

        public override async Task BeforeRemove(CarModel db)
        {
            var hasAppointments = await _context.Appointments.AnyAsync(
                x => x.CarModelId == db.Id);

            var hasProducts = await _context.Products.AnyAsync(
                x => x.CarModels.Any(model => model.Id == db.Id));

            if (hasAppointments || hasProducts)
            {
                throw new UserException(
                    "Model nije moguće obrisati jer se koristi u sistemu.");
            }

            await base.BeforeRemove(db);
        }

        private async Task ValidateManufacturer(int manufacturerId)
        {
            var exists = await _context.CarManufacturers.AnyAsync(
                x => x.Id == manufacturerId);

            if (!exists)
            {
                throw new UserException(
                    "Odabrani proizvođač ne postoji.");
            }
        }

        public async Task<PageResult<CarModelGetByManufacturerModel>>GetByManufacturerAll()
        {
            var manufacturers = await _context.CarManufacturers
                .Include(x => x.CarModels)
                .OrderBy(x => x.Name)
                .ToListAsync();

            var result = manufacturers.Select(manufacturer =>
                new CarModelGetByManufacturerModel
                {
                    Manufacturer =
                        _mapper.Map<CarManufacturerModel>(manufacturer),

                    Models = _mapper.Map<List<CarModelModel>>(
                        manufacturer.CarModels
                            .OrderBy(x => x.Name)
                            .ThenBy(x => x.ModelYear)
                            .ToList())
                }).ToList();

            return new PageResult<CarModelGetByManufacturerModel>
            {
                Result = result,
                Count = result.Count
            };
        }
    }
}
