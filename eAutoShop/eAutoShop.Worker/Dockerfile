FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["eAutoShop.Worker/eAutoShop.Worker.csproj", "eAutoShop.Worker/"]
COPY ["eAutoShop.Model/eAutoShop.Model.csproj", "eAutoShop.Model/"]
COPY ["eAutoShop.Services/eAutoShop.Services.csproj", "eAutoShop.Services/"]
RUN dotnet restore "./eAutoShop.Worker/eAutoShop.Worker.csproj"
COPY . .
WORKDIR "/src/eAutoShop.Worker"
RUN dotnet build "./eAutoShop.Worker.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "./eAutoShop.Worker.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "eAutoShop.Worker.dll"]
