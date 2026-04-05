# ============================================================
#  Dockerfile — Laboratorio de Administración de Usuarios
#  Base: Alpine Linux (liviana, sin GUI)
# ============================================================
FROM alpine:3.19

LABEL maintainer="Laboratorio Linux"
LABEL description="Contenedor para laboratorio de administración de usuarios"

# ── Instalar paquetes necesarios ─────────────────────────────
RUN apk update && apk add --no-cache \
    bash \
    shadow \
    sudo \
    util-linux \
    linux-pam \
    openssl \
    procps \
    tzdata \
    && rm -rf /var/cache/apk/*

# ── Zona horaria ─────────────────────────────────────────────
ENV TZ=America/Bogota
RUN cp /usr/share/zoneinfo/America/Bogota /etc/localtime && \
    echo "America/Bogota" > /etc/timezone

# ── Copiar el script de administración ──────────────────────
COPY useradmin.sh /usr/local/bin/useradmin
RUN chmod +x /usr/local/bin/useradmin

# ── Copiar configuración de PAM para calidad de contraseñas ─
COPY pwquality.conf /etc/security/pwquality.conf

# ── Configurar login.defs con las políticas del lab ──────────
RUN sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/'  /etc/login.defs && \
    sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   1/'   /etc/login.defs && \
    sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   10/'  /etc/login.defs

# ── Crear directorio para sudoers del lab ────────────────────
RUN mkdir -p /etc/sudoers.d && \
    echo "#includedir /etc/sudoers.d" >> /etc/sudoers

# ── Mensaje de bienvenida al iniciar el contenedor ───────────
COPY motd.sh /etc/profile.d/motd.sh
RUN chmod +x /etc/profile.d/motd.sh

# ── Shell por defecto ────────────────────────────────────────
SHELL ["/bin/bash", "-c"]

CMD ["/bin/bash", "--login"]
