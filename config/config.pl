# =====================================================================
# Configuración para Zimbra Carbonio MR Sync
# =====================================================================

use strict;
use warnings;

my %CONFIG = (
    # --- DIRECTORIOS LOCALES ---
    'local_dir'           => '/opt/zimbra-carbonio-mr-sync',
    'buzones_file'        => 'Buzones.zmp',
    
    # --- SERVIDOR REMOTO (SSH) ---
    'ssh_host'            => 'XXX.XXX.XXX.XXX',
    'ssh_user'            => 'root',
    'ssh_key_file'        => '/root/zmail.key',
    'ssh_port'            => 22,
    # 'ssh_pass'          => '',  # Descomentar si usas contraseña en lugar de clave
    
    # --- CONFIGURACIÓN DE BINARIOS ---
    # SELECCIONA SEGÚN TU SISTEMA:
    # Para ZIMBRA descomenta esta línea:
    # 'zmmailbox_bin'       => '/opt/zimbra/bin/zmmailbox',
    
    # Para CARBONIO descomenta esta línea (por defecto):
    'zmmailbox_bin'       => '/opt/zextras/bin/zmmailbox',
    
    # --- OPCIONES DE CORREO ---
    'backup_format'       => 'tgz',
    'backup_timeout'      => 0,          # 0 = sin timeout
    'restore_timeout'     => 0,          # 0 = sin timeout
    
    # --- CONTROL DE CONCURRENCIA ---
    'max_remote_restore'  => 3,          # Max restauraciones paralelas en servidor remoto
    'delay_between_tasks' => 1,          # Segundos entre tareas
    
    # --- RUTAS DE LOGS ---
    'log_dir'             => 'LOGS',
    'log_prefix'          => 'log_',
    
    # --- OPCIONES DE BACKUP (comentar/descomentar según necesidad) ---
    # Backup FULL (por defecto)
    'backup_query'        => '//?fmt=tgz',
    
    # Backup INCREMENTAL por rango de fechas (descomentar para usar)
    # 'backup_query'      => '//?fmt=tgz&query=after:02/20/2024 before:02/26/2024',
    
    # --- OPCIONES DE RESTAURACIÓN ---
    'restore_resolve'     => 'skip',     # skip, replace, etc.
);

1;  # Importante para que el require funcione

