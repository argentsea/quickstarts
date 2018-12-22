using ArgentSea;
using ArgentSea.Sql;
using ShardKey = ArgentSea.ShardKey<byte, int>;

namespace QuickStart2.Sql.Models
{
    public class CustomerListItem
    {
        [MapShardKey('c', "CustomerId")]
        [MapToSqlInt("@CustomerId")]
        [MapToSqlSmallInt("@ShardId")]
        public ShardKey CustomerKey { get; set; }

        [MapToSqlNVarChar("@Name", 255)]
        public string Name { get; set; }
    }
}
