#!/bin/bash
# ============================================================
#  useradmin.sh — Administrador de usuarios Linux
#  Laboratorio de Administración de Sistemas
#  Solo puede ser ejecutado por root (superusuario)
# ============================================================

# ── Colores ──────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

# ── Constantes de política de contraseñas ────────────────────
DEFAULT_PASS="Temporal@2024"   # contraseña asignada al crear usuario
PASS_MAX_DAYS=90               # días hasta vencer la contraseña
PASS_WARN_DAYS=10              # días de advertencia antes de vencer
PASS_MIN_DAYS=1                # mínimo de días entre cambios
PASS_INACTIVE=0                # bloqueo inmediato tras vencimiento (0 = mismo día)

# ── Comandos permitidos en sudoers para usuarios del lab ─────
LAB_SUDOERS_CMDS="/usr/sbin/useradd,/usr/sbin/userdel,/usr/sbin/usermod,\
/usr/bin/passwd,/usr/sbin/chage,/bin/grep /etc/passwd,\
/usr/sbin/faillock,/bin/cat /etc/login.defs"

# ── Archivo de configuración PAM para calidad de contraseña ──
PAM_PWQUALITY="/etc/security/pwquality.conf"

# ============================================================
#  UTILIDADES
# ============================================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}✖  Este script debe ejecutarse como root (superusuario).${RESET}"
        exit 1
    fi
}

press_enter() {
    echo -e "\n${CYAN}Presiona [Enter] para continuar...${RESET}"
    read -r
}

header() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║        ADMINISTRADOR DE USUARIOS — Linux Lab             ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

user_exists() {
    id "$1" &>/dev/null
}

# ============================================================
#  CONFIGURACIÓN INICIAL DEL SISTEMA
# ============================================================

configure_pwquality() {
    # En Alpine la validación es 100% por el script (sin pam-pwquality)
    : # no-op
}

# ============================================================
#  VALIDAR CONTRASEÑA (reglas del laboratorio)
# ============================================================

validate_password() {
    local pass="$1"
    local ok=true

    if [[ "$pass" =~ [[:space:]] ]]; then
        echo -e "${RED}  ✖ No debe contener espacios en blanco.${RESET}"
        ok=false
    fi
    if ! [[ "$pass" =~ [A-Z] ]]; then
        echo -e "${RED}  ✖ Debe contener al menos una letra MAYÚSCULA.${RESET}"
        ok=false
    fi
    if ! [[ "$pass" =~ [[:punct:]] ]]; then
        echo -e "${RED}  ✖ Debe contener al menos un carácter especial (!@#\$%^&*...).${RESET}"
        ok=false
    fi
    if [[ ${#pass} -lt 8 ]]; then
        echo -e "${RED}  ✖ Debe tener al menos 8 caracteres.${RESET}"
        ok=false
    fi

    $ok
}

# ============================================================
#  1. LISTAR USUARIOS
# ============================================================

list_users() {
    header
    echo -e "${BOLD}▸ USUARIOS DEL SISTEMA (UID ≥ 1000, sin nobody)${RESET}\n"
    printf "%-20s %-8s %-12s %-30s\n" "USUARIO" "UID" "ESTADO" "COMENTARIO"
    printf "%-20s %-8s %-12s %-30s\n" "-------" "---" "------" "----------"

    while IFS=: read -r uname _ uid _ gecos _ _; do
        [[ $uid -lt 1000 || "$uname" == "nobody" ]] && continue

        # Estado: bloqueado si passwd empieza con ! o si cuenta está expirada
        local status
        local shadow_pass
        shadow_pass=$(getent shadow "$uname" | cut -d: -f2)
        if [[ "$shadow_pass" == !* || "$shadow_pass" == "!" ]]; then
            status="${RED}BLOQUEADO${RESET}"
        else
            status="${GREEN}ACTIVO${RESET}"
        fi

        printf "%-20s %-8s %-12b %-30s\n" "$uname" "$uid" "$status" "${gecos:-(sin descripción)}"

        # Información de vencimiento
        local exp_info
        exp_info=$(chage -l "$uname" 2>/dev/null | grep "Password expires" | cut -d: -f2 | xargs)
        echo -e "   ${CYAN}↳ Contraseña vence:${RESET} $exp_info"
    done < /etc/passwd

    press_enter
}

# ============================================================
#  2. CREAR USUARIO
# ============================================================

create_user() {
    header
    echo -e "${BOLD}▸ CREAR NUEVO USUARIO${RESET}\n"

    read -rp "Nombre de usuario: " uname
    uname=$(echo "$uname" | tr '[:upper:]' '[:lower:]' | tr -d ' ')

    if [[ -z "$uname" ]]; then
        echo -e "${RED}Nombre de usuario no puede estar vacío.${RESET}"
        press_enter; return
    fi

    if user_exists "$uname"; then
        echo -e "${RED}El usuario '$uname' ya existe.${RESET}"
        press_enter; return
    fi

    read -rp "Nombre completo (comentario): " fullname
    read -rp "Shell [/bin/bash]: " ushell
    ushell=${ushell:-/bin/bash}

    # Crear usuario con home directory
    if useradd -m -c "$fullname" -s "$ushell" "$uname"; then
        echo -e "${GREEN}✔ Usuario '$uname' creado.${RESET}"
    else
        echo -e "${RED}✖ Error al crear el usuario.${RESET}"
        press_enter; return
    fi

    # Asignar contraseña por defecto
    echo "$uname:$DEFAULT_PASS" | chpasswd
    echo -e "${YELLOW}→ Contraseña por defecto asignada: ${BOLD}$DEFAULT_PASS${RESET}"

    # Política de contraseña: vence en 90 días, advertencia 10 días antes,
    # bloqueo inmediato al vencer, debe cambiarla en el primer login
    chage -M "$PASS_MAX_DAYS" \
          -W "$PASS_WARN_DAYS" \
          -I "$PASS_INACTIVE" \
          -m "$PASS_MIN_DAYS" \
          -d 0 \
          "$uname"
    # -d 0 fuerza el cambio de contraseña en el primer inicio de sesión

    echo -e "${GREEN}✔ Políticas de contraseña configuradas.${RESET}"
    echo -e "   ${CYAN}• Vence en:${RESET} $PASS_MAX_DAYS días"
    echo -e "   ${CYAN}• Advertencia:${RESET} $PASS_WARN_DAYS días antes de vencer"
    echo -e "   ${CYAN}• Bloqueo tras vencimiento:${RESET} inmediato"
    echo -e "   ${CYAN}• Cambio obligatorio en primer login:${RESET} Sí"

    press_enter
}

# ============================================================
#  3. BLOQUEAR USUARIO
# ============================================================

lock_user() {
    header
    echo -e "${BOLD}▸ BLOQUEAR USUARIO${RESET}\n"

    read -rp "Nombre de usuario a bloquear: " uname

    if ! user_exists "$uname"; then
        echo -e "${RED}El usuario '$uname' no existe.${RESET}"
        press_enter; return
    fi

    if [[ "$uname" == "root" ]]; then
        echo -e "${RED}✖ No se puede bloquear al usuario root.${RESET}"
        press_enter; return
    fi

    usermod -L "$uname"
    echo -e "${YELLOW}✔ Usuario '$uname' BLOQUEADO.${RESET}"
    echo -e "   (La contraseña fue desactivada; el home y archivos se conservan)"

    press_enter
}

# ============================================================
#  4. ACTIVAR / DESBLOQUEAR USUARIO
# ============================================================

unlock_user() {
    header
    echo -e "${BOLD}▸ ACTIVAR / DESBLOQUEAR USUARIO${RESET}\n"

    read -rp "Nombre de usuario a activar: " uname

    if ! user_exists "$uname"; then
        echo -e "${RED}El usuario '$uname' no existe.${RESET}"
        press_enter; return
    fi

    usermod -U "$uname"
    echo -e "${GREEN}✔ Usuario '$uname' ACTIVADO.${RESET}"

    # Renovar expiración de contraseña desde hoy
    chage -M "$PASS_MAX_DAYS" \
          -W "$PASS_WARN_DAYS" \
          -I "$PASS_INACTIVE" \
          -m "$PASS_MIN_DAYS" \
          -d "$(date +%Y-%m-%d)" \
          "$uname"

    echo -e "   ${CYAN}Políticas de contraseña renovadas.${RESET}"
    press_enter
}

# ============================================================
#  5. ELIMINAR USUARIO
# ============================================================

delete_user() {
    header
    echo -e "${BOLD}▸ ELIMINAR USUARIO${RESET}\n"

    read -rp "Nombre de usuario a eliminar: " uname

    if ! user_exists "$uname"; then
        echo -e "${RED}El usuario '$uname' no existe.${RESET}"
        press_enter; return
    fi

    if [[ "$uname" == "root" ]]; then
        echo -e "${RED}✖ No se puede eliminar al usuario root.${RESET}"
        press_enter; return
    fi

    read -rp "¿Eliminar también el directorio home y archivos? [s/N]: " del_home

    if [[ "$del_home" =~ ^[sS]$ ]]; then
        userdel -r "$uname" 2>/dev/null
        echo -e "${RED}✔ Usuario '$uname' eliminado (con home y archivos).${RESET}"
    else
        userdel "$uname" 2>/dev/null
        echo -e "${YELLOW}✔ Usuario '$uname' eliminado (home conservado).${RESET}"
    fi

    # Eliminar de sudoers si existía entrada
    local sudoers_file="/etc/sudoers.d/lab_$uname"
    if [[ -f "$sudoers_file" ]]; then
        rm -f "$sudoers_file"
        echo -e "   ${CYAN}Entrada de sudoers eliminada.${RESET}"
    fi

    press_enter
}

# ============================================================
#  6. AGREGAR A SUDOERS (solo comandos del laboratorio)
# ============================================================

add_sudoers() {
    header
    echo -e "${BOLD}▸ AGREGAR USUARIO A SUDOERS (comandos del lab)${RESET}\n"

    read -rp "Nombre de usuario: " uname

    if ! user_exists "$uname"; then
        echo -e "${RED}El usuario '$uname' no existe.${RESET}"
        press_enter; return
    fi

    local sudoers_file="/etc/sudoers.d/lab_$uname"

    if [[ -f "$sudoers_file" ]]; then
        echo -e "${YELLOW}El usuario '$uname' ya tiene entrada en sudoers del lab.${RESET}"
        press_enter; return
    fi

    # Crear archivo sudoers con permisos correctos
    cat > "$sudoers_file" <<EOF
# Sudoers del laboratorio para: $uname
# Generado por useradmin.sh el $(date)
#
# Este usuario puede ejecutar ÚNICAMENTE los comandos de administración
# de usuarios definidos en este laboratorio.

$uname ALL=(root) NOPASSWD: /usr/sbin/useradd, \\
                             /usr/sbin/userdel, \\
                             /usr/sbin/usermod, \\
                             /usr/bin/passwd, \\
                             /usr/sbin/chage, \\
                             /usr/bin/faillock, \\
                             /usr/bin/grep /etc/passwd, \\
                             /usr/bin/cat /etc/login.defs
EOF

    chmod 440 "$sudoers_file"

    # Verificar sintaxis
    if visudo -cf "$sudoers_file" &>/dev/null; then
        echo -e "${GREEN}✔ Usuario '$uname' agregado a sudoers del lab.${RESET}"
        echo -e "   Comandos permitidos:"
        echo -e "   ${CYAN}useradd, userdel, usermod, passwd, chage, faillock${RESET}"
    else
        echo -e "${RED}✖ Error en la sintaxis del archivo sudoers. Revirtiendo...${RESET}"
        rm -f "$sudoers_file"
    fi

    press_enter
}

# ============================================================
#  7. CAMBIAR CONTRASEÑA DE USUARIO
# ============================================================

change_password() {
    header
    echo -e "${BOLD}▸ CAMBIAR CONTRASEÑA DE USUARIO${RESET}\n"

    read -rp "Nombre de usuario: " uname

    if ! user_exists "$uname"; then
        echo -e "${RED}El usuario '$uname' no existe.${RESET}"
        press_enter; return
    fi

    while true; do
        read -rsp "Nueva contraseña: " newpass; echo
        read -rsp "Confirmar contraseña: " newpass2; echo

        if [[ "$newpass" != "$newpass2" ]]; then
            echo -e "${RED}✖ Las contraseñas no coinciden.${RESET}"
            continue
        fi

        if validate_password "$newpass"; then
            echo "$uname:$newpass" | chpasswd
            echo -e "${GREEN}✔ Contraseña actualizada para '$uname'.${RESET}"

            # Renovar fecha de inicio de las políticas
            chage -d "$(date +%Y-%m-%d)" "$uname"
            break
        else
            echo -e "${YELLOW}Por favor ingresa una contraseña que cumpla los requisitos.${RESET}\n"
        fi
    done

    press_enter
}

# ============================================================
#  8. VER DETALLES DE USUARIO
# ============================================================

show_user_detail() {
    header
    echo -e "${BOLD}▸ DETALLES DE USUARIO${RESET}\n"

    read -rp "Nombre de usuario: " uname

    if ! user_exists "$uname"; then
        echo -e "${RED}El usuario '$uname' no existe.${RESET}"
        press_enter; return
    fi

    echo -e "\n${CYAN}── Información de cuenta ──${RESET}"
    id "$uname"

    echo -e "\n${CYAN}── Política de contraseña (chage) ──${RESET}"
    chage -l "$uname"

    echo -e "\n${CYAN}── Grupos ──${RESET}"
    groups "$uname"

    local sudoers_file="/etc/sudoers.d/lab_$uname"
    if [[ -f "$sudoers_file" ]]; then
        echo -e "\n${YELLOW}★ Este usuario tiene permisos de sudoers del lab.${RESET}"
    fi

    press_enter
}

# ============================================================
#  MENÚ PRINCIPAL
# ============================================================

main_menu() {
    while true; do
        header
        echo -e "  ${BOLD}Sesión actual:${RESET} $(whoami) | $(date '+%d/%m/%Y %H:%M')\n"
        echo -e "  ${CYAN}[1]${RESET}  Listar usuarios del sistema"
        echo -e "  ${CYAN}[2]${RESET}  Crear nuevo usuario"
        echo -e "  ${CYAN}[3]${RESET}  Bloquear usuario"
        echo -e "  ${CYAN}[4]${RESET}  Activar / desbloquear usuario"
        echo -e "  ${CYAN}[5]${RESET}  Eliminar usuario"
        echo -e "  ${CYAN}[6]${RESET}  Agregar usuario a sudoers (lab)"
        echo -e "  ${CYAN}[7]${RESET}  Cambiar contraseña de usuario"
        echo -e "  ${CYAN}[8]${RESET}  Ver detalles de usuario"
        echo -e "  ${RED}[0]${RESET}  Salir\n"
        read -rp "  Selecciona una opción: " opt

        case "$opt" in
            1) list_users ;;
            2) create_user ;;
            3) lock_user ;;
            4) unlock_user ;;
            5) delete_user ;;
            6) add_sudoers ;;
            7) change_password ;;
            8) show_user_detail ;;
            0) echo -e "\n${GREEN}Hasta luego.${RESET}\n"; exit 0 ;;
            *) echo -e "${RED}Opción inválida.${RESET}"; sleep 1 ;;
        esac
    done
}

# ============================================================
#  ENTRY POINT
# ============================================================

check_root
configure_pwquality
main_menu
