using System;
using System.Collections.Generic;
using System.Linq;
using System.ComponentModel.DataAnnotations;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Model.Request
{
    public class PaymentCreateRequest
    {
        [Range(1, int.MaxValue)]
        public int OrderId { get; set; }
    }
}
