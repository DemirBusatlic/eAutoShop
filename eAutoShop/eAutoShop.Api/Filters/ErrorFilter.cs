using eAutoShop.Model.Exceptions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using System.Net;

namespace eAutoShop.Api.Filters
{
    public class ErrorFilter : ExceptionFilterAttribute
    {
        public override void OnException(ExceptionContext context)
        {
            var logger = context.HttpContext.RequestServices
                .GetRequiredService<ILogger<ErrorFilter>>();

            if (context.Exception is UserException)
            {
                logger.LogWarning(
                    context.Exception,
                    "Greška uzrokovana neispravnim korisničkim zahtjevom."
                );

                context.ModelState.AddModelError(
                    "error",
                    context.Exception.Message
                );

                context.HttpContext.Response.StatusCode =
                    (int)HttpStatusCode.BadRequest;
            }
            else
            {
                logger.LogError(
                    context.Exception,
                    "Neočekivana serverska greška."
                );

                context.ModelState.AddModelError(
                    "error",
                    "Došlo je do greške na serveru."
                );

                context.HttpContext.Response.StatusCode =
                    (int)HttpStatusCode.InternalServerError;
            }

            var errors = context.ModelState
                .Where(x => x.Value is { Errors.Count: > 0 })
                .ToDictionary(
                    x => x.Key,
                    x => x.Value!.Errors.Select(e => e.ErrorMessage)
                );

            context.Result = new JsonResult(new { errors });
            context.ExceptionHandled = true;
        }
    }
}