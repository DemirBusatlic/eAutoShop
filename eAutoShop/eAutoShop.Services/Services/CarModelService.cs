using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Model.Utilities;
using eAutoShop.Services.Database;
using eAutoShop.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;


namespace eAutoShop.Services.Services
{
    public class CarModelService : BaseService<CarModelModel, CarModel, CarModelSearchObject>, ICarModelService
    {
        public CarModelService(AutoShopContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public async Task<PageResult<CarModelGetByManufacturerModel>> GetByManufacturerAll()
        {
            var manufacturers = await _context.CarManufacturers
                .Include(x => x.CarModels)
                .OrderBy(x => x.Name)
                .ToListAsync();

            var result = manufacturers.Select(manufacturer => new CarModelGetByManufacturerModel
            {
                Manufacturer = _mapper.Map<CarManufacturerModel>(manufacturer),

                Models = _mapper.Map<List<CarModelModel>>(
                        manufacturer.CarModels
                            .OrderBy(x => x.Name)
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
