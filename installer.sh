#!/bin/sh

# ==================================================
# SKRIP INSTALASI NODOGSPLASH DENGAN DOWNLOAD GITHUB
# ==================================================

# Konfigurasi URL GitHub
GITHUB_RAW="https://raw.githubusercontent.com/tokektv/nodogsplash/refs/heads/main/"
SPLASH_URL="$GITHUB_RAW/splash.html"
CONFIG_URL="$GITHUB_RAW/nodogsplash"
FALLBACK_MODE=0

echo "[1] UPDATE DAN INSTALASI PAKET"
opkg update
opkg install vsftpd nodogsplash wget

echo "[2] DOWNLOAD FILE DARI GITHUB"
mkdir -p /etc/nodogsplash/htdocs

# Fungsi untuk menangani download
download_file() {
  if wget -q --spider "$1"; then
    wget -O "$2" "$1" && return 0
  else
    echo "ERROR: Gagal mengunduh $1"
    return 1
  fi
}

# Download splash.html
if ! download_file "$SPLASH_URL" "/etc/nodogsplash/htdocs/splash.html"; then
  echo "Menggunakan splash page fallback..."
  cat > /etc/nodogsplash/htdocs/splash.html << 'EOL'
<!DOCTYPE html>
<html>
<head>
    <title>Hotspot Login</title>
    <meta http-equiv="refresh" content="5;url=$authaction?tok=$tok&redir=$redir">
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
    </style>
</head>
<body>
    <h1>Selamat Datang</h1>
    <p>Anda akan otomatis terhubung dalam 5 detik...</p>
</body>
</html>
EOL
  FALLBACK_MODE=1
fi

# Download config
if ! download_file "$CONFIG_URL" "/etc/config/nodogsplash"; then
  echo "Menggunakan config fallback..."
  cat > /etc/config/nodogsplash << 'EOL'
config nodogsplash
    option enabled '1'
    option gatewayinterface 'br-lan'
    option gatewayname 'OpenWRT-Hotspot'
    option splashpage 'splash.html'
    option htmlpath '/etc/nodogsplash/htdocs'
    option clientforcetimeout '30'
    option authentication 'true'
    option redirecturl 'http://www.example.com'
EOL
  FALLBACK_MODE=1
fi

# Set permission
chown nobody:nogroup /etc/nodogsplash/htdocs/splash.html
chmod 644 /etc/nodogsplash/htdocs/splash.html

echo "[3] KONFIGURASI FIREWALL"
cat >> /etc/config/firewall << 'EOL'

config rule
    option name 'NoDogSplash-WAN'
    option src 'wan'
    option proto 'tcp'
    option dest_port '2050'
    option target 'ACCEPT'

config rule
    option name 'NoDogSplash-WWAN'
    option src 'wwan'
    option proto 'tcp'
    option dest_port '2050'
    option target 'ACCEPT'
EOL

echo "[4] RESTART SERVICE"
/etc/init.d/firewall restart
/etc/init.d/nodogsplash restart

# Hasil instalasi
if [ "$FALLBACK_MODE" -eq 1 ]; then
  echo "WARNING: Beberapa file menggunakan fallback lokal"
fi

cat <<EOF

===============================================
INSTALASI SELESAI!
-----------------------------------------------
File yang diunduh dari GitHub:
- splash.html: $(if [ $FALLBACK_MODE -eq 0 ]; then echo "Sukses"; else echo "Gagal (fallback)"; fi)
- config: $(if [ $FALLBACK_MODE -eq 0 ]; then echo "Sukses"; else echo "Gagal (fallback)"; fi)

Akses hotspot:
- http://$(uci get network.lan.ipaddr):2050
===============================================
EOF
