#==============================================================================
# HAPROXY CONFIGURATION FOR REDIS ENTERPRISE
# Following official Redis Enterprise documentation
# https://redis.io/docs/latest/operate/rs/networking/cluster-lba-setup/
#==============================================================================

global
    log         /dev/log local0
    log         /dev/log local1 notice
    chroot      /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user        haproxy
    group       haproxy
    daemon
    
    # Default SSL material locations
    ca-base     /etc/ssl/certs
    crt-base    /etc/ssl/private
    
    # SSL configuration following Redis Enterprise guidelines
    ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
    ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
    ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

defaults
    log         global
    mode        tcp
    option      tcplog
    option      dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000

#==============================================================================
# REDIS ENTERPRISE DATABASE FRONTEND/BACKEND (PORT 12000)
#==============================================================================

frontend redis_front_db
    bind        *:12000
    mode        tcp
    default_backend redis_back_db

backend redis_back_db
    mode        tcp
    balance     roundrobin
    option      tcp-check
    tcp-check   connect
%{ for i, node in redis_nodes ~}
    server      redis${i+1} ${node}:12000 check
%{ endfor ~}

#==============================================================================
# REDIS ENTERPRISE API FRONTEND/BACKEND (PORT 9443)
#==============================================================================

frontend redis_front_api
    bind        *:9443
    mode        tcp
    default_backend redis_back_api

backend redis_back_api
    mode        tcp
    balance     roundrobin
    option      tcp-check
    tcp-check   connect
%{ for i, node in redis_nodes ~}
    server      redis${i+1} ${node}:9443 check
%{ endfor ~}

#==============================================================================
# REDIS ENTERPRISE UI FRONTEND/BACKEND (PORT 8443)
#==============================================================================

frontend redis_front_ui
    bind        *:8443
    mode        tcp
    default_backend redis_back_ui

backend redis_back_ui
    mode        tcp
    balance     roundrobin
    option      tcp-check
    tcp-check   connect
%{ for i, node in redis_nodes ~}
    server      redis${i+1} ${node}:8443 check
%{ endfor ~}

#==============================================================================
# HAPROXY STATISTICS PAGE (OPTIONAL)
#==============================================================================

frontend stats
    mode http
    bind *:8404
    stats enable
    stats refresh 10s
    stats uri /stats
    stats show-modules

#==============================================================================
# CONFIGURATION END
#==============================================================================