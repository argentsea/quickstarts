using System;
using ArgentSea.Pg;

namespace QuickStart1.Pg.Models
{
    public class Subscriber
    {
        [MapToPgInteger("subid")]
        public int SubscriberId { get; set; }

        [MapToPgVarchar("subname", 255, true)]
        public string Name { get; set; }

        [MapToPgTimestamp("enddate")]
        public DateTime? Expiration { get; set; }
    }
}
