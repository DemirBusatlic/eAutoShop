using System.Security.Claims;
using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Services.Helpers;
using eAutoShop.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eAutoShop.Api.Controllers
{
    [Authorize]
    [ApiController]
    [Route("[controller]")]
    public class RecommenderController : ControllerBase
    {
        private readonly IRecommenderTrainService _recommenderTrainService;
        private readonly IRecommenderPredictService _recommenderPredictService;

        public RecommenderController(IRecommenderTrainService recommenderTrainService, IRecommenderPredictService recommenderPredictService)
        {
            _recommenderTrainService = recommenderTrainService;
            _recommenderPredictService = recommenderPredictService;
        }

        [Authorize(Roles = UserRoles.Manager)]
        [HttpPost("TrainProductsModel")]
        public async Task<IActionResult> TrainProductsModel()
        {
            await _recommenderTrainService.TrainProductsModel();
            return Ok();
        }

        [Authorize(Roles = UserRoles.Customer)]
        [HttpGet("RecommendProducts")]
        public async Task<PageResult<ProductModel>> RecommendProducts()
        {
            var customerIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (!int.TryParse(customerIdClaim, out var customerId))
            {
                throw new UserException("Neispravan korisnički token.");
            }

            return await _recommenderPredictService.RecommendProductsForUser(customerId);
        }
    }
}
