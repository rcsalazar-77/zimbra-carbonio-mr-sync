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

## 📄 Licencia

Public Domain - Libre para usar, modificar y distribuir
