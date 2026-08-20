using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.Model
{
    public class AppointmentDetailModel
    {
        public int ServiceId { get; set; }
        public string ServiceName { get; set; } = null!;
        public double ServicePrice { get; set; }
        public double ServiceDiscount { get; set; }
        public double ServiceDiscountedPrice { get; set; }
    }
}
