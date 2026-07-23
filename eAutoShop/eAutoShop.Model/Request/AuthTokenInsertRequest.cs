using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Model.Request
{
    public class AuthTokenInsertRequest
    {
        public int Id { get; set; }
        public string Value { get; set; }
        public int UserId { get; set; }
        public DateTime Created { get; set; }
    }
}
