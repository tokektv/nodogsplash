#!/bin/sh

# =============================================
# AUTO INSTALL NODOGSPLASH + PRESERVE PERMISSIONS
# =============================================

echo "[1] Menginstall nodogsplash..."
opkg update
opkg install nodogsplash luci-app-nodogsplash

echo "[2] Membuat direktori..."
mkdir -p /etc/nodogsplash/htdocs

echo "[3] Mengunduh splash.html custom..."
wget -O /etc/nodogsplash/htdocs/splash.html "https://raw.githubusercontent.com/username/repo/main/splash.html"

echo "[4] Mengunduh config..."
wget -O /etc/config/nodogsplash "https://raw.githubusercontent.com/username/repo/main/nodogsplash-config"

echo "[5] Mengatur permissions..."
chown nobody:nogroup /etc/nodogsplash/htdocs/splash.html
chmod 644 /etc/nodogsplash/htdocs/splash.html

echo "[6] Menjalankan service..."
/etc/init.d/nodogsplash restart

echo "Selesai! Splash page sudah terpasang."
