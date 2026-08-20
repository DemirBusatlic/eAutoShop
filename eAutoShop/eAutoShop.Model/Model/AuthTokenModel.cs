using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Model.Model
{
    public class AuthTokenModel
    {
        public int Id { get; set; }

        public string Value { get; set; } = null!;

        public int UserId { get; set; }

        public DateTime Created { get; set; }

        public DateTime? Revoked { get; set; }
    }
}
