using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using ArgentSea;
using ArgentSea.Sql;

namespace QuickStart.Sql
{

    public static class Queries
    {
        public static QueryProcedure GetSubscriber => new QueryProcedure("ws.GetSubscriber", new[] { "@SubId", "SubName", "EndDate" });

    }
}
