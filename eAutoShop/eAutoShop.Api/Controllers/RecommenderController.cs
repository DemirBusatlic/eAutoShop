using eAutoShop.Model.Model;
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

        [HttpPost("TrainProductsModel")]
        public IActionResult TrainProductsModel()
        {
            _recommenderTrainService.TrainProductsModel();
            return Ok();
        }

        [HttpGet("RecommendProducts/{productId}")]
        public async Task<PageResult<ProductModel>> RecommendProducts(int productId)
        {
            return await _recommenderPredictService.RecommendProduct(productId);
        }
    }
}
