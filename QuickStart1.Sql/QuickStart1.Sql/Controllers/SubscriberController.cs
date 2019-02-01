using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Mvc;
using QuickStart.Sql.Stores;
using QuickStart.Sql.Models;

namespace QuickStart.Sql.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class SubscriberController : ControllerBase
    {
        private readonly SubscriberStore _store;
        private readonly ILogger<SubscriberController> _logger;

        public SubscriberController(SubscriberStore store, ILogger<SubscriberController> logger)
        {
            _store = store;
            _logger = logger;
        }

        // GET api/subscriber/5
        [HttpGet("{id}")]
        public async Task<ActionResult<Subscriber>> Get(int id, CancellationToken cancellation)
        {
            var result = await _store.GetSubscriber(id, cancellation);
            if (result is null)
            {
                return NotFound();
            }
            return result;
        }
    }
}
