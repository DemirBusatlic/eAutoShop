using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.SearchObjects
{
    public class EmployeeTaskSearchObject : BaseSearchObject
    {
        public string? TitleFTS { get; set; }

        public int? EmployeeId { get; set; }

        public int? CreatedById { get; set; }

        public string? State { get; set; }

        public DateTime? MinDueDate { get; set; }

        public DateTime? MaxDueDate { get; set; }
    }
}
