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
    public class CityService: BaseCRUDService<CityModel,City,CitySearchObject,CityInsertRequest,CityUpdateRequest>,ICityService
    {
        public CityService(AutoShopContext context, IMapper mapper): base(context, mapper)
        {
        }

        public override IQueryable<City> AddFilter(IQueryable<City> query,CitySearchObject? search = null)
        {
            if (!string.IsNullOrWhiteSpace(search?.Name))
            {
                var name = search.Name.Trim();

                query = query.Where(x => x.Name.Contains(name));
            }

            return query.OrderBy(x => x.Name);
        }

        public override async Task BeforeInsert(City db, CityInsertRequest insert)
        {
            var name = insert.Name.Trim();

            if (string.IsNullOrWhiteSpace(name))
            {
                throw new UserException("Naziv grada je obavezan.");
            }

            var exists = await _context.Cities.AnyAsync(x => x.Name == name);

            if (exists)
            {
                throw new UserException( "Grad sa ovim nazivom već postoji.");
            }

            db.Name = name;

            await base.BeforeInsert(db, insert);
        }

        public override async Task BeforeUpdate(City db, CityUpdateRequest update)
        {
            var name = update.Name.Trim();

            if (string.IsNullOrWhiteSpace(name))
            {
                throw new UserException("Naziv grada je obavezan.");
            }

            var exists = await _context.Cities.AnyAsync(x => x.Id != db.Id && x.Name == name);

            if (exists)
            {
                throw new UserException("Grad sa ovim nazivom već postoji.");
            }

            db.Name = name;

            await base.BeforeUpdate(db, update);
        }

        public override async Task BeforeRemove(City db)
        {
            var isUsedByUsers = await _context.Users.AnyAsync(x => x.CityId == db.Id);

            var isUsedByOrders = await _context.Orders.AnyAsync(x => x.CityId == db.Id);

            if (isUsedByUsers || isUsedByOrders)
            {
                throw new UserException("Grad nije moguće obrisati jer se koristi u sistemu.");
            }

            await base.BeforeRemove(db);
        }
    }
}
