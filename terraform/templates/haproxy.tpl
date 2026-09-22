global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 664 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon
    ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
    ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
    ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

defaults
    log global
    mode http
    option httplog
    option dontlognull
    timeout connect 5000
    timeout client 50000
    timeout server 50000
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

listen stats
    bind *:8080
    stats enable
    stats uri /
    stats refresh 10s
    stats auth admin:securepass

frontend http_in
    bind :80
    mode http
    default_backend webservers

backend webservers
    balance source
    mode http
    cookie JSESSIONID insert indirect nocache

%{ for i, ip in master_nodes ~}
    server m${i + 1} ${ip}:80 check cookie m${i + 1}
%{ endfor ~}

%{ for i, ip in worker_nodes ~}
    server w${i + 1} ${ip}:80 check cookie w${i + 1}
%{ endfor ~}


# =====================================================================
# 1. HANDLE TCP SYSLOG (Port 514)
# =====================================================================
frontend syslog_tcp_in
    bind :514
    mode tcp
    option tcplog
    default_backend syslog_tcp_backend

backend syslog_tcp_backend
    mode tcp
    balance source

%{ for i, ip in master_nodes ~}
    server m${i + 1} ${ip}:30514 check
%{ endfor ~}

%{ for i, ip in worker_nodes ~}
    server w${i + 1} ${ip}:30514 check
%{ endfor ~}

# =====================================================================
# 2. HANDLE UDP SYSLOG (Port 514)
# =====================================================================
log-forward syslog_udp_in
    # dgram-bind is the proper keyword for UDP reception in HAProxy
    dgram-bind :514

    # This sends incoming UDP logs directly to our dedicated log backend
    log backend@syslog_udp_backend local0

backend syslog_udp_backend
    # mode log is a special L4 optimization for handling UDP datagrams
    mode log
    balance roundrobin

    # Note the 'udp@' prefix required for UDP destinations

%{ for i, ip in master_nodes ~}
    server m${i + 1} udp@${ip}:30514
%{ endfor ~}

%{ for i, ip in worker_nodes ~}
    server w${i + 1} udp@${ip}:30514
%{ endfor ~}
