
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$PSNativeCommandUseErrorActionPreference = $true # might be true by default

# Define variables
$wslDistroName = "Arch"
$imageName = $wslDistroName.ToLower()
$tarFile = "$imageName.tar"
$dockerFile = "$imageName.dockerfile" 

$wslDataPath = "C:\WSL2\$wslDistroName"

# Step 1: Build the Docker image
Write-Host "Building Docker image from arch.dockerfile..."
docker build -t $imageName -f $dockerFile --progress=plain . 

# Step 2: Export the root filesystem


$cid = docker ps -aqf "name=temp_container"
if ($cid) { 
  docker container rm $cid
}

Write-Host "Exporting the root filesystem to $tarFile..."
docker run --name temp_container $imageName
docker export -o $tarFile temp_container
$cid = docker ps -aqf "name=temp_container"
docker container rm $cid

# Step 3: Import the filesystem into WSL2
Write-Host "Importing the root filesystem into WSL2..."

try {
wsl --unregister $wslDistroName
} catch {}
wsl --import $wslDistroName $wslDataPath $tarFile --version 2

Write-Host "WSL2 distribution $wslDistroName has been created."

Remove-Item $tarFile
