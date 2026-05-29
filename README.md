# Zimbra Carbonio MR Sync

Herramienta para sincronizar y migrar buzones de correo entre servidores Zimbra y Carbonio.

**Creador:** Roberto Salazar (rcsalazar77@gmail.com)  
**Licencia:** Public Domain

## Requisitos

- Acceso a servidores Zimbra/Carbonio
- Credenciales de administrador
- Conectividad SSH/remota a los servidores

## Estructura del Proyecto

- `scripts/local/`  Script que tiene los correos a sincronizar
- `scripts/remote/` Script que recibe los correos
- `config/`        Archivos de configuración
- `docs/`          Documentación y guías

## Uso

1. Configura las credenciales en `config/`
2. Ejecuta los scripts locales según tu caso de uso
3. Los scripts remotos se ejecutarán en los servidores automáticamente

## Configuración SSH (Sin Contraseña)

### En el Servidor LOCAL (Origen)

**Generar par de claves SSH:**
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

**Copiar la clave pública al servidor REMOTO:**
```bash
scp -P 22 ~/.ssh/id_rsa.pub root@XXX.XXX.XXX.XXX:~/.ssh/authorized_keys
```

### En el Servidor REMOTO (Destino)

**Preparar directorio SSH:**
```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

**Recibir la clave pública:**
```bash
# La clave debe estar en ~/.ssh/authorized_keys
# Verificar que se copió correctamente:
cat ~/.ssh/authorized_keys
```

### Flujo de Autenticación

- `Local.pl` en el servidor local intenta conectarse al servidor remoto por SSH.
- Usa la clave privada `~/.ssh/id_rsa` para autenticarse sin contraseña.
- El servidor remoto comprueba si la clave pública está en `~/.ssh/authorized_keys`.
- Si coincide, la conexión se acepta y se puede ejecutar el script remoto.

### Configuración en config.pl

```perl
'ssh_key_file'  => '/root/.ssh/id_rsa',    # Clave privada en LOCAL
'ssh_host'      => 'XXX.XXX.XXX.XXX',      # IP del REMOTO
'ssh_user'      => 'root',                 # Usuario en REMOTO
'ssh_port'      => 22,
```

### Prueba de Conexión

```bash
# Desde el servidor LOCAL
ssh -i ~/.ssh/id_rsa root@XXX.XXX.XXX.XXX "echo 'Conexión exitosa'"
```

Si aparece "Conexión exitosa" sin pedir contraseña = Funcionando

## Ejecución por cron

Para evitar corridas dobles es recomendable ejecutar `Local.pl` con un lock. El script ya incluye un lock de instancia (`local.lock`) que evita que se inicie otra instancia si ya hay una en ejecución.

Ejemplo de entrada de cron:
```bash
*/30 * * * * flock -n /opt/zimbra-carbonio-mr-sync/local.lock /usr/bin/perl /opt/zimbra-carbonio-mr-sync/scripts/local/Local.pl
```

Si `flock` no está disponible, puedes usar un wrapper simple con un lockfile:
```bash
*/30 * * * * [ -e /opt/zimbra-carbonio-mr-sync/local.lock ] && exit 1; /usr/bin/perl /opt/zimbra-carbonio-mr-sync/scripts/local/Local.pl
```

### Nota sobre concurrencia remota

`Local.pl` también controla cuántas restauraciones remotas pueden ejecutarse a la vez usando `max_remote_restore`.
Esto no evita ejecuciones múltiples de `Local.pl`, pero sí limita la cantidad de procesos `zmmailbox postRestURL` en el servidor remoto.

## Licencia

Public Domain - Libre para usar, modificar y distribuir
