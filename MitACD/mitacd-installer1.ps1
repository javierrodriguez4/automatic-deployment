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

# Función para descargar archivos desde una URL sin autenticación
function Download-FileFromUrl {
    param (
        [string]$url,
        [string]$outputPath
    )
    try {
        Write-Output "Intentando descargar desde $url..."
        
        $webRequest = [System.Net.HttpWebRequest]::Create($url)
        $webRequest.Method = "GET"
        
        $response = $webRequest.GetResponse()
        $responseStream = $response.GetResponseStream()
        $fileStream = [System.IO.File]::Create($outputPath)
        $buffer = New-Object byte[] 1024
        $bytesRead = 0

        while (($bytesRead = $responseStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $fileStream.Write($buffer, 0, $bytesRead)
        }

        $responseStream.Close()
        $fileStream.Close()
        Write-Output "Archivo descargado correctamente en $outputPath"
    } catch {
        Write-Error "Error al descargar el archivo: $_"
    }
}

# Ruta al archivo .env
$envFilePath = ".\.env"

# Leer variables del archivo .env
$envVariables = Get-EnvVariables -filePath $envFilePath

# Obtener el valor de las variables del archivo .env
$disco = $envVariables["DISCO"]
$carpetas = $envVariables["CARPETAS"].Split(",")
$nexusBaseUrl = $envVariables["NEXUS_BASE_URL"]
$version = $envVariables["VERSION"]

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
$downloadUrl = "$nexusBaseUrl$version"
$downloadPath = "$disco\Servicios\$version"
Download-FileFromUrl -url $downloadUrl -outputPath $downloadPath

# Verificar si 7-Zip está instalado
$sevenZipPath = "C:\Program Files\7-Zip\7z.exe"
if (-Not (Test-Path -Path $sevenZipPath)) {
    Write-Error "7-Zip no está instalado en el camino predeterminado: $sevenZipPath. Por favor, instálalo."
    exit 1
}

# Descomprimir el archivo descargado
$extractPath = "$disco\Servicios\MitACD"
if (-Not (Test-Path -Path $extractPath)) {
    New-Item -ItemType Directory -Path $extractPath
}
Start-Process -FilePath $sevenZipPath -ArgumentList "x", "`$downloadPath`", "-o`$extractPath`" -Wait

Write-Output "Descarga y descompresión completadas en: $extractPath"
