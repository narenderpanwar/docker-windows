# Parameters
param (
    [string]$ImageName = "dotapp:latest",
    [string]$ContainerName = "dotapp-container",
    [string]$PortMapping = "8080:80",
    [string]$GitRepo = "https://github.com/narenderpanwar/docker-windows.git",
    [string]$ClonePath = "$PSScriptRoot/docker-windows"
)

# Function to install Docker on Windows Server
function Install-Docker {
    Write-Host "Docker is not installed. Initiating installation..." -ForegroundColor Cyan

    # Step 1: Install DockerMsftProvider module
    Write-Host "Installing DockerMsftProvider module..." -ForegroundColor Cyan
    Install-Module DockerMsftProvider -Force
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to install DockerMsftProvider module."
        exit 1
    } else {
        Write-Host "DockerMsftProvider module installed successfully." -ForegroundColor Green
    }

    # Step 2: Download the Docker installation script
    Write-Host "Downloading Docker installation script..." -ForegroundColor Cyan
    Invoke-WebRequest -UseBasicParsing `
        "https://raw.githubusercontent.com/microsoft/Windows-Containers/Main/helpful_tools/Install-DockerCE/install-docker-ce.ps1" `
        -OutFile "install-docker-ce.ps1"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to download Docker installation script."
        exit 1
    } else {
        Write-Host "Docker installation script downloaded successfully." -ForegroundColor Green
    }

    # Step 3: Execute the installation script
    Write-Host "Executing Docker installation script..." -ForegroundColor Cyan
    .\install-docker-ce.ps1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker installation failed."
        exit 1
    } else {
        Write-Host "Docker installed successfully." -ForegroundColor Green
    }

    # Step 4: Verify Docker installation
    Write-Host "Verifying Docker installation..." -ForegroundColor Cyan
    $dockerVersion = docker --version
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker verification failed. Ensure Docker is installed and accessible."
        exit 1
    } else {
        Write-Host "Docker is installed and operational: $dockerVersion" -ForegroundColor Green
    }
}

# Function to check if Docker is installed
function Check-Docker {
    Write-Host "Checking if Docker is installed..." -ForegroundColor Cyan
    $dockerPath = Get-Command docker -ErrorAction SilentlyContinue
    if (!$dockerPath) {
        Write-Host "Docker not found. Initiating installation..." -ForegroundColor Yellow
        Install-Docker
    } else {
        Write-Host "Docker is installed." -ForegroundColor Green
    }
}

# Function to clone the Git repository and build the Docker image
function Build-DockerImage {
    Write-Host "Cloning the Git repository: $GitRepo" -ForegroundColor Cyan
    if (Test-Path $ClonePath) {
        Write-Host "Directory $ClonePath already exists. Cleaning up..." -ForegroundColor Yellow
        Remove-Item -Recurse -Force $ClonePath
    }
    git clone $GitRepo $ClonePath
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to clone the repository: $GitRepo."
        exit 1
    } else {
        Write-Host "Repository cloned successfully." -ForegroundColor Green
    }

    Write-Host "Building the Docker image: $ImageName" -ForegroundColor Cyan
    docker build -t $ImageName $ClonePath/dotnet-hello-world
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build the Docker image: $ImageName."
        exit 1
    } else {
        Write-Host "Docker image '$ImageName' built successfully." -ForegroundColor Green
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
    Build-DockerImage
}

Remove-ExistingContainer
Run-DockerContainer

