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

# Función para deshabilitar el firewall de Windows
function Disable-WindowsFirewall {
    Write-Output "Deshabilitando el firewall de Windows..."
    try {
        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
        Write-Output "Firewall de Windows deshabilitado."
    } catch {
        Write-Error "Error al deshabilitar el firewall: $_"
    }
}

# Ruta al archivo .env
$envFilePath = ".\.env"

# Leer variables del archivo .env
$envVariables = Get-EnvVariables -filePath $envFilePath

# Obtener el valor de las variables del archivo .env
$disco = $envVariables["DISCO"]
$carpetas = $envVariables["CARPETAS"].Split(",")
$sqlncliUrl = $envVariables["SQLNCLI_URL"]
$downloadPath = "$disco\Servicios"

# Deshabilitar el firewall de Windows
Disable-WindowsFirewall

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

# Descargar el archivo SQL Server Native Client
$sqlncliPath = "$downloadPath\sqlncli.msi"
Download-FileFromUrl -url $sqlncliUrl -outputPath $sqlncliPath

# Ejecutar comandos bcdedit
Write-Output "Ejecutando comandos bcdedit..."
Start-Process -FilePath "bcdedit" -ArgumentList "-set loadoptions disable_integrity_checks" -Wait -NoNewWindow
Start-Process -FilePath "bcdedit" -ArgumentList "-set testsigning on" -Wait -NoNewWindow

# Mostrar mensaje para instalación manual
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show("El archivo `sqlncli.msi` esta en la ruta $sqlncliPath. Debe instalarse manualmente para que la aplicacion MitE1x funcione correctamente. Por favor, haga clic en Aceptar para continuar.", "Instalacion Manual Requerida", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

Write-Output "El archivo sqlncli.msi ha sido descargado y está listo para la instalación manual."

# Mostrar mensaje de reinicio y contador de 10 segundos
$confirmRestart = [System.Windows.Forms.MessageBox]::Show("El servidor se va a reiniciar. Presione Aceptar para iniciar un contador de 10 segundos antes del reinicio.", "Reinicio del Servidor", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)

if ($confirmRestart -eq [System.Windows.Forms.DialogResult]::OK) {
    for ($i = 10; $i -ge 0; $i--) {
        Write-Output "Reiniciando en $i segundos..."
        Start-Sleep -Seconds 1
    }
    Restart-Computer -Force
}
