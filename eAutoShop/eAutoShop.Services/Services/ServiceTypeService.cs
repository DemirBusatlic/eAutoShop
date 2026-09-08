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
    public class ServiceTypeService
        : BaseCRUDService<
            ServiceTypeModel,
            ServiceType,
            ServiceTypeSearchObject,
            ServiceTypeInsertRequest,
            ServiceTypeUpdateRequest>,
          IServiceTypeService
    {
        private const int MaximumImageSize = 5 * 1024 * 1024;

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
            db.Image = ParseImage(insert.Image);

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
                db.Image = ParseImage(update.Image);
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

        private static byte[] ParseImage(string image)
        {
            try
            {
                var commaIndex = image.IndexOf(',');

                if (commaIndex >= 0)
                {
                    image = image[(commaIndex + 1)..];
                }

                var bytes = Convert.FromBase64String(image);

                if (bytes.Length == 0 || bytes.Length > MaximumImageSize)
                {
                    throw new UserException(
                        "Slika mora biti manja od 5 MB.");
                }

                var isPng =
                    bytes.Length >= 8 &&
                    bytes[0] == 0x89 &&
                    bytes[1] == 0x50 &&
                    bytes[2] == 0x4E &&
                    bytes[3] == 0x47 &&
                    bytes[4] == 0x0D &&
                    bytes[5] == 0x0A &&
                    bytes[6] == 0x1A &&
                    bytes[7] == 0x0A;

                var isJpeg =
                    bytes.Length >= 3 &&
                    bytes[0] == 0xFF &&
                    bytes[1] == 0xD8 &&
                    bytes[2] == 0xFF;

                if (!isPng && !isJpeg)
                {
                    throw new UserException(
                        "Dozvoljene su samo PNG i JPEG slike.");
                }

                return bytes;
            }
            catch (UserException)
            {
                throw;
            }
            catch
            {
                throw new UserException(
                    "Slika nije u ispravnom Base64 formatu.");
            }
        }
    }
}
