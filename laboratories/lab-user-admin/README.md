# Laboratorio — Administración de Usuarios Linux

## Estructura del proyecto

```
lab-usuarios/
├── Dockerfile          # Imagen Alpine Linux sin GUI
├── useradmin.sh        # Script principal (menú de administración)
├── pwquality.conf      # Política de contraseñas (PAM)
├── motd.sh             # Mensaje de bienvenida del contenedor
├── run_lab.sh          # Script para construir y arrancar el lab
└── README.md           # Esta guía
```

---

## Requisitos en Fedora

```bash
# Instalar Docker (si no está instalado)
sudo dnf install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER   # opcional: usar docker sin sudo
```

---

## Levantar el laboratorio

```bash
# Dar permisos de ejecución
chmod +x run_lab.sh useradmin.sh motd.sh

# Construir y entrar al contenedor
./run_lab.sh
```

Una vez dentro del contenedor, el prompt cambia a `root@lab-linux`.

---

## Usar el administrador de usuarios

```bash
# Dentro del contenedor, ejecutar como root:
useradmin
```

### Menú principal

```
[1]  Listar usuarios del sistema
[2]  Crear nuevo usuario
[3]  Bloquear usuario
[4]  Activar / desbloquear usuario
[5]  Eliminar usuario
[6]  Agregar usuario a sudoers (lab)
[7]  Cambiar contraseña de usuario
[8]  Ver detalles de usuario
[0]  Salir
```

---

## Políticas configuradas

| Parámetro                    | Valor                        |
|------------------------------|------------------------------|
| Contraseña por defecto       | `Temporal@2024`              |
| Días hasta vencimiento       | 90 días                      |
| Advertencia antes de vencer  | 10 días (mensaje personalizado) |
| Bloqueo tras vencimiento     | Inmediato (mismo día)        |
| Cambio en primer login       | Obligatorio                  |
| Mínimo días entre cambios    | 1 día                        |

### Reglas de contraseña (validadas por el script y PAM)

- ❌ Sin espacios en blanco
- ✅ Al menos 1 carácter especial (`!@#$%^&*` etc.)
- ✅ Al menos 1 letra MAYÚSCULA
- ✅ Al menos 1 letra minúscula
- ✅ Al menos 1 dígito
- ✅ Mínimo 8 caracteres

---

## Sudoers del laboratorio

Al agregar un usuario a sudoers (opción 6), **solo** puede ejecutar los comandos del lab:

```
useradd, userdel, usermod, passwd, chage, faillock
```

El archivo se crea en `/etc/sudoers.d/lab_<usuario>` con permisos `440`.

---

## Flujo de primer login de un usuario creado

1. Root crea al usuario → contraseña por defecto asignada.
2. Usuario hace login → sistema lo obliga a cambiar contraseña.
3. El nuevo password debe cumplir las reglas (mayúscula + especial + sin espacios).
4. Desde ese día, el contador de 90 días comienza.
5. A los 80 días → advertencia de vencimiento.
6. Al día 90 → contraseña vencida → cuenta bloqueada automáticamente.

---

## Comandos útiles dentro del contenedor

```bash
# Ver info de vencimiento de un usuario
chage -l <usuario>

# Forzar cambio de contraseña en próximo login
chage -d 0 <usuario>

# Ver usuarios del sistema
cat /etc/passwd | awk -F: '$3>=1000'

# Ver estado de contraseñas (shadow)
cat /etc/shadow
```
