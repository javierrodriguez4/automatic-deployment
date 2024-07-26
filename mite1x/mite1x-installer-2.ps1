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
Start-Process -FilePath $exePath -Wait -NoNewWindow

# Verificar éxito y mostrar mensaje emergente
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show("El archivo install.bat y MitE1x.exe se ejecutaron correctamente.", "Ejecución Exitosa", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
