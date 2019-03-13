using ArgentSea;
using ArgentSea.Pg;
using System.ComponentModel.DataAnnotations;
using ShardKey = ArgentSea.ShardKey<short, int>;

namespace QuickStart2.Pg.Models
{
    public class ContactListItem : IKeyedModel<short, int>
    {
        [MapShardKey(DataOrigins.Contact, "contactshardid", "contactid")]
        [MapToPgSmallint("contactshardid", true)]
        [MapToPgInteger("contactid", true)]
        public ShardKey Key { get; set; }

        [Required]
        [MapToPgVarchar("fullname", 255)]
        public string Name { get; set; }
    }
}
