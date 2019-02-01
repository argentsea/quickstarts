using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using ArgentSea;
using ArgentSea.Sql;
using QuickStart.Sql.Models;


namespace QuickStart.Sql.Stores
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
            var prms = new ParameterCollection()
                .AddSqlIntInputParameter("@SubId", subscriberId)
                .CreateOutputParameters<Subscriber>(_logger);
            return await db.Read.MapOutputAsync<Subscriber>(Queries.GetSubscriber, prms, cancellation);
        }
    }
}
