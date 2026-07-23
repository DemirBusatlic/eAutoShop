using eAutoShop.Model.Exceptions;
using eAutoShop.Model.Model;
using eAutoShop.Model.SearchObjects;
using eAutoShop.Services.Database;
using eAutoShop.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Identity.Client;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using static Microsoft.EntityFrameworkCore.DbLoggerCategory;

namespace eAutoShop.Services.Services
{
    public class BaseService<T, TDb, TSearch> : IService<T, TSearch> where T : class where TDb : class where TSearch : BaseSearchObject, new()
    {
        protected readonly AutoShopContext _context;
        protected readonly IMapper _mapper;

        private const int MaxPageSize = 100;
        private const int DefaultPage = 1;
        private const int DefaultPageSize = 10;

        public BaseService(AutoShopContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public virtual async Task<PageResult<T>> Get(TSearch? search = null)
        {
            search ??= new TSearch();

            var query = _context.Set<TDb>().AsQueryable();

            query = AddFilter(query, search);

            query = AddInclude(query, search);

            var count = await query.CountAsync();

            var page = search.Page ?? DefaultPage;

            if (page < 1)
                page = DefaultPage;

            var pageSize = search.PageSize ?? DefaultPageSize;

            if (pageSize > MaxPageSize)
                pageSize = MaxPageSize;

            query = query
                .Skip((page - 1) * pageSize)
                .Take(pageSize);

            var list = await query.ToListAsync();

            return new PageResult<T>
            {
                Count = count,
                Result = _mapper.Map<List<T>>(list)
            };
        }

        public virtual async Task<T> GetById(int id)
        {
            var query = _context.Set<TDb>().AsQueryable();

            query = AddInclude(query);

            query = AddFilterById(query, id);

            var entity = await query.FirstOrDefaultAsync();

            if (entity == null)
                throw new UserException("Entity not found.");

            return _mapper.Map<T>(entity);
        }

        public virtual IQueryable<TDb> AddInclude(IQueryable<TDb> query,TSearch? search = null)
        {
            return query;
        }

        public virtual IQueryable<TDb> AddFilter(IQueryable<TDb> query,TSearch? search = null)
        {
            return query;
        }

        public virtual IQueryable<TDb> AddFilterById(IQueryable<TDb> query,int id)
        {
            return query.Where(x => EF.Property<int>(x, "Id") == id);
        }
    }
}

