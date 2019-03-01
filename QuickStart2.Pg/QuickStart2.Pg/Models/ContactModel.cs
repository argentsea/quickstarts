using ArgentSea;
using ArgentSea.Pg;
using System.ComponentModel.DataAnnotations;
using ShardKey = ArgentSea.ShardKey<short, int>;

namespace QuickStart2.Pg.Models
{
    public class ContactModel : ContactListItem
    {
        public string Email { get; set; }

        public string Phone { get; set; }
    }
}
