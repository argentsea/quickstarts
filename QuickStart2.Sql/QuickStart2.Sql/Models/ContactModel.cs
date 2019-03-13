using ArgentSea;
using ArgentSea.Sql;
using ShardKey = ArgentSea.ShardKey<byte, int>;

namespace QuickStart2.Sql.Models
{
    public class ContactModel : ContactListItem
    {
        public string Email { get; set; }

        public string Phone { get; set; }
    }
}
