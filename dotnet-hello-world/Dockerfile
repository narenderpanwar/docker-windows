# Use the official .NET SDK image as the build environment
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build

# Set the working directory in the container
WORKDIR /src

# Copy the solution and project files
COPY ["dotnet-hello-world.sln", "./"]
COPY ["hello-world-api/hello-world-api.csproj", "hello-world-api/"]

# Restore the dependencies (via NuGet)
RUN dotnet restore "dotnet-hello-world.sln"

# Copy the rest of the application files
COPY . .

# Publish the application to the /app directory in the container
RUN dotnet publish "hello-world-api/hello-world-api.csproj" -c Release -o /app

# Use the official .NET Runtime image to run the application
FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base

# Set the working directory in the container
WORKDIR /app

# Copy the published files from the build stage
COPY --from=build /app .

# Expose the port the app runs on
EXPOSE 80

# Set the entrypoint for the container to run the app
ENTRYPOINT ["dotnet", "hello-world-api.dll"]
