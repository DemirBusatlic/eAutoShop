using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Database;
using eAutoShop.Services.Interfaces;
using eAutoShop.Services.Helpers;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace eAutoShop.Services.Services
{
    public class ServiceTypeService
        : BaseCRUDService<
            ServiceTypeModel,
            ServiceType,
            ServiceTypeSearchObject,
            ServiceTypeInsertRequest,
            ServiceTypeUpdateRequest>,
          IServiceTypeService
    {
        public ServiceTypeService(
            AutoShopContext context,
            IMapper mapper)
            : base(context, mapper)
        {
        }

        public override IQueryable<ServiceType> AddFilter(
            IQueryable<ServiceType> query,
            ServiceTypeSearchObject? search = null)
        {
            if (!string.IsNullOrWhiteSpace(search?.Name))
            {
                var name = search.Name.Trim();

                query = query.Where(x => x.Name.Contains(name));
            }

            return query.OrderBy(x => x.Name);
        }

        public override async Task BeforeInsert(
            ServiceType db,
            ServiceTypeInsertRequest insert)
        {
            var name = insert.Name.Trim();

            var exists = await _context.ServiceTypes.AnyAsync(
                x => x.Name == name);

            if (exists)
            {
                throw new UserException(
                    "Tip usluge sa ovim nazivom već postoji.");
            }

            db.Name = name;
            db.Image = ImageValidator.Parse(insert.Image);

            await base.BeforeInsert(db, insert);
        }

        public override async Task BeforeUpdate(
            ServiceType db,
            ServiceTypeUpdateRequest update)
        {
            var name = update.Name.Trim();

            var exists = await _context.ServiceTypes.AnyAsync(
                x => x.Id != db.Id && x.Name == name);

            if (exists)
            {
                throw new UserException(
                    "Tip usluge sa ovim nazivom već postoji.");
            }

            db.Name = name;

            if (!string.IsNullOrWhiteSpace(update.Image))
            {
                db.Image = ImageValidator.Parse(update.Image);
            }

            await base.BeforeUpdate(db, update);
        }

        public override async Task BeforeRemove(ServiceType db)
        {
            var isUsed = await _context.AutoShopServices.AnyAsync(
                x => x.ServiceTypeId == db.Id);

            if (isUsed)
            {
                throw new UserException(
                    "Tip usluge nije moguće obrisati jer se koristi u uslugama.");
            }

            await base.BeforeRemove(db);
        }

    }
}
