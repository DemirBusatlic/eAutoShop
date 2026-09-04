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

namespace eAutoShop.Services.StateMachineService.ProductStateMachine
{
    public class BaseProductState
    {
        protected readonly AutoShopContext _context;

        protected readonly IMapper _mapper;

        protected readonly IServiceProvider _serviceProvider;

        public BaseProductState(AutoShopContext context, IMapper mapper, IServiceProvider serviceProvider)
        {
            _context = context;
            _mapper = mapper;
            _serviceProvider = serviceProvider;
        }

        public virtual Task<ProductModel> Insert(ProductInsertRequest request)
        {
            throw new UserException("Action not allowed.");
        }

        public virtual Task<ProductModel> Update(Product entity, ProductUpdateRequest request)
        {
            throw new UserException("Action not allowed.");
        }

        public virtual Task<ProductModel> Activate(Product entity)
        {
            throw new UserException("Action not allowed.");
        }

        public virtual Task<ProductModel> Hide(Product entity)
        {
            throw new UserException("Action not allowed.");
        }

        public virtual Task<bool> Delete(Product entity)
        {
            throw new UserException("Action not allowed.");
        }

        public virtual Task<List<string>> AllowedActions()
        {
            return Task.FromResult(new List<string>());
        }

        public BaseProductState CreateState(string? state)
        {
            var key = state?.Trim().ToLowerInvariant();

            return key switch
            {
                null or ProductStates.Initial => _serviceProvider.GetRequiredService<InitialProductState>(),

                ProductStates.Draft => _serviceProvider.GetRequiredService<DraftProductState>(),

                ProductStates.Active => _serviceProvider.GetRequiredService<ActiveProductState>(),
                _ => throw new UserException($"Unknown product state: '{state}'")
            };
        }
    }

}
