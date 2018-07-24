using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Mvc;
using Quckstart.Pg.Stores;
using Quckstart.Pg.Models;

namespace Quckstart.Pg.Controllers
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
