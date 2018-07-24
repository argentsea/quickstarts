using System;
using ArgentSea.Pg;

namespace QuickStart1.Pg.Models
{
    public class Subscriber
    {
        [MapToPgInteger("_subid")]
        public int SubscriberId { get; set; }

        [MapToPgVarChar("_subname", 255, true)]
        public string Name { get; set; }

        [MapToPgTimestamp("_enddate")]
        public DateTime? Expiration { get; set; }
    }
}
