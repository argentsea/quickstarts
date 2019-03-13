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
            var result = await _store.GetCustomer(skey, cancellation);
            if (result is null)
            {
                return NotFound();
            }
            return Ok(result);
        }

        [HttpPost]
        public async Task<ActionResult> Post([FromBody] CustomerInputModel customer, CancellationToken cancellation)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }
            return Ok(await _store.CreateCustomer(customer, cancellation));
        }

        [HttpPut]
        public async Task<ActionResult> Put([FromBody] CustomerModel customer, CancellationToken cancellation)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }
            await _store.UpdateCustomer(customer, cancellation);
            return Ok();
        }

        [HttpDelete("{key}")]
        public async Task<ActionResult> Delete(string key, CancellationToken cancellation)
        {
            var skey = ShardKey.FromExternalString(key);
            await _store.DeleteCustomer(skey, cancellation);
            return Ok();
        }
    }
}
