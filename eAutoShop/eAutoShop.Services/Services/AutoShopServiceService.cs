using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using eAutoShop.Services.Interfaces;
using eAutoShop.Services.StateMachineService.AutoShopServiceStateMachine;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Services
{
    public class AutoShopServiceService: BaseCRUDService<AutoShopServiceModel, AutoShopService, AutoShopServiceSearchObject, AutoShopServiceInsertRequest, AutoShopServiceUpdateRequest>, IAutoShopServiceService
    {
        private readonly BaseAutoShopServiceState _baseAutoShopServiceState;

        public AutoShopServiceService(AutoShopContext context,IMapper mapper,BaseAutoShopServiceState baseAutoShopServiceState) : base(context, mapper)
        {
            _baseAutoShopServiceState = baseAutoShopServiceState;
        }

        public override IQueryable<AutoShopService> AddInclude(IQueryable<AutoShopService> query,AutoShopServiceSearchObject? search = null)
        {
            query = query.Include(x => x.ServiceType);

            return base.AddInclude(query, search);
        }

        public override IQueryable<AutoShopService> AddFilter(IQueryable<AutoShopService> query,AutoShopServiceSearchObject? search = null)
        {
            if (search != null)
            {
                if (search.ServiceTypeId.HasValue)
                {
                    query = query.Where(x => x.ServiceTypeId == search.ServiceTypeId.Value);
                }

                if (!string.IsNullOrWhiteSpace(search.ServiceType))
                {
                    query = query.Where(x => x.ServiceType.Name.Contains(search.ServiceType));
                }

                if (!string.IsNullOrWhiteSpace(search.Name))
                {
                    query = query.Where(x => x.Name.Contains(search.Name));
                }

                if (!string.IsNullOrWhiteSpace(search.State))
                {
                    query = query.Where(x => x.State == search.State);
                }

                if (search.WithDiscount.HasValue)
                {
                    query = search.WithDiscount.Value ? query.Where(x => x.Discount > 0) : query.Where(x => x.Discount == 0);
                }
            }

            query = query.OrderBy(x => x.Name);

            return base.AddFilter(query, search);
        }

        public override async Task<AutoShopServiceModel> Insert(AutoShopServiceInsertRequest request)
        {
            if (request.ServiceTypeId <= 0 ||string.IsNullOrWhiteSpace(request.Name) ||request.Price <= 0 || string.IsNullOrWhiteSpace(request.Duration))
            {
                throw new UserException("Please insert all required service properties.");
            }

            var state = _baseAutoShopServiceState.CreateState(AutoShopServiceStates.Initial);

            return await state.Insert(request);
        }

        public override async Task<AutoShopServiceModel> Update(int id, AutoShopServiceUpdateRequest request)
        {
            var entity = await _context.AutoShopServices.FindAsync(id);

            if (entity == null)
            {
                throw new UserException($"Auto shop service ({id}) doesn't exist.");
            }

            var state = _baseAutoShopServiceState.CreateState(entity.State);

            return await state.Update(entity, request);
        }

        public override async Task<bool> Delete(int id)
        {
            var entity = await _context.AutoShopServices.FindAsync(id);

            if (entity == null)
            {
                throw new UserException($"Auto shop service ({id}) doesn't exist.");
            }

            var state = _baseAutoShopServiceState.CreateState(entity.State);

            await state.Delete(entity);

            return true;
        }

        public async Task<AutoShopServiceModel> Activate(int id)
        {
            var entity = await _context.AutoShopServices.Include(x => x.ServiceType).FirstOrDefaultAsync(x => x.Id == id);

            if (entity == null)
            {
                throw new UserException($"Auto shop service ({id}) doesn't exist.");
            }

            var state = _baseAutoShopServiceState.CreateState(entity.State);

            return await state.Activate(entity);
        }

        public async Task<AutoShopServiceModel> Hide(int id)
        {
            var entity = await _context.AutoShopServices.FindAsync(id);

            if (entity == null)
            {
                throw new UserException($"Auto shop service ({id}) doesn't exist.");
            }

            var state = _baseAutoShopServiceState.CreateState(entity.State);

            return await state.Hide(entity);
        }

        public async Task<List<string>> AllowedActions(int id)
        {
            var entity = await _context.AutoShopServices.FindAsync(id);

            var state = _baseAutoShopServiceState.CreateState(entity?.State ?? AutoShopServiceStates.Initial);

            return await state.AllowedActions();
        }
    }
}
