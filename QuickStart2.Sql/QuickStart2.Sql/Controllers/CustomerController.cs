using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Threading;
using Microsoft.AspNetCore.Mvc;
using ArgentSea;
using ArgentSea.Sql;
using QuickStart2.Sql.Stores;
using QuickStart2.Sql.Models;
using QuickStart2.Sql.InputModels;
using ShardKey = ArgentSea.ShardKey<byte, int>;

namespace QuickStart2.Sql.Controllers
{
    [Route("[controller]")]
    [ApiController]
    public class CustomerController : ControllerBase
    {
        private readonly CustomerStore _store;

        public CustomerController(CustomerStore store)
        {
            _store = store;
        }

        // GET api/values
        [HttpGet]
        public async Task<ActionResult<IEnumerable<CustomerListItem>>> Get(CancellationToken cancellation)
        {
            return Ok(await _store.ListCustomers(cancellation));

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


        }

        // GET api/values/ABCDEFG
        [HttpGet("{key}")]
        public async Task<ActionResult<string>> Get(string key, CancellationToken cancellation)
        {
            var skey = ShardKey.FromExternalString(key);
            return Ok(await _store.GetCustomer(skey, cancellation));
        }

        // POST api/values
        [HttpPost]
        public async Task<ActionResult> Post([FromBody] CustomerInputModel customer, CancellationToken cancellation)
        {
            var customerKey = await _store.CreateCustomer(customer, cancellation);
            return Ok(customerKey);
        }

        // PUT api/values/5
        [HttpPut]
        public async Task<ActionResult> Put([FromBody] CustomerModel customer, CancellationToken cancellation)
        {
            await _store.SaveCustomer(customer, cancellation);
            return Ok();
        }

        // DELETE api/values/5
        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(string key, CancellationToken cancellation)
        {
            var skey = ShardKey.FromExternalString(key);
            await _store.DeleteCustomer(skey, cancellation);
            return Ok();
        }
    }
}
