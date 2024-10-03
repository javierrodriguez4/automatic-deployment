# Intervalo en segundos para verificar las sesiones (5 segundos)
$interval = 5

# Obtener el nombre de usuario que está ejecutando el script
$currentSessionId = (quser | Select-String ">" | ForEach-Object { $_ -split "\s+" })[2]

# Función para mostrar todas las sesiones y su estado
function Show-SessionsStatus {
    Write-Host "`nEstado de las sesiones:"
    quser | Select-Object -Skip 1 | ForEach-Object {
        $parts = $_ -split "\s+"
        Write-Host ("Usuario: {0} | ID: {1} | Estado: {2}" -f $parts[0], $parts[2], $parts[3])
    }
}

# Función para cerrar sesiones desconectadas
function Close-InactiveSessions {
    # Ejecutar quser y procesar las sesiones
    $sessions = quser | Select-Object -Skip 1 | ForEach-Object {
        $parts = $_ -split "\s+"
        [PSCustomObject]@{
            Username   = $parts[0]
            SessionId  = $parts[2]
            State      = $parts[3]
        }
    }

    # Filtrar sesiones que están desconectadas y no corresponden al ID de sesión actual
    $filteredSessions = $sessions | Where-Object {
        $_.SessionId -ne $currentSessionId -and $_.State -eq "Desc"
    }

    # Contador de sesiones cerradas
    $closedSessions = @()

    foreach ($session in $filteredSessions) {
        # Cierra la sesión desconectada
        logoff $session.SessionId /server:localhost
        # Añade la sesión cerrada a la lista
        $closedSessions += "$($session.Username)"
    }

    if ($closedSessions.Count -eq 0) {
        Write-Host "No hay sesiones para cerrar."
    } else {
        Write-Host "Se cerraron las siguientes sesiones: $($closedSessions -join ', ')"
    }
}

# Bucle infinito
while ($true) {
    Show-SessionsStatus

    for ($i = 1; $i -le $interval; $i++) {
        Write-Host "Esperando... $i de $interval segundos"
        Start-Sleep -Seconds 1
    }

    # Ejecuta la función para cerrar sesiones inactivas y desconectadas
    Close-InactiveSessions
}
