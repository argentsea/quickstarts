using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using ArgentSea.Sql;
using Microsoft.Extensions.Options;
using Microsoft.Extensions.Logging;
using ArgentSea;


namespace QuickStart2.Sql
{
    public class ShardSets : SqlShardSets<byte>
    {
        public ShardSets(
            IOptions<SqlShardConnectionOptions<byte>> configOptions,
            IOptions<SqlGlobalPropertiesOptions> globalOptions,
            ILogger<ShardSets> logger
        ) : base(configOptions, globalOptions, logger)
        {
            //
        }
    }
}
