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

# Ruta al archivo .env en el mismo directorio que el script
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFilePath = Join-Path -Path $scriptDir -ChildPath "features.env"

# Leer variables del archivo .env
$envVariables = Get-EnvVariables -filePath $envFilePath

# Obtener la lista de características desde la variable 'FEATURES'
$features = $envVariables["FEATURES"].Split(",")

# Instalar características
foreach ($feature in $features) {
    Write-Output "Instalando $feature..."
    Install-WindowsFeature -Name $feature -IncludeManagementTools
}

Write-Output "Instalación completada."
