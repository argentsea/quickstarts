using ArgentSea;
using ArgentSea.Pg;
using ShardKey = ArgentSea.ShardKey<short, int>;

namespace QuickStart2.Sql.Models
{
    public class ContactModel
    {
        [MapShardKey('C', "ContactId")]
        [MapToPgInteger("ContactId")]
        public ShardKey ContactKey { get; set; }

        [MapToPgVarchar("FullName", 255)]
        public string Name { get; set; }
    }
}
