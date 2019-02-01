using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using ArgentSea;
using ArgentSea.Pg;
using QuickStart1.Pg.Models;

namespace QuickStart1.Pg.Stores
{
    public class SubscriberStore
    {
        private readonly PgDatabases.Database _db;
        private readonly ILogger<SubscriberStore> _logger;

        public SubscriberStore(PgDatabases dbs, ILogger<SubscriberStore> logger)
        {
            _db = dbs["MyDatabase"];
            _logger = logger;
        }

        public async Task<Subscriber> GetSubscriber(int subscriberId, CancellationToken cancellation)
        {
            var prms = new ParameterCollection()
                .AddPgIntegerInputParameter("subid", subscriberId);
            return await _db.Read.MapReaderAsync<Subscriber>(Queries.GetSubscriber, prms, cancellation);
        }
    }
}
