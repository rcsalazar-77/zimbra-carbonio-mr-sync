# Zimbra Carbonio MR Sync

Herramienta para sincronizar y migrar buzones de correo entre servidores Zimbra y Carbonio.

**Creador:** Roberto Salazar (rcsalazar77@gmail.com)  
**Licencia:** Public Domain

## 📋 Requisitos

- Acceso a servidores Zimbra/Carbonio
- Credenciales de administrador
- Conectividad SSH/remota a los servidores

## 🚀 Estructura del Proyecto

```
scripts/
├── local/      # Script que tiene los correos a sincronizar
└── remote/     # Script que recibe los correos

config/
└── Archivos de configuración

docs/
└── Documentación y guías
```

## 📝 Uso

1. Configura las credenciales en `config/`
2. Ejecuta los scripts locales según tu caso de uso
3. Los scripts remotos se ejecutarán en los servidores automáticamente

## 🔐 Configuración SSH (Sin Contraseña)

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

```
LOCAL                              REMOTO
┌─────────────────────────────┐   ┌──────────────────────┐
│ Local.pl intenta SSH        │   │                      │
│ ├─ ssh -i ~/.ssh/id_rsa     │──→│ Servidor SSH recibe  │
│ │  root@XXX.XXX.XXX.XXX     │   │ ├─ Busca en auth_keys│
│ │                           │   │ ├─ Compara clave pub │
│ └─ Sin pedir contraseña     │   │ └─ ✅ AUTENTICADO    │
│                             │←──│                      │
└─────────────────────────────┘   └──────────────────────┘
```

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

Si aparece "Conexión exitosa" sin pedir contraseña = ✅ Funcionando

## 📄 Licencia

Public Domain - Libre para usar, modificar y distribuir
