using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using ArgentSea;
using ArgentSea.Pg;
using Microsoft.Extensions.Configuration;

namespace QuickStart1.Pg
{
    public static class Queries
    {
        private static readonly Lazy<QueryStatement> _getSubscriber = QueryStatement.Create("GetSubscriber", new[] { "subid" });
        public static QueryStatement GetSubscriber => _getSubscriber.Value;
    }
}
