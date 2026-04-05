#!/bin/bash
# /etc/profile.d/motd.sh — Mensaje de bienvenida del laboratorio

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

echo -e "${CYAN}"
echo "  ╔═══════════════════════════════════════════════════╗"
echo "  ║     LABORATORIO — Administración de Usuarios      ║"
echo "  ║              Linux (Alpine Container)             ║"
echo "  ╚═══════════════════════════════════════════════════╝"
echo -e "${RESET}"
echo -e "  ${BOLD}Comando principal:${RESET}  ${GREEN}sudo useradmin${RESET}   (requiere root)"
echo -e "  ${BOLD}Ayuda rápida:${RESET}       ${CYAN}man useradmin${RESET} / --help"
echo -e "  ${YELLOW}  Solo el superusuario puede ejecutar acciones de admin.${RESET}"
echo ""
