#!/bin/bash

# ==========================================
# NexoHost VPS Hardware Spoof Setup
# Professional Edition
# Owner: InfinityForge
# ==========================================

clear

G='\033[0;32m'
R='\033[0;31m'
B='\033[0;34m'
Y='\033[1;33m'
C='\033[0;36m'
NC='\033[0m'

echo -e "${C}"
echo "=================================================="
echo "            NexoHost VPS Spoof Utility"
echo "=================================================="
echo -e "${NC}"

[ "$EUID" -ne 0 ] && echo -e "${R}Please run as root.${NC}" && exit 1

read -p "Enter RAM Size (GB): " RAMGB

echo ""
echo "Select CPU Model:"
echo "1) AMD Ryzen 9 9950X3D"
echo "2) AMD Ryzen 9 7950X"
echo "3) AMD Ryzen 7 7800X3D"
echo "4) Intel Core i9-14900K"
echo "5) Intel Core i9-13900K"
echo "6) Intel Core i7-13700K"
echo "7) Intel Xeon Platinum 8480+"
echo "8) Intel Xeon Gold 6430"
echo "9) Intel Xeon E5-2699 v4"
echo "10) AMD EPYC 9654"
echo "11) AMD EPYC 7763"
echo "12) Snapdragon 8 Elite Gen 5"
echo "13) Apple M3 Ultra"
echo "14) Intel Xeon W9-3495X"
echo "15) Custom CPU"

echo ""
read -p "Choose CPU (1-15): " CPUCHOICE

case $CPUCHOICE in
1) CPUNAME="AMD Ryzen 9 9950X3D";;
2) CPUNAME="AMD Ryzen 9 7950X";;
3) CPUNAME="AMD Ryzen 7 7800X3D";;
4) CPUNAME="Intel Core i9-14900K";;
5) CPUNAME="Intel Core i9-13900K";;
6) CPUNAME="Intel Core i7-13700K";;
7) CPUNAME="Intel Xeon Platinum 8480+";;
8) CPUNAME="Intel Xeon Gold 6430";;
9) CPUNAME="Intel Xeon E5-2699 v4";;
10) CPUNAME="AMD EPYC 9654";;
11) CPUNAME="AMD EPYC 7763";;
12) CPUNAME="Snapdragon 8 Elite Gen 5";;
13) CPUNAME="Apple M3 Ultra";;
14) CPUNAME="Intel Xeon W9-3495X";;
15) read -p "Enter Custom CPU Name: " CPUNAME;;
*) CPUNAME="AMD Ryzen 9 9950X3D";;
esac

echo ""
read -p "Enter CPU Core Count: " CORES

RAMKB=$((RAMGB*1024*1024))

mkdir -p /opt/sysspoof

echo -e "${B}[*] Generating meminfo...${NC}"

cat > /opt/sysspoof/meminfo <<EOF
MemTotal:       ${RAMKB} kB
MemFree:        $((RAMKB-1000000)) kB
MemAvailable:   $((RAMKB-1000000)) kB
Buffers:        200000 kB
Cached:         400000 kB
SwapTotal:      0 kB
SwapFree:       0 kB
EOF

echo -e "${B}[*] Generating cpuinfo...${NC}"

rm -f /opt/sysspoof/cpuinfo

for ((i=0;i<CORES;i++))
do
cat >> /opt/sysspoof/cpuinfo <<EOF
processor   : $i
vendor_id   : AuthenticAMD
cpu family  : 26
model       : 68
model name  : $CPUNAME
stepping    : 1
cpu MHz     : 4300.000
cache size  : 1024 KB
physical id : 0
siblings    : $CORES
core id     : $i
cpu cores   : $CORES
apicid      : $i
initial apicid  : $i
fpu     : yes
flags       : fpu sse sse2 sse3 ssse3 sse4_1 sse4_2 avx avx2 aes

EOF
done

echo -e "${B}[*] Creating persistent mounts...${NC}"

cat > /etc/systemd/system/proc-cpuinfo.mount <<EOF
[Unit]
Description=NexoHost CPU Spoof

[Mount]
What=/opt/sysspoof/cpuinfo
Where=/proc/cpuinfo
Type=none
Options=bind

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/proc-meminfo.mount <<EOF
[Unit]
Description=NexoHost RAM Spoof

[Mount]
What=/opt/sysspoof/meminfo
Where=/proc/meminfo
Type=none
Options=bind

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable proc-cpuinfo.mount >/dev/null 2>&1
systemctl enable proc-meminfo.mount >/dev/null 2>&1

mount --bind /opt/sysspoof/cpuinfo /proc/cpuinfo
mount --bind /opt/sysspoof/meminfo /proc/meminfo

echo -e "${B}[*] Spoofing lscpu...${NC}"

mv /usr/bin/lscpu /usr/bin/lscpu.real 2>/dev/null

cat > /usr/bin/lscpu <<EOF
#!/bin/bash

echo "Architecture:             x86_64"
echo "CPU(s):                   $CORES"
echo "Vendor ID:                AuthenticAMD"
echo "Model name:               $CPUNAME"
echo "Thread(s) per core:       1"
echo "Core(s) per socket:       $CORES"
echo "Socket(s):                1"
echo "CPU max MHz:              4300.0000"
echo "Hypervisor vendor:        KVM"
echo "Virtualization type:      full"

echo ""
echo "Host:                     NexoHost"
EOF

chmod +x /usr/bin/lscpu

echo -e "${B}[*] Spoofing nproc...${NC}"

mv /usr/bin/nproc /usr/bin/nproc.real 2>/dev/null

cat > /usr/bin/nproc <<EOF
#!/bin/bash
echo $CORES
EOF

chmod +x /usr/bin/nproc

echo -e "${B}[*] Installing neofetch & fastfetch configs...${NC}"

mkdir -p /etc/neofetch
mkdir -p /etc/fastfetch

cat > /etc/neofetch/config.conf <<EOF
print_info() {
    info title
    info underline

    info "Host" "NexoHost"
    info "OS" distro
    info "Kernel" kernel
    info "Uptime" uptime
    info "Packages" packages
    info "Shell" shell
    info "CPU" "$CPUNAME"
    info "GPU" "Virtual GPU"
    info "Memory" "${RAMGB}GB"
}
EOF

cat > /etc/fastfetch/config.jsonc <<EOF
{
  "\$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "modules": [
    "title",
    {
      "type": "custom",
      "format": "NexoHost"
    },
    "os",
    "kernel",
    {
      "type": "cpu",
      "format": "$CPUNAME"
    },
    {
      "type": "memory",
      "format": "${RAMGB} GB"
    }
  ]
}
EOF

echo ""
echo -e "${G}=========================================${NC}"
echo -e "${G}        NexoHost Spoof Activated        ${NC}"
echo -e "${G}=========================================${NC}"
echo -e "${Y}Host:${NC} NexoHost"
echo -e "${Y}RAM:${NC} ${RAMGB}GB"
echo -e "${Y}CPU:${NC} $CPUNAME"
echo -e "${Y}Cores:${NC} $CORES"
echo -e "${Y}Persistence:${NC} Enabled"
echo -e "${G}=========================================${NC}"
echo ""
