using ArgentSea;
using ArgentSea.Pg;
using ShardKey = ArgentSea.ShardKey<byte, int>;

namespace QuickStart2.Sql.Models
{
    public class CustomerListItem
    {
        [MapShardKey('c', "@CustomerId")]
        [MapToPgInteger("@CustomerId")]
        public ShardKey CustomerKey { get; set; }

        [MapToPgVarchar("@Name", 255)]
        public string Name { get; set; }
    }
}
