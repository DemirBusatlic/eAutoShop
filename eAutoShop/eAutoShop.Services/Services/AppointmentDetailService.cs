using eAutoShop.Model.Model;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Database;
using eAutoShop.Services.Interfaces;
using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Services
{
    public class AppointmentDetailService : BaseService<AppointmentDetailModel, AppointmentDetail, AppointmentDetailSearchObject>, IAppointmentDetailService
    {
        public AppointmentDetailService(AutoShopContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override IQueryable<AppointmentDetail> AddFilter(IQueryable<AppointmentDetail> query, AppointmentDetailSearchObject? search = null)
        {
            if (search != null)
            {
                if (search?.AppointmentId != null)
                {
                    query = query.Where(od => od.AppointmentId == search.AppointmentId);
                }
            }
            return base.AddFilter(query, search);
        }
    }
}
