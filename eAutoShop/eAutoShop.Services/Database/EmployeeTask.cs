using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Database;

public partial class EmployeeTask
{
    public int Id { get; set; }

    public string Title { get; set; } = null!;

    public string Description { get; set; } = null!;

    public int EmployeeId { get; set; }

    public int CreatedById { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? DueDate { get; set; }

    public DateTime? CompletedAt { get; set; }

    public string State { get; set; } = null!;

    public virtual User Employee { get; set; } = null!;

    public virtual User CreatedBy { get; set; } = null!;
}
