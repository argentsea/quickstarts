using System;
using ArgentSea.Sql;

namespace Quckstart.Sql.Models
{
    public class Subscriber
    {
        [MapToSqlInt("@SubId")]
        public int SubscriberId { get; set; }

        [MapToSqlNVarChar("@SubName", 255, true)]
        public string Name { get; set; }

        [MapToSqlDateTime2("@EndDate")]
        public DateTime? Expiration { get; set; }
    }
}
