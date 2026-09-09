using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.Request;
using eAutoShop.Services.Database;
using eAutoShop.Services.Helpers;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.StateMachineService.AutoShopServiceStateMachine
{
    public class HiddenAutoShopServiceState : BaseAutoShopServiceState
    {
        public HiddenAutoShopServiceState(AutoShopContext context, IMapper mapper, IServiceProvider serviceProvider) : base(context, mapper, serviceProvider)
        {
        }

        public override async Task<AutoShopServiceModel> Update(AutoShopService entity, AutoShopServiceUpdateRequest request)
        {
            if (request.Name != null && string.IsNullOrWhiteSpace(request.Name))
                throw new UserException("Service name is required.");

            if (request.Price.HasValue && request.Price.Value <= 0)
                throw new UserException("Service price must be greater than zero.");

            if (request.ServiceTypeId.HasValue &&
                !await _context.ServiceTypes.AnyAsync(x => x.Id == request.ServiceTypeId.Value))
                throw new UserException("Selected service type doesn't exist.");

            TimeOnly? duration = null;
            if (request.Duration != null)
            {
                if (!TimeOnly.TryParse(request.Duration, out var parsedDuration) || parsedDuration == TimeOnly.MinValue)
                    throw new UserException("Service duration is invalid.");
                duration = parsedDuration;
            }

            if (request.ImageData != null)
            {
                entity.Image = !string.IsNullOrWhiteSpace(request.ImageData)
                    ? ImageValidator.Parse(request.ImageData)
                    : Array.Empty<byte>();
            }

            _mapper.Map(request, entity);
            if (request.Name != null) entity.Name = request.Name.Trim();
            if (request.Description != null) entity.Description = request.Description.Trim();
            if (request.Details != null) entity.Details = string.IsNullOrWhiteSpace(request.Details) ? null : request.Details.Trim();
            if (duration.HasValue) entity.Duration = duration.Value;

            var discount = request.Discount ?? entity.Discount;

            if (discount < 0 || discount > 1)
            {
                throw new UserException("Discount must be between 0 and 1.");
            }

            entity.Discount = discount;

            entity.DiscountedPrice = discount > 0 ? Math.Round(entity.Price * (1 - discount), 2) : entity.Price;

            await _context.SaveChangesAsync();

            return _mapper.Map<AutoShopServiceModel>(entity);
        }
        public override async Task<AutoShopServiceModel> Activate(AutoShopService entity)
        {
            entity.State = AutoShopServiceStates.Active;

            await _context.SaveChangesAsync();

            return _mapper.Map<AutoShopServiceModel>(entity);
        }

        public override async Task<List<string>> AllowedActions()
        {
            var list = await base.AllowedActions();

            list.Add(nameof(Activate));

            return list;
        }
    }
}
