FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 5233
ENV ASPNETCORE_URLS=http://+:5233

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["eAutoShop.HelperApi/eAutoShop.HelperApi.csproj", "eAutoShop.HelperApi/"]
COPY ["eAutoShop.Model/eAutoShop.Model.csproj", "eAutoShop.Model/"]
COPY ["eAutoShop.Services/eAutoShop.Services.csproj", "eAutoShop.Services/"]
RUN dotnet restore "./eAutoShop.HelperApi/eAutoShop.HelperApi.csproj"
COPY . .
WORKDIR "/src/eAutoShop.HelperApi"
RUN dotnet build "./eAutoShop.HelperApi.csproj" -c Release -o /app/build


FROM build AS publish
RUN dotnet publish "./eAutoShop.HelperApi.csproj" -c Release -o /app/publish 


FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "eAutoShop.HelperApi.dll"]