using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eAutoShop.Services.Database;

public partial class PasswordResetToken
{
    public int Id { get; set; }

    public int UserId { get; set; }

    public string CodeHash { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public DateTime ExpiresAt { get; set; }

    public DateTime? UsedAt { get; set; }

    public DateTime? RevokedAt { get; set; }

    public int FailedAttempts { get; set; }

    public virtual User User { get; set; } = null!;
}
