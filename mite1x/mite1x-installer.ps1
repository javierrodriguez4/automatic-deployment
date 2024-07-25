# Función para leer el archivo .env
function Get-EnvVariables {
    param (
        [string]$filePath
    )
    $envVariables = @{}
    Get-Content $filePath | ForEach-Object {
        if ($_ -match "^\s*([^#;][^=]+?)\s*=\s*(.*?)\s*$") {
            $name, $value = $matches[1], $matches[2]
            $envVariables[$name] = $value
        }
    }
    return $envVariables
}

# Función para descargar archivos desde una URL
function Download-FileFromUrl {
    param (
        [string]$url,
        [string]$outputPath
    )
    Invoke-WebRequest -Uri $url -OutFile $outputPath
}

# Ruta al archivo .env
$envFilePath = ".\.env"

# Leer variables del archivo .env
$envVariables = Get-EnvVariables -filePath $envFilePath

# Obtener el valor de las variables del archivo .env
$disco = $envVariables["DISCO"]
$carpetas = $envVariables["CARPETAS"].Split(",")
$nexusUrl = $envVariables["NEXUS_URL"]
$downloadPath = "$disco\Servicios"

# Crear las carpetas en el disco especificado
foreach ($folder in $carpetas) {
    $path = "$disco\$folder"
    if (-Not (Test-Path -Path $path)) {
        New-Item -ItemType Directory -Path $path
        Write-Output "Carpeta creada: $path"
    } else {
        Write-Output "La carpeta ya existe: $path"
    }
}

# Descargar el archivo desde Nexus
$zipFilePath = "$downloadPath\MitE1x.zip"
Download-FileFromUrl -url $nexusUrl -outputPath $zipFilePath

# Verificar si 7-Zip está instalado
$sevenZipPath = "C:\Program Files\7-Zip\7z.exe"
if (-Not (Test-Path -Path $sevenZipPath)) {
    Write-Error "7-Zip no está instalado en el camino predeterminado: $sevenZipPath. Por favor, instálalo."
    exit 1
}

# Descomprimir el archivo descargado
Start-Process -FilePath $sevenZipPath -ArgumentList "x", "`"$zipFilePath`"", "-o`"$downloadPath`"" -Wait

Write-Output "Descarga y descompresión completadas en: $downloadPath"
