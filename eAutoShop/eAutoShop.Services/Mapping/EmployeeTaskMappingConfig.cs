using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using eAutoShop.Model.Model;
using eAutoShop.Services.Database;
using Mapster;

namespace eAutoShop.Services.Mapping
{
    public class EmployeeTaskMappingConfig : IRegister
    {
        public void Register(TypeAdapterConfig config)
        {
            config.NewConfig<EmployeeTask, EmployeeTaskModel>()
                .Map(
                    destination => destination.EmployeeName,
                    source => source.Employee.Name + " " +
                              source.Employee.Surname
                )
                .Map(
                    destination => destination.CreatedByName,
                    source => source.CreatedBy.Name + " " +
                              source.CreatedBy.Surname
                );
        }
    }
}
