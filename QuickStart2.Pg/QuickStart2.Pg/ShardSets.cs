using ArgentSea.Pg;
using Microsoft.Extensions.Options;
using Microsoft.Extensions.Logging;


namespace QuickStart2.Pg
{
    public class ShardSets : PgShardSets<short>
    {
        public ShardSets(
            IOptions<PgShardConnectionOptions<short>> configOptions,
            IOptions<PgGlobalPropertiesOptions> globalOptions,
            ILogger<ShardSets> logger
        ) : base(configOptions, globalOptions, logger)
        {
            //
        }
    }
}
