﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.HttpsPolicy;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Microsoft.OpenApi.Models;
using ArgentSea.Pg;
using Microsoft.AspNetCore.Http;

namespace QuickStart2.Pg
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
            services.AddOptions();
            services.AddLogging();
            services.AddPgServices<short>(this.Configuration);
            services.AddSingleton<ShardSets>();

            services.AddTransient<Stores.CustomerStore>();
            services.AddMvc().SetCompatibilityVersion(CompatibilityVersion.Version_2_2);
            services.AddSwaggerGen(o =>
            {
                o.SwaggerDoc("v1", new OpenApiInfo() { Title = "ArgentSea Sharded WebService", Version = "v1" });
                o.DescribeAllEnumsAsStrings();
            });
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IHostingEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }
            else
            {
                app.UseHsts();
            }

            app.UseExceptionHandler(options =>
            {
                options.Run(async context =>
                {
                    context.Response.StatusCode = 500;
                    context.Response.ContentType = "application/json";
                    var contextFeature = context.Features.Get<Microsoft.AspNetCore.Diagnostics.IExceptionHandlerFeature>();
                    if (!(contextFeature is null))
                    {
                        await context.Response.WriteAsync(new ErrorModel(contextFeature.Error).ToJson());
                    }
                });
            });

            app.UseHttpsRedirection();
            app.UseMvc();
            app.UseSwagger();
            app.UseSwaggerUI(o =>
            {
                o.SwaggerEndpoint("/swagger/v1/swagger.json", "ArgentSea QuickStart 2");
                o.RoutePrefix = "swagger"; //default

            });
        }
    }
}
