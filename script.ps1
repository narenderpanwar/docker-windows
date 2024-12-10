# Parameters
param (
    [string]$ImageName = "dotapp:latest",
    [string]$ContainerName = "dotapp-container",
    [string]$PortMapping = "8080:80"
)

# Function to check if Docker is installed
function Check-Docker {
    Write-Host "Checking if Docker is installed..." -ForegroundColor Cyan
    $dockerPath = Get-Command docker -ErrorAction SilentlyContinue
    if (!$dockerPath) {
        Write-Error "Docker is not installed or not in PATH. Please install Docker and try again."
        exit 1
    } else {
        Write-Host "Docker is installed." -ForegroundColor Green
    }
}

# Function to check if the Docker image exists locally
function Check-LocalImage {
    Write-Host "Checking if the Docker image '$ImageName' exists locally..." -ForegroundColor Cyan
    $imageExists = docker images --format "{{.Repository}}:{{.Tag}}" | Where-Object { $_ -eq $ImageName }
    if ($imageExists) {
        Write-Host "Docker image '$ImageName' found locally." -ForegroundColor Green
        return $true
    } else {
        Write-Host "Docker image '$ImageName' not found locally." -ForegroundColor Yellow
        return $false
    }
}

# Function to pull the Docker image
function Pull-DockerImage {
    Write-Host "Pulling the Docker image: $ImageName" -ForegroundColor Cyan
    docker pull $ImageName
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to pull the Docker image: $ImageName."
        exit 1
    } else {
        Write-Host "Docker image '$ImageName' pulled successfully." -ForegroundColor Green
    }
}

# Function to check if a container with the same name exists
function Remove-ExistingContainer {
    Write-Host "Checking if a container with the name '$ContainerName' exists..." -ForegroundColor Cyan
    $containerExists = docker ps -a --filter "name=$ContainerName" --format "{{.Names}}" | Where-Object { $_ -eq $ContainerName }
    if ($containerExists) {
        Write-Host "Stopping and removing the existing container: $ContainerName" -ForegroundColor Yellow
        docker stop $ContainerName
        docker rm $ContainerName
    } else {
        Write-Host "No existing container with the name '$ContainerName' found." -ForegroundColor Green
    }
}

# Function to run the Docker container
function Run-DockerContainer {
    Write-Host "Running the Docker container: $ContainerName" -ForegroundColor Cyan
    docker run -d -p $PortMapping --name $ContainerName $ImageName
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Docker container '$ContainerName' is running on port $PortMapping." -ForegroundColor Green
    } else {
        Write-Error "Failed to run the Docker container."
        exit 1
    }
}

# Main execution
Check-Docker

if (-not (Check-LocalImage)) {
    Pull-DockerImage
}

Remove-ExistingContainer
Run-DockerContainer

