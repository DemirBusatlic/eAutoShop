using System;
using System.Collections.Generic;
using System.Text;

namespace eAutoShop.Model.Model
{
    public class EmployeeTaskModel
    {
        public int Id { get; set; }

        public string Title { get; set; } = null!;

        public string Description { get; set; } = null!;

        public int EmployeeId { get; set; }

        public string EmployeeName { get; set; } = null!;

        public int CreatedById { get; set; }

        public string CreatedByName { get; set; } = null!;

        public DateTime CreatedAt { get; set; }

        public DateTime? DueDate { get; set; }

        public DateTime? CompletedAt { get; set; }

        public string State { get; set; } = null!;
    }
}