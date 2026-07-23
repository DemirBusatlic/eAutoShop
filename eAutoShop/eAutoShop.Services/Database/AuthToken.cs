using System;
using System.Collections.Generic;

namespace eAutoShop.Services.Database;

public partial class AuthToken
{
    public int Id { get; set; }

    public string Value { get; set; } = null!;

    public int UserId { get; set; }

    public DateTime Created { get; set; }

    public DateTime? Revoked { get; set; }

    public virtual User User { get; set; } = null!;
}
