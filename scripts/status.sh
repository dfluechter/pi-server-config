#!/bin/bash
cpu_temp=$(vcgencmd measure_temp | cut -d= -f2)
cpu_freq=$(($(vcgencmd measure_clock arm | awk -F= '{print $2}') / 1000000))
cpu_load=$(awk '{print $1 " (1m), " $2 " (5m), " $3 " (15m)"}' /proc/loadavg)
ram_info=$(free -m | awk 'NR==2 {printf "%s MB frei von %s MB (%s MB genutzt / %.1f%%)", $7, $2, $3, ($3/$2)*100}')
nvme_temp=$(sudo -n nvme smart-log /dev/nvme0n1 2>/dev/null | grep -m1 -i 'temperature' | awk -F: '{print $2}' | xargs)
fan_state=$(cat /sys/class/thermal/cooling_device0/cur_state 2>/dev/null || echo "0")
fan_raw_rpm=$(cat /sys/devices/platform/cooling_fan/hwmon/*/fan1_input 2>/dev/null || echo "0")

# Wenn Stufe 0 aktiv ist oder ein unplausibler Störwert (>8500 RPM auf Stufe 0) anliegt:
if [ "$fan_state" -eq 0 ] && [ "$fan_raw_rpm" -gt 8500 ]; then
    fan_display="${fan_raw_rpm} RPM (WARNUNG: PWM-Pin pruefen! Soll: 0 RPM)"
elif [ "$fan_state" -eq 0 ] && [ "$fan_raw_rpm" -eq 0 ]; then
    fan_display="0 RPM (Aus - Stufe 0/4)"
else
    fan_display="${fan_raw_rpm} RPM (Stufe ${fan_state}/4)"
fi

disk_free=$(df -h / | awk 'NR==2 {print $4 " frei von " $2 " (" $5 " belegt)"}')
now=$(date +"%H:%M:%S")

echo -e "\e[1;36m==========================================================\e[0m"
echo -e "\e[1;36m              SENSOR-PI STATUS (${now} Uhr)              \e[0m"
echo -e "\e[1;36m==========================================================\e[0m"
echo -e "\e[1;32mCPU-Temperatur :\e[0m ${cpu_temp} @ ${cpu_freq} MHz"
echo -e "\e[1;32mCPU-Last (Load):\e[0m ${cpu_load}"
echo -e "\e[1;33mNVMe-Temperatur:\e[0m ${nvme_temp:-Bitte mit sudo starten}"
echo -e "\e[1;34mActive Cooler  :\e[0m ${fan_display}"
echo -e "\e[1;35mArbeitsspeicher:\e[0m ${ram_info}"
echo -e "\e[1;35mNVMe Speicher  :\e[0m ${disk_free}"
echo -e "\e[1;36m==========================================================\e[0m"
