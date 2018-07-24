using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using ArgentSea;
using ArgentSea.Pg;
using Quckstart.Pg.Stores;

namespace Quckstart.Pg
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddLogging();
            //services.Configure<PgDbConnectionOptions>(options => Configuration.GetSection("").Bind(options));

            //services.AddPgServices(Configuration);
            services.Configure<DataResilienceOptions>(Configuration);
            services.Configure<DataSecurityOptions>(Configuration);
            //services.Configure<PgDbConnectionOptions>(Configuration);
            services.Configure<PgDbConnectionOptions>(options => Configuration.GetSection("PgDbConnections").Bind(options));
            services.AddSingleton<PgDatabases>();


            services.AddSingleton<SubscriberStore>();
            services.AddMvc().SetCompatibilityVersion(CompatibilityVersion.Version_2_1);
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IHostingEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }

            app.UseMvc();
        }
    }
}
