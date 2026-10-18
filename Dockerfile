# Servidor virtual de la U.E. Horizonte: Ubuntu Server 24.04 con systemd (para usar systemctl como en una VM).
# La misma imagen sirve para el servidor y para el cliente de pruebas.
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive TZ=America/La_Paz
RUN apt-get update && apt-get install -y --no-install-recommends \
      systemd systemd-sysv dbus sudo tzdata locales ca-certificates \
      iproute2 iputils-ping net-tools curl wget nano vim less \
      openssh-server openssh-client htop tree dnsutils git ufw python3 \
    && sed -i 's/^# *es_BO.UTF-8/es_BO.UTF-8/' /etc/locale.gen && locale-gen \
    && rm -f /etc/update-motd.d/* /usr/sbin/policy-rc.d \
    && find /etc/systemd/system /lib/systemd/system -path '*.wants/*' \
         \( -name '*getty*' -o -name 'systemd-logind*' \) -delete || true \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
