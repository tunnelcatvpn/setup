#!/bin/bash
# file: setup.sh

DISTRO=`awk '/^ID=/' /etc/*-release | awk -F'=' '{ print tolower($2) }'`
SERVER_IP=`ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p'`

# Welcome Message
echo 'Welcome to TunnelCat VPN Setup Script'
echo 'Script Version: 0.1'
echo 'Updated on: 9/5/2020'

# Verify Distro
if [[ $DISTRO != "ubuntu" || $DISTRO != "debian" ]]; then
	echo 'This script works only on Debian/Ubuntu OS'
	exit 1
fi

# Check if root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Read Input
read -e -p 'Input your Server IP: ' -i '$SERVER_IP' SERVER_IP
read -e -p 'Input OpenVPN TCP Port: ' -i '1194' OPENVPN_PORT
read -e -p 'Input Privoxy Port: ' -i '8080' PRIVOXY_PORT
read -e -p 'Input ohpserver Port: ' -i '80' OHP_PORT
read -e -p 'Input stunnel Port: ' -i '443' STUNNEL_PORT
read -e -p 'Input DNS Tunnel Domain: ' -i 'dns.tunnel.example.com' DNS_TUNNEL_DOMAIN

# Check input
echo 'Checking Input...'
if ![[ $SERVER_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	echo 'Server IP is invalid'
	exit 1
fi

if ![[ $OPENVPN_PORT =~ '^[0-9]+$' || $OHP_PORT =~ '^[0-9]+$' || $PRIVOXY_PORT =~ '^[0-9]+$' || $STUNNEL_PORT =~ '^[0-9]+$' ]]; then
	echo 'Port is invalid'
	exit 1
fi

echo 'Proceeding with the installation of dependencies'

# Install Dependencies
echo 'Installing Dependencies'
DEBIAN_FRONTEND=noninteractive apt install -y resolvconf privoxy stunnel unzip iproute2 dns2tcp
echo 'Dependencies Installed!' 

# Install TunnelCat VPN Software
echo 'Installing ohpserver'
wget https://github.com/lfasmpao/open-http-puncher/releases/download/0.1/ohpserver-linux32.zip
unzip ohpserver-linux32.zip
rm ohpserver-linux32.zip
mv ohpserver /usr/local/bin/
chmod +x /usr/local/bin/ohpserver

# Setup Privoxy
echo 'Setting up Privoxy'
cat <<EOF > /etc/privoxy/config
user-manual /usr/share/doc/privoxy/user-manual
confdir /etc/privoxy
logdir /var/log/privoxy
actionsfile match-all.action
actionsfile default.action
actionsfile user.action
filterfile default.filter
filterfile user.filter
logfile logfile
listen-address  :$PRIVOXY_PORT
toggle 1
enable-remote-toggle  0
enable-remote-http-toggle  0
enable-edit-actions 0
enforce-blocks 0
buffer-limit 4096
enable-proxy-authentication-forwarding 0
forwarded-connect-retries  0
accept-intercepted-requests 0
allow-cgi-request-crunching 0
split-large-forms 0
keep-alive-timeout 5
tolerate-pipelining 1
socket-timeout 300
EOF

cat <<EOF > /etc/privoxy/user.action
{ +block }
/

{ -block }
*.tcat.me
127.0.0.1
$SERVER_IP
EOF


# Setup Stunnel
echo 'Setting up Stunnel'
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4

cat <<EOF > /etc/stunnel/stunnel.conf
client = no
[ovpn]
accept = 0.0.0.0:$STUNNEL_PORT
connect = $SERVER_IP:$OPENVPN_PORT
cert = /etc/stunnel/stunnel.pem
EOF

cat <<EOF > /etc/stunnel/stunnel.pem
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDqa9qPx+BD8hA4
nIMTW3wDF4OC/DrwNS1ooUAh8dsktBq1uFy1w4dDxk8cqy4mvtMx/t2LHY2vLc4Z
u4XE9f5p+9uwcrlcdeKTWFwMtWdgZVHwkPY5ACyGgfoE2392GABr+a0Lfc+sMpdm
p7Pdu3NXGIFEY0UbRss/7RgAEVVOwmwo94cVGDEfCeMOsHJH9AGvT/d8L5KH1rkq
HQcnEAkujAb7W8bykwBKUPIriNzF4zQXq5RrQgQm3Wi3y4KzPqJWDQMmcIfzajvt
DBZ3lsusU8Q1TVsA6ony8tN9YCGuGtPNpe2E8T5iScP9wOdWljHUFfMIZUELk1FD
VF/xIg79AgMBAAECggEAF1X9P+rpzFnAe6I4+ihVRAmHMfbh9x+UEaJbvAVTh2fW
cNiVghKg2IJZRcVUps7AP23bqAmdHR82MSGVw3Gpjetgh0QkZ6vkjj5xi2JTlCkB
6yzDFhGKXSl7NhiTq7Hf+N+19jrj/YRbxgBTy3LpnHX4CFLJglmdyhNUHE2dbGWF
iU/N/M7mmkRAtT2hWsxuhZT48U1UH5y2LNyQIol8e7XqUpXcgWTU/4uWOSdV7tLb
XblQJiXDBxVl/HwuGcYcpjpinKRNU6DTtTmelH+w5ztpJo6OGJ7MUqcnpXysaLzx
JJWmT+6ccQVkNBvHa+MQSzYHNS72w2GXKRVDBvZkEQKBgQD9qO0tBdMenuD8/tUR
tkJ9H2DOJ7rPcoh9O969g6Cjt6eRJDnwdBAVm72mgHQH7JYDFakKREzhYyAGp4hs
haSEh37CegHNAlqxe08XVORiO2WJr2jXHHqwLA0Ru3JI8F6BBPZJ/V7kn7DNBSTY
bzTyqXfeAAbLaM7CbQvrk15MYwKBgQDslX2+fUNebEVZNhArqDm005p2Joj0LKji
34nnGoDbc1hfiFTim/eZrSPJDKYN5auYQ5eTv3JXyJa6q+FbUgIVyeKBsVdEIGC2
8Kp7rYQ2ADjE4jIvKrgr92sU66roYbRm0JTXk+9poJ9aHD1uMOVmKPTxRukOa/mq
0+l9dgmlHwKBgQCcUjJ4AJLu1/LHdzRPygaHnYLHCWzy0x6SLwdBu5CP1GqL48th
B+Wxq1zg82COUZrRI9Qc46KNc80UzMIiPun4UpgnuZDKipzhq6A+PK7SatBUXak6
h+6EC2Gyf9YaZSeYUzqEtoR4WIFYl8bxKvdyZEXeph2J1Xk2EIW8FAGVCQKBgQCD
KrKnnS1vuVmNh4LZoZA06Ci4Hs9JiUUtW8BKSBBvGvlBJgXiCZTyN+MiQYgDJnXH
mpn8SWVstAKVhlwQVFxhlielvhvi4oycgLwUi/REOEVBKyOlsOqhPbC5zZtY8Wqi
ojwTdaqEBpCy1ftdD3Dv/f8nkif+XfDzPEA01e+tAwKBgDonV6mg7pNEo03TbRi8
p5jziixgDJl0cUCjJ9wbO1ue37KgvbAxyBKeHGYYQnthqHZPZFFUDguys/APBwaS
RHTXyLxb3FLfdJfkhFjJCudl2ySvEHFUsE4VZ96MKmN2QcvdZfOaoJIG5B2RMtJO
whQXUdy185eIaDFl0N29AxWG
-----END PRIVATE KEY-----
-----BEGIN CERTIFICATE-----
MIIDfzCCAmegAwIBAgIJANCVSZB1ur70MA0GCSqGSIb3DQEBCwUAMFYxCzAJBgNV
BAYTAlBIMQwwCgYDVQQIDANOQ1IxFjAUBgNVBAcMDVRvbmRvLCBNYW5pbGExITAf
BgNVBAoMGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDAeFw0xODA2MTgxMzIzMTRa
Fw0yODA2MTUxMzIzMTRaMFYxCzAJBgNVBAYTAlBIMQwwCgYDVQQIDANOQ1IxFjAU
BgNVBAcMDVRvbmRvLCBNYW5pbGExITAfBgNVBAoMGEludGVybmV0IFdpZGdpdHMg
UHR5IEx0ZDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOpr2o/H4EPy
EDicgxNbfAMXg4L8OvA1LWihQCHx2yS0GrW4XLXDh0PGTxyrLia+0zH+3Ysdja8t
zhm7hcT1/mn727ByuVx14pNYXAy1Z2BlUfCQ9jkALIaB+gTbf3YYAGv5rQt9z6wy
l2ans927c1cYgURjRRtGyz/tGAARVU7CbCj3hxUYMR8J4w6wckf0Aa9P93wvkofW
uSodBycQCS6MBvtbxvKTAEpQ8iuI3MXjNBerlGtCBCbdaLfLgrM+olYNAyZwh/Nq
O+0MFneWy6xTxDVNWwDqifLy031gIa4a082l7YTxPmJJw/3A51aWMdQV8whlQQuT
UUNUX/EiDv0CAwEAAaNQME4wHQYDVR0OBBYEFFZDktqWQVuxUs01NN0mGB9BsiU9
MB8GA1UdIwQYMBaAFFZDktqWQVuxUs01NN0mGB9BsiU9MAwGA1UdEwQFMAMBAf8w
DQYJKoZIhvcNAQELBQADggEBAI4zRWJX3JOGr7UaGIVIFMyNUReFgd58aAsEEkUe
p50IyBLBds27GxTl1/L7BcpWv2fPHKpYHw5A/mtFiXacc3/S89KlAYiT3aH6mV6p
SNAZTOEGCeAa/DGrhQGitE9JLnXKjv62U2cUJoyNDIWqIDj8Usiq61UhkKcc3wjl
TM1A3+9hRUl+DTf5bIwbfXxHfC3y4F27ymhh8PUrju8aCcTBDTXicagbDb/4CflP
V9honTqGLihXBEtQFGfP3nH4dwMkS4pQDgms5xEsgoJfqO4YEe8OkybppL6M8StV
v3dDyLcgz+ajGzwyTSn7Dc2j5nJI2+BLlhh6Lx2cNtrUQcg=
-----END CERTIFICATE-----
EOF

# Setup ohpserver
echo 'Setup ohpserver'
cat <<EOF > /etc/systemd/system/ohpserver.service
[Unit]
Description=Daemonize OpenHTTP Puncher Server
Wants=network.target
After=network.target

[Service]
ExecStart=/usr/local/bin/ohpserver -port $OHP_PORT -proxy 127.0.0.1:$PRIVOXY_PORT -tunnel $SERVER_IP:$OPENVPN_PORT
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF

echo 'Setup dns2tcp'
mkdir /etc/dns2tcp/
cat <<EOF > /etc/dns2tcp/server.conf
listen = 0.0.0.0
port = 53
user = nobody
chroot = /tmp
pid_file = /var/run/dns2tcp.pid
domain = $DNS_TUNNEL_DOMAIN
resources = ovpn:$SERVER_IP:$OPENVPN_PORT
EOF

# Start Services
echo 'Running Services'
echo "nameserver 8.8.8.8" > /etc/resolvconf/resolv.conf.d/head
systemctl daemon-reload
systemctl restart resolvconf
systemctl restart stunnel4
systemctl restart privoxy
systemctl start ohpserver
systemctl stop systemd-resolved
dns2tcpd -d 1 -f /etc/dns2tcp/server.conf

# Enable on boot
echo 'Start services on boot'
systemctl enable stunnel4
systemctl enable privoxy
systemctl enable ohpserver

# Installation Completed
echo 'Installation Completed!'
echo ''
echo ''
echo 'Installation Information'
echo '##############################'
echo 'Server IP: $SERVER_IP'
echo 'OpenVPN Port: $OPENVPN_PORT'
echo 'HTTP Port: $PRIVOXY_PORT'
echo 'OHP Port: $OHP_PORT'
echo 'stunnel Port: $STUNNEL_PORT'
echo 'DNS Tunnel Domain: $DNS_TUNNEL_DOMAIN'
echo '##############################'