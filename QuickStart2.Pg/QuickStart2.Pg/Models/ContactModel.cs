using ArgentSea;
using ArgentSea.Pg;
using ShardKey = ArgentSea.ShardKey<short, int>;

namespace QuickStart2.Pg.Models
{
    public class ContactModel : IKeyedModel<short, int>
    {
        [MapShardKey(DataOrigins.Contact, "contactid")]
        [MapToPgInteger("contactid")]
        public ShardKey Key { get; set; }

        [MapToPgVarchar("fullname", 255)]
        public string Name { get; set; }
    }
}
