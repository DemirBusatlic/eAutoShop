using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.Model
{
    public class AppointmentDetailModel
    {
        public int AutoShopServiceId { get; set; }
        public string ServiceName { get; set; }
        public double ServicePrice { get; set; }
        public double ServiceDiscount { get; set; }
        public double ServiceDiscountedPrice { get; set; }
    }
}
