﻿using System.Linq;
using System.Web.Http;
using System.Web.Mvc;
using System.Web.Optimization;
using System.Web.Routing;
using System.Web.Security;
using AlwayEncryptedSample.Models;
using AlwayEncryptedSample.Services;
using Microsoft.AspNet.Identity;
using Microsoft.AspNet.Identity.EntityFramework;
using ApplicationDbContext = AlwayEncryptedSample.Services.ApplicationDbContext;

namespace AlwayEncryptedSample
{
    public class MvcApplication : System.Web.HttpApplication
    {
        protected void Application_Start()
        {
            AreaRegistration.RegisterAllAreas();
            GlobalConfiguration.Configure(WebApiConfig.Register);
            FilterConfig.RegisterGlobalFilters(GlobalFilters.Filters);
            RouteConfig.RegisterRoutes(RouteTable.Routes);
            BundleConfig.RegisterBundles(BundleTable.Bundles);
            // Force creation of the database at startup.
            using (var authDbCtx = AuthDbContext.Create())
            {
                if (!authDbCtx.Roles.Any())
                {
                    var roleManager = new RoleManager<IdentityRole>(new RoleStore<IdentityRole>(authDbCtx));
                    roleManager.Create(new IdentityRole("DBAs"));
                    roleManager.Create(new IdentityRole("Credit Card Admins"));
                }
                if (!authDbCtx.Users.Any())
                {
                    var userManager = new UserManager<ApplicationUser>(new UserStore<ApplicationUser>(authDbCtx));
                    userManager.Create(new ApplicationUser
                    {
                        Id = "Administrator",
                        Email = "no-reply+admin@microsoft.com",
                        UserName = "Administrator",
                        EmailConfirmed = true,
                        PasswordHash = userManager.PasswordHasher.HashPassword("P3ter!"),
                    });

                    userManager.AddToRole("Administrator", "DBAs");

                    userManager.Create(new ApplicationUser
                    {
                        Email = "no-reply+creditcard@microsoft.com",
                        Id = "CCAdmin",
                        UserName = "CCAdmin",
                        EmailConfirmed = true,
                        PasswordHash = userManager.PasswordHasher.HashPassword("P@ul!")
                    });
                    userManager.AddToRole("CCAdmin", "Credit Card Admins");
                }
            }
            (new ApplicationDbContext()).CreditCards.Find(-1);
        }
    }
}