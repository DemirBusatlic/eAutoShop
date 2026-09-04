using eAutoShop.Model.Model;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eAutoShop.Api.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class BaseCRUDController<T, TSearch, TInsert, TUpdate> : BaseController<T, TSearch> where T : class where TSearch : BaseSearchObject, new() where TInsert : class where TUpdate : class
    {
        protected readonly IBaseCRUDService<T, TSearch, TInsert, TUpdate> _crudService;

        public BaseCRUDController(ILogger<BaseController<T, TSearch>> logger, IBaseCRUDService<T, TSearch, TInsert, TUpdate> service) : base(logger, service)
        {
            _crudService = service;
        }

        [Authorize]
        [HttpPost]
        public virtual async Task<T> Insert([FromBody] TInsert insert)
        {
            return await _crudService.Insert(insert);
        }

        [Authorize]
        [HttpPut("{id}")]
        public virtual async Task<T> Update(int id, [FromBody] TUpdate update)
        {
            return await _crudService.Update(id, update);
        }

        [Authorize]
        [HttpDelete("{id}")]
        public virtual async Task<IActionResult> Delete(int id)
        {
            await _crudService.Delete(id);

            return NoContent();
        }
    }
}
