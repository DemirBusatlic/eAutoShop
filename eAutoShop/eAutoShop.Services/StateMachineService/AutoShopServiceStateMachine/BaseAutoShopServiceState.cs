using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using MapsterMapper;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.StateMachineService.AutoShopServiceStateMachine
{
    public class BaseAutoShopServiceState
    {
        protected readonly AutoShopContext _context;
        protected readonly IMapper _mapper;
        protected readonly IServiceProvider _serviceProvider;

        public BaseAutoShopServiceState(AutoShopContext context, IMapper mapper, IServiceProvider serviceProvider)
        {
            _context = context;
            _mapper = mapper;
            _serviceProvider = serviceProvider;
        }

        public virtual async Task<AutoShopServiceModel> Insert(AutoShopServiceInsertRequest request)
        {
            throw new UserException("Action not allowed.");
        }

        public virtual async Task<AutoShopServiceModel> Update(AutoShopService entity, AutoShopServiceUpdateRequest request)
        {
            throw new UserException("Action not allowed.");
        }

        public virtual async Task<AutoShopServiceModel> Activate(AutoShopService entity)
        {
            throw new UserException("Action not allowed.");
        }

        public virtual async Task<AutoShopServiceModel> Hide(AutoShopService entity)
        {
            throw new UserException("Action not allowed.");
        }

        public virtual async Task<bool> Delete(AutoShopService entity)
        {
            throw new UserException("Action not allowed.");
        }

        public virtual async Task<List<string>> AllowedActions()
        {
            return new List<string>();
        }

        public BaseAutoShopServiceState CreateState(string? state)
        {
            switch (state)
            {
                case AutoShopServiceStates.Initial:
                case null:
                    return _serviceProvider.GetService<InitialAutoShopServiceState>()!;

                case AutoShopServiceStates.Draft:
                    return _serviceProvider.GetService<DraftAutoShopServiceState>()!;

                case AutoShopServiceStates.Active:
                    return _serviceProvider.GetService<ActiveAutoShopServiceState>()!;

                case AutoShopServiceStates.Hidden:
                    return _serviceProvider.GetService<HiddenAutoShopServiceState>()!;

                default:
                    throw new UserException("Action not allowed.");
            }
        }
    }
}
