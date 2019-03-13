using ArgentSea;
using ArgentSea.Sql;
using System.ComponentModel.DataAnnotations;
using ShardKey = ArgentSea.ShardKey<byte, int>;

namespace QuickStart2.Sql.Models
{
    public class ContactListItem : IKeyedModel<byte, int>
    {
        [MapShardKey(DataOrigins.Contact, "ContactShardId", "ContactId")]
        [MapToSqlTinyInt("ContactShardId", true)]
        [MapToSqlInt("ContactId", true)]
        public ShardKey Key { get; set; }

        [Required]
        [MapToSqlNVarChar("FullName", 255)]
        public string Name { get; set; }
    }
}