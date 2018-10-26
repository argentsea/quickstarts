using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using ArgentSea;
using ArgentSea.Sql;
using Quckstart.Sql.Models;


namespace Quckstart.Sql.Stores
{
    public class SubscriberStore
    {
        private readonly SqlDatabases _dbs;
        private readonly ILogger<SubscriberStore> _logger;
        public SubscriberStore(SqlDatabases dbs, ILogger<SubscriberStore> logger)
        {
            _dbs = dbs;
            _logger = logger;
        }

        public async Task<Subscriber> GetSubscriber(int subscriberId, CancellationToken cancellation)
        {
            var db = _dbs["MyDatabase"];
            var prms = new QueryParameterCollection()
                .AddSqlIntInputParameter("@SubId", subscriberId)
                .CreateOutputParameters<Subscriber>(_logger);
            return await db.MapOutputAsync<Subscriber>("ws.GetSubscriber", prms, cancellation);
        }
    }
}
