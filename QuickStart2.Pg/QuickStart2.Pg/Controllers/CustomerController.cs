using System.Collections.Generic;
using System.Threading.Tasks;
using System.Threading;
using Microsoft.AspNetCore.Mvc;
using QuickStart2.Pg.Stores;
using QuickStart2.Pg.Models;
using QuickStart2.Pg.InputModels;
using ShardKey = ArgentSea.ShardKey<short, int>;

namespace QuickStart2.Pg.Controllers
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
        }

        // GET api/values/ABCDEFG
        [HttpGet("{key}")]
        public async Task<ActionResult<string>> Get(string key, CancellationToken cancellation)
        {
            var skey = ShardKey.FromExternalString(key);
            return Ok(await _store.GetCustomer(skey, cancellation));
        }

        // POST api/values
        //[HttpPost]
        //public async Task<ActionResult> Post([FromBody] CustomerInputModel customer, CancellationToken cancellation)
        //{
        //    var customerKey = await _store.CreateCustomer(customer, cancellation);
        //    return Ok(customerKey);
        //}

        //// PUT api/values/5
        //[HttpPut]
        //public async Task<ActionResult> Put([FromBody] CustomerModel customer, CancellationToken cancellation)
        //{
        //    await _store.SaveCustomer(customer, cancellation);
        //    return Ok();
        //}

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
