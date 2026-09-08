using eAutoShop.Api.Controllers;
using eAutoShop.Model.Model;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

[ApiController]
public class CarModelController: BaseController<CarModelModel, CarModelSearchObject>
{
    private readonly ICarModelService _carModelService;

    public CarModelController(ICarModelService service,ILogger<BaseController<CarModelModel, CarModelSearchObject>> logger): base(logger, service)
    {
        _carModelService = service;
    }

    [HttpGet("/GetByManufacturerAll")]
    public async Task<PageResult<CarModelGetByManufacturerModel>>GetByManufacturerAll()
    {
        return await _carModelService.GetByManufacturerAll();
    }
}