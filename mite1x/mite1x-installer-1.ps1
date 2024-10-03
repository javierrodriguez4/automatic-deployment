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

# Función para escribir en el archivo de log
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logMessage = "$timestamp - $message"
    try {
        if ($logFilePath) {
            $logDir = Split-Path -Path $logFilePath -Parent
            if (-Not (Test-Path -Path $logDir)) {
                # Si la carpeta de logs no existe, crearla
                New-Item -Path $logDir -ItemType Directory -Force | Out-Null
                Write-Output "Carpeta de logs creada: $logDir"
            }
            if (-Not (Test-Path -Path $logFilePath)) {
                # Si el archivo de log no existe, crear un archivo vacío
                New-Item -Path $logFilePath -ItemType File -Force | Out-Null
                Write-Output "Archivo de log creado: $logFilePath"
            }
            Add-Content -Path $logFilePath -Value $logMessage
        }
    } catch {
        Write-Error "No se pudo escribir en el archivo de log: $_"
    }
}

# Ruta al archivo .env
$envFilePath = ".\.env"

# Leer variables del archivo .env
Write-Log "Leyendo variables del archivo .env..."
$envVariables = Get-EnvVariables -filePath $envFilePath

# Obtener el valor de las variables del archivo .env
$disco = $envVariables["DISCO"]
$carpetas = $envVariables["CARPETAS"].Split(",")
$nexusBaseUrl = $envVariables["NEXUS_BASE_URL"]
$applicationVersion = $envVariables["APLICATION_VERSION"]
$sqlncliUrl = $envVariables["SQLNCLI_URL"]
$driversPathTemplate = $envVariables["DRIVERS_PATH"]
$downloadPath = "$disco\Servicios"
$pathLogs = $envVariables["PATH_LOGS"]

# Construir la ruta completa al archivo de log
$logFilePath = Join-Path -Path $pathLogs -ChildPath "install.log"

# Escribir mensaje inicial en el log
Write-Log "Inicio del script."

# Función para descargar archivos desde una URL sin autenticación
function Download-FileFromUrl {
    param (
        [string]$url,
        [string]$outputPath
    )
    try {
        Write-Log "Intentando descargar desde $url..."
        Invoke-WebRequest -Uri $url -OutFile $outputPath
        Write-Log "Archivo descargado correctamente en $outputPath"
    } catch {
        Write-Log "Error al descargar el archivo: $_"
    }
}

# Función para descomprimir archivos .zip
function Extract-ZipFile {
    param (
        [string]$zipPath,
        [string]$extractPath
    )
    try {
        Write-Log "Descomprimiendo el archivo $zipPath en $extractPath..."
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
        Write-Log "Archivo descomprimido correctamente en $extractPath"
    } catch {
        Write-Log "Error al descomprimir el archivo: $_"
    }
}

# Función para deshabilitar el firewall de Windows
function Disable-WindowsFirewall {
    Write-Log "Deshabilitando el firewall de Windows..."
    try {
        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
        Write-Log "Firewall de Windows deshabilitado."
    } catch {
        Write-Log "Error al deshabilitar el firewall: $_"
    }
}

# Función para instalar un ejecutable
function Install-Executable {
    param (
        [string]$exePath
    )
    if (Test-Path -Path $exePath) {
        Write-Log "Instalando $exePath..."
        Start-Process -FilePath $exePath -ArgumentList "/silent" -Wait
        Write-Log "Instalación completada."
    } else {
        Write-Log "No se encontró el archivo ejecutable en la ruta: $exePath"
    }
}

# Función para renombrar la carpeta descomprimida a MitE1x
function Rename-ToMitE1x {
    param (
        [string]$extractPath
    )
    try {
        # Obtener la lista de carpetas dentro del directorio de extracción
        $folders = Get-ChildItem -Path $extractPath -Directory
        if ($folders.Count -eq 1) {
            $oldFolderPath = $folders[0].FullName
            $newFolderPath = Join-Path -Path $extractPath -ChildPath "MitE1x"
            Rename-Item -Path $oldFolderPath -NewName "MitE1x" -Force
            Write-Log "Carpeta renombrada a MitE1x"
        } else {
            Write-Log "Se esperaba una sola carpeta en $extractPath para renombrar. Carpeta(s) encontrada(s): $($folders.Count)"
        }
    } catch {
        Write-Log "Error al renombrar la carpeta: $_"
    }
}

# Deshabilitar el firewall de Windows
Disable-WindowsFirewall

# Crear las carpetas en el disco especificado
foreach ($folder in $carpetas) {
    $path = "$disco\$folder"
    if (-Not (Test-Path -Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        Write-Log "Carpeta creada: $path"
    } else {
        Write-Log "La carpeta ya existe: $path"
    }
}

# Construir la URL de Nexus para la versión específica de MitE1x
$nexusUrl = "$nexusBaseUrl/MitE1x-$applicationVersion.zip"

# Descargar el archivo desde Nexus
$zipFilePath = "$downloadPath\MitE1x.zip"
Download-FileFromUrl -url $nexusUrl -outputPath $zipFilePath

# Descomprimir el archivo descargado
Extract-ZipFile -zipPath $zipFilePath -extractPath $downloadPath

# Renombrar la carpeta descomprimida a MitE1x
Rename-ToMitE1x -extractPath $downloadPath

# Actualizar la variable driversPath
$driversPath = "$downloadPath\MitE1x\drivers"

# Ruta al archivo VC_redist.x86.exe dentro de la carpeta descomprimida
$vcRedistPath = "$driversPath\VC_redist.x86.exe"

# Instalar el ejecutable VC_redist.x86.exe
Install-Executable -exePath $vcRedistPath

# Ejecutar comandos bcdedit
Write-Log "Ejecutando comandos bcdedit..."
Start-Process -FilePath "bcdedit" -ArgumentList "-set loadoptions disable_integrity_checks" -Wait -NoNewWindow
Start-Process -FilePath "bcdedit" -ArgumentList "-set testsigning on" -Wait -NoNewWindow

# Descargar el archivo sqlncli.msi
$sqlncliPath = "$downloadPath\sqlncli.msi"
Download-FileFromUrl -url $sqlncliUrl -outputPath $sqlncliPath

# Mostrar mensaje para instalación manual
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show("El archivo `sqlncli.msi` está en la ruta $sqlncliPath. Debe instalarse manualmente para que la aplicación MitE1x funcione correctamente. Por favor, haga clic en Aceptar para continuar.", "Instalación Manual Requerida", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

Write-Log "El archivo sqlncli.msi ha sido descargado y está listo para la instalación manual."

# Mostrar mensaje de reinicio y contador de 10 segundos
$confirmRestart = [System.Windows.Forms.MessageBox]::Show("El servidor se va a reiniciar. Presione Aceptar para iniciar un contador de 10 segundos antes del reinicio.", "Reinicio del Servidor", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)

if ($confirmRestart -eq [System.Windows.Forms.DialogResult]::OK) {
    for ($i = 10; $i -ge 0; $i--) {
        Write-Log "Reiniciando en $i segundos..."
        Start-Sleep -Seconds 1
    }
    Restart-Computer -Force
}
