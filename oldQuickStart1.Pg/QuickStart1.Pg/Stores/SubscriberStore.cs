using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using ArgentSea;
using ArgentSea.Pg;
using Quckstart.Pg.Models;


namespace Quckstart.Pg.Stores
{
    public class SubscriberStore
    {
        private readonly PgDatabases _dbs;
        private readonly ILogger<SubscriberStore> _logger;
        public SubscriberStore(PgDatabases dbs, ILogger<SubscriberStore> logger)
        {
            _dbs = dbs;
            _logger = logger;
        }

        public async Task<Subscriber> GetSubscriber(int subscriberId, CancellationToken cancellation)
        {
            var db = _dbs.DbConnections["MyDatabase"];
            var prms = new QueryParameterCollection()
                .AddPgIntegerInParameter("@SubId", subscriberId);
            Mapper.MapToOutParameters(prms, typeof(Subscriber), _logger);
            return await db.QueryAsync<Subscriber>("ws.GetSubscriber", prms, cancellation);
        }
    }
}
