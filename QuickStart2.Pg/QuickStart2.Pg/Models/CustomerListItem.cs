using ArgentSea;
using ArgentSea.Pg;
using System.ComponentModel.DataAnnotations;
using ShardKey = ArgentSea.ShardKey<short, int>;

namespace QuickStart2.Pg.Models
{
    public class CustomerListItem : IKeyedModel<short, int>
    {
        [MapShardKey(DataOrigins.Customer, "customerid")]
        [MapToPgInteger("customerid", true)]
        public ShardKey Key { get; set; }

        [Required]
        [StringLength(255, MinimumLength = 2)]
        [MapToPgVarchar("name", 255, true)]
        public string Name { get; set; }
    }
}
