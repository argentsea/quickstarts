using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Mvc;
using QuickStart1.Pg.Stores;
using QuickStart1.Pg.Models;

namespace QuickStart1.Pg.Controllers
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
            return await _store.GetSubscriber(id, cancellation);
        }
    }
}
