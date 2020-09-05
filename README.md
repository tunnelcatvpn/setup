# TunnelCat VPN Setup Script

# Prerequisite
1. Linux VPS
2. Ubuntu/Debian OS
3. Domain Setup for Protocol G

# Setup Domain for Protocol G
Follow this [tutorial](https://docs.tcat.me/server/slowdns#setup-ns-records-with-cloudflare)

# Install OpenVPN
I recommend to use [https://github.com/Nyr/openvpn-install](https://github.com/Nyr/openvpn-install)

Install OpenVPN using this script:
```
wget https://git.io/vpn -O openvpn-install.sh && bash openvpn-install.sh
```

# Running the Script
Run this command and follow the installation:
```
wget https://github.com/tunnelcatvpn/setup/raw/master/setup.sh -O setup.sh && sudo bash setup.sh
```

# Uninstall
Run this command:
```
wget https://raw.githubusercontent.com/tunnelcatvpn/setup/master/uninstall.sh -O uninstall.sh && sudo bash uninstall.sh
```