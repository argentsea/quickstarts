using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using ArgentSea;
using ArgentSea.Sql;

namespace QuickStart2.Sql.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ValuesController : ControllerBase
    {
        ArgentSea.Sql.SqlDbConnectionOptions _dbConfig;
        ArgentSea.Sql.SqlShardConnectionOptions<byte> _shardConfig;


        // GET api/values
        [HttpGet]
        public ActionResult<IEnumerable<string>> Get()
        {
            //_dbConfig.SqlDbConnections[""].DatabaseKey;
            //_dbConfig.SqlDbConnections[""].DataResilienceKey;
            //_dbConfig.SqlDbConnections[""].SecurityKey;
            //_dbConfig.SqlDbConnections[""].DataConnection.ApplicationIntent;
            //_dbConfig.SqlDbConnections[""].DataConnection.ApplicationName;
            //_dbConfig.SqlDbConnections[""].DataConnection.ConnectionDescription;

            //_shardConfig.SqlShardSets[""].DataResilienceKey;.
            //_shardConfig.SqlShardSets[""].SecurityKey;
            //_shardConfig.SqlShardSets[""].ShardSetKey;.
            //_shardConfig.SqlShardSets[""].Shards[0].ShardId;
            //_shardConfig.SqlShardSets[""].Shards[0].ReadConnection;
            //_shardConfig.SqlShardSets[""].Shards[0].WriteConnection;
            //_shardConfig.SqlShardSets[""].Shards[0].WriteConnection.ApplicationIntent;
            //_shardConfig.SqlShardSets[""].Shards[0].WriteConnection.ApplicationName;
            //_shardConfig.SqlShardSets[""].Shards[0].WriteConnection.ConnectionDescription;

            //_dbConfig.SqlDbConnections[0].DataConnection.DataResilienceKey
            //_dbConfig.SqlDbConnections[0].DataConnection.SecurityKey;
            //_dbConfig.SqlDbConnections[0].DataConnection.ApplicationIntent


            return new string[] { "value1", "value2" };
        }

        // GET api/values/5
        [HttpGet("{id}")]
        public ActionResult<string> Get(int id)
        {
            return "value";
        }

        // POST api/values
        [HttpPost]
        public void Post([FromBody] string value)
        {
        }

        // PUT api/values/5
        [HttpPut("{id}")]
        public void Put(int id, [FromBody] string value)
        {
        }

        // DELETE api/values/5
        [HttpDelete("{id}")]
        public void Delete(int id)
        {
        }
    }
}
