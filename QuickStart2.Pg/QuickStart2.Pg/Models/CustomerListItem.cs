using ArgentSea;
using ArgentSea.Pg;
using ShardKey = ArgentSea.ShardKey<short, int>;

namespace QuickStart2.Pg.Models
{
    public class CustomerListItem
    {
        [MapShardKey('c', "customerid")]
        [MapToPgInteger("customerid")]
        public ShardKey CustomerKey { get; set; }

        [MapToPgVarchar("name", 255)]
        public string Name { get; set; }
    }
}
