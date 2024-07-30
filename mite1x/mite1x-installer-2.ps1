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

# Leer variables del archivo .env
$envVariables = Get-EnvVariables -filePath $envFilePath

# Obtener la ruta de los drivers desde el archivo .env
$driversPath = $envVariables["DRIVERS_PATH"]

# Ruta completa al archivo install.bat
$installBatPath = Join-Path -Path $driversPath -ChildPath "install.bat"

# Cambiar al directorio de los drivers
Write-Output "Cambiando al directorio: $driversPath"
Set-Location -Path $driversPath

# Confirmar el cambio de directorio
Write-Output "Directorio actual: $(Get-Location)"

# Ejecutar install.bat
Write-Output "Ejecutando $installBatPath en el directorio $driversPath..."
Start-Process -FilePath $installBatPath -Wait -NoNewWindow

# Verificar si el archivo MitE1x.exe está en la ruta correcta
$exePath = Join-Path -Path (Split-Path -Parent $driversPath) -ChildPath "MitE1x.exe"

# Ejecutar MitE1x.exe
Write-Output "Ejecutando $exePath..."
$process = Start-Process -FilePath $exePath -PassThru

# Esperar a que MitE1x.exe inicie (esto puede necesitar ajustarse dependiendo del tiempo de inicio de la aplicación)
Start-Sleep -Seconds 10

# Cerrar MitE1x.exe
Write-Output "Cerrando $exePath..."
$process | Stop-Process -Force

# Obtener IP de la variable ACD_IP del archivo .env
$acdIp = $envVariables["ACD_IP"]

# Obtener IP de la interfaz de red de Windows 10
$networkIp = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.Address -ne "127.0.0.1" }).IPAddress

# Ruta al archivo sttr_E1.rwe
$rweFilePath = "P:\Servicios\MitE1x\cfg\sttr_E1.rwe"

# Leer el contenido del archivo
$content = Get-Content -Path $rweFilePath

# Reemplazar las líneas específicas
$content = $content -replace "LoggingDir=P:\\Servicios\\MitE1x\\Logging\\", "LoggingDir=L:\\Servicios\\MitE1x\\Logging\\"
$content = $content -replace "Host=127.0.0.1", "Host=$acdIp"
$content = $content -replace "IpSrc=.*", "IpSrc=$networkIp"

# Guardar el archivo con las modificaciones
Set-Content -Path $rweFilePath -Value $content

# Verificar éxito y mostrar mensaje emergente
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show("El archivo install.bat, MitE1x.exe se ejecutaron correctamente, MitE1x.exe fue cerrado y el archivo sttr_E1.rwe ha sido actualizado.", "Ejecución Exitosa", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

# Esperar un momento para asegurarse de que el archivo se haya guardado correctamente
Start-Sleep -Seconds 5

# Volver a iniciar MitE1x.exe
Write-Output "Reiniciando $exePath..."
Start-Process -FilePath $exePath -NoNewWindow
