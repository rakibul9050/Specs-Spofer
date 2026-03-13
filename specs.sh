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
echo "6) Intel Xeon Platinum 8480+"
echo "7) Intel Xeon Gold 6430"
echo "8) AMD EPYC 9654"
echo "9) AMD EPYC 7763"
echo "10) Custom CPU Name"

read -p "Choose CPU (1-10): " CPUCHOICE

case $CPUCHOICE in
1) CPUNAME="AMD Ryzen 9 9950X3D";;
2) CPUNAME="AMD Ryzen 9 7950X";;
3) CPUNAME="AMD Ryzen 7 7800X3D";;
4) CPUNAME="Intel Core i9-14900K";;
5) CPUNAME="Intel Core i9-13900K";;
6) CPUNAME="Intel Xeon Platinum 8480+";;
7) CPUNAME="Intel Xeon Gold 6430";;
8) CPUNAME="AMD EPYC 9654";;
9) CPUNAME="AMD EPYC 7763";;
10) read -p "Enter custom CPU name: " CPUNAME;;
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
echo "Architecture: x86_64"
echo "CPU(s): $CORES"
echo "Vendor ID: AuthenticAMD"
echo "Model name: $CPUNAME"
echo "Thread(s) per core: 1"
echo "Core(s) per socket: $CORES"
echo "Socket(s): 1"
EOF

chmod +x /usr/bin/lscpu

echo "Spoofing nproc..."

mv /usr/bin/nproc /usr/bin/nproc.real 2>/dev/null

cat > /usr/bin/nproc <<EOF
#!/bin/bash
echo $CORES
EOF

chmod +x /usr/bin/nproc

echo ""
echo "================================="
echo "Spoof Setup Complete!"
echo "RAM: ${RAMGB}GB"
echo "CPU: $CPUNAME"
echo "Cores: $CORES"
echo "Persistent: YES (24/7)"
echo "================================="
