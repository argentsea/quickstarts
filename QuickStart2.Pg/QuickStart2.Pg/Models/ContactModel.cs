using ArgentSea;
using ArgentSea.Pg;
using ShardKey = ArgentSea.ShardKey<short, int>;

namespace QuickStart2.Pg.Models
{
    public class ContactModel
    {
        [MapShardKey('C', "contactid")]
        [MapToPgInteger("contactid")]
        public ShardKey ContactKey { get; set; }

        [MapToPgVarchar("fullname", 255)]
        public string Name { get; set; }
    }
}
