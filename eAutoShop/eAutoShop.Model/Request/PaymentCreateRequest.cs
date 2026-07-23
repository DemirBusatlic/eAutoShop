using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Model.Request
{
    public class PaymentCreateRequest
    {
        public int? OrderId { get; set; }
        public int? AppointmentId { get; set; } 
        public long TotalAmount { get; set; }
        public string? PaymentMethodId { get; set; }
        public string? Username { get; set; }
    }
}
