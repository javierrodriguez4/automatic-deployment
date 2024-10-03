# Ruta al archivo .env
$envFilePath = ".\.env"

# Función para leer variables del archivo .env
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

# Función para escribir en el archivo de log
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logMessage = "$timestamp - $message"
    if ($logFilePath) {
        Add-Content -Path $logFilePath -Value $logMessage
    }
}

# Leer variables del archivo .env
$envVariables = Get-EnvVariables -filePath $envFilePath

# Obtener la letra del disco desde el archivo .env
$disco = $envVariables["DISCO"]

# Comprobar si la letra del disco es válida
if (-Not (Test-Path "$disco\")) {
    Write-Log "La unidad $disco no está disponible."
    exit 1
}

# Obtener la ruta de los drivers desde el archivo .env (sin la letra del disco)
$driversPathRelative = $envVariables["DRIVERS_PATH"]

# Construir la ruta completa a los drivers
$driversPath = Join-Path -Path $disco -ChildPath $driversPathRelative

# Comprobar si la ruta a los drivers es válida
if (-Not (Test-Path $driversPath)) {
    Write-Log "La ruta a los drivers no es válida: $driversPath"
    exit 1
}

# Ruta completa al archivo install.bat
$installBatPath = Join-Path -Path $driversPath -ChildPath "install.bat"

# Construir la ruta completa al archivo de log
$pathLogs = $envVariables["PATH_LOGS"]
$logFilePath = Join-Path -Path $pathLogs -ChildPath "install.log"

# Cambiar al directorio de los drivers
Write-Log "Cambiando al directorio: $driversPath"
Set-Location -Path $driversPath

# Confirmar el cambio de directorio
Write-Log "Directorio actual: $(Get-Location)"

# Ejecutar install.bat
Write-Log "Ejecutando $installBatPath en el directorio $driversPath..."
Start-Process -FilePath $installBatPath -Wait -NoNewWindow

# Verificar si el archivo MitE1x.exe está en la ruta correcta
$exePath = Join-Path -Path (Split-Path -Parent $driversPath) -ChildPath "MitE1x.exe"

# Verificar si MitE1x.exe existe
if (-Not (Test-Path $exePath)) {
    Write-Log "El archivo MitE1x.exe no se encontró en la ruta: $exePath"
    exit 1
}

# Ejecutar MitE1x.exe
Write-Log "Ejecutando $exePath..."
$process = Start-Process -FilePath $exePath -PassThru

# Esperar a que MitE1x.exe inicie (esto puede necesitar ajustarse dependiendo del tiempo de inicio de la aplicación)
Start-Sleep -Seconds 10

# Cerrar MitE1x.exe
Write-Log "Cerrando $exePath..."
$process | Stop-Process -Force

# Obtener IP de la variable ACD_IP del archivo .env
$acdIp = $envVariables["ACD_IP"]

# Obtener IP de la interfaz de red de Windows 10
$networkIp = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.Address -ne "127.0.0.1" }).IPAddress

# Ruta al archivo sttr_E1.rwe usando la letra del disco de la variable DISCO
$rweFilePath = Join-Path -Path $disco -ChildPath "Servicios\MitE1x\cfg\sttr_E1.rwe"

# Comprobar si el archivo sttr_E1.rwe existe
if (-Not (Test-Path $rweFilePath)) {
    Write-Log "El archivo sttr_E1.rwe no se encontró en la ruta: $rweFilePath"
    exit 1
}

# Leer el contenido del archivo
Write-Log "Leyendo el archivo $rweFilePath..."
$content = Get-Content -Path $rweFilePath

# Reemplazar las líneas específicas
$content = $content -replace "LoggingDir=P:\\Servicios\\MitE1x\\Logging\\", "LoggingDir=L:\\Servicios\\MitE1x\\Logging\\"
$content = $content -replace "Host=127.0.0.1", "Host=$acdIp"
$content = $content -replace "IpSrc=.*", "IpSrc=$networkIp"

# Guardar el archivo con las modificaciones
Write-Log "Guardando el archivo actualizado $rweFilePath..."
Set-Content -Path $rweFilePath -Value $content

# Verificar éxito y mostrar mensaje emergente
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show("El archivo install.bat, MitE1x.exe se ejecutaron correctamente, MitE1x.exe fue cerrado y el archivo sttr_E1.rwe ha sido actualizado.", "Ejecución Exitosa", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

# Esperar un momento para asegurarse de que el archivo se haya guardado correctamente
Start-Sleep -Seconds 5

# Volver a iniciar MitE1x.exe
Write-Log "Reiniciando $exePath..."
Start-Process -FilePath $exePath -NoNewWindow
