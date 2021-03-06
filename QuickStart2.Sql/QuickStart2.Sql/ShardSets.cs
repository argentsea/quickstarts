﻿using ArgentSea.Sql;
using Microsoft.Extensions.Options;
using Microsoft.Extensions.Logging;


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
