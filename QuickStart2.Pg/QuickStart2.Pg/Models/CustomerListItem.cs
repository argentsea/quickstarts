using ArgentSea;
using ArgentSea.Pg;
using ShardKey = ArgentSea.ShardKey<short, int>;

namespace QuickStart2.Pg.Models
{
    public class CustomerListItem : IKeyedModel<short, int>
    {
        [MapShardKey(DataOrigins.Customer, "customerid")]
        [MapToPgInteger("customerid")]
        public ShardKey Key { get; set; }

        [MapToPgVarchar("name", 255)]
        public string Name { get; set; }
    }
}
