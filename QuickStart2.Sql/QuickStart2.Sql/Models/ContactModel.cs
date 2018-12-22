using ArgentSea;
using ArgentSea.Sql;
using ShardKey = ArgentSea.ShardKey<byte, int>;

namespace QuickStart2.Sql.Models
{
    public class ContactModel
    {
        [MapShardKey('C', "ContactId")]
        [MapToSqlInt("ContactId")]
        public ShardKey ContactKey { get; set; }

        [MapToSqlNVarChar("FullName", 255)]
        public string Name { get; set; }
    }
}
