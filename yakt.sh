#!/system/bin/sh
# Yakt v6
# Author: @NotZeetaa (Github)

sleep 60

# Log create
if [ ! -d /sdcard/Documents ]; then
    LOG=/sdcard/yakt.log
else
    if [ ! -d /sdcard/Documents/yakt ]; then
        mkdir /sdcard/Documents/yakt
        LOG=/sdcard/Documents/yakt/yakt.log
    else
        LOG=/sdcard/Documents/yakt/yakt.log
    fi
fi

# Variables
SC=/sys/devices/system/cpu/cpu0/cpufreq/schedutil
KP=/sys/module/kprofiles
TP=/dev/stune/top-app/uclamp.max
DV=/dev/stune
CP=/dev/cpuset
ZW=/sys/module/zswap
MC=/sys/module/mmc_core
WT=/proc/sys/vm/watermark_boost_factor
KL=/proc/sys/kernel
VM=/proc/sys/vm
S2=/sys/devices/system/cpu/cpufreq/schedutil
MG=/sys/kernel/mm/lru_gen
RM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
PS=$(cat /proc/version)
BT=$(getprop ro.boot.bootdevice)
BL=/dev/blkio
US=/dev/sys/fs/by-name/userdata

# Info
echo "# YAKT v6" > $LOG
echo "# Build Date: 29/01/2023" >> $LOG
echo -e "# Author: @NotZeetaa (Github)\n" >> $LOG
echo "[$(date "+%H:%M:%S")] Device: $(getprop ro.product.system.model)" >> $LOG
echo "[$(date "+%H:%M:%S")] Brand: $(getprop ro.product.system.brand)" >> $LOG
echo "[$(date "+%H:%M:%S")] Kernel: $(uname -r)" >> $LOG
echo "[$(date "+%H:%M:%S")] Rom build type: $(getprop ro.system.build.type)" >> $LOG
echo -e "[$(date "+%H:%M:%S")] Android Version: $(getprop ro.system.build.version.release)\n" >> $LOG

# Use Google's schedutil rate-limits from Pixel 3
# Credits to Kdrag0n
echo "[$(date "+%H:%M:%S")] Applying Google's schedutil rate-limits from Pixel 3" >> $LOG
sleep 0.5
if [ -d $S2 ]; then
    echo 500 > $S2/up_rate_limit_us
    echo 20000 > $S2/down_rate_limit_us
    echo -e "[$(date "+%H:%M:%S")] Applied Google's schedutil rate-limits from Pixel 3\n" >> $LOG
elif [ -e $SC ]; then
    for cpu in /sys/devices/system/cpu/*/cpufreq/schedutil
    do
        echo 500 > "${cpu}"/up_rate_limit_us
        echo 20000 > "${cpu}"/down_rate_limit_us
    done
    echo -e "[$(date "+%H:%M:%S")] Applied Google's schedutil rate-limits from Pixel 3\n" >> $LOG
else
    echo -e "[$(date "+%H:%M:%S")] Abort You are not using schedutil governor\n" >> $LOG
fi

# Grouping tasks tweak
echo "[$(date "+%H:%M:%S")] Disabling Sched Auto Group..." >> $LOG
echo 0 > /proc/sys/kernel/sched_autogroup_enabled
echo -e "[$(date "+%H:%M:%S")] Done.\n" >> $LOG

# Tweak scheduler to have less Latency
# Credits to RedHat & tytydraco
echo "[$(date "+%H:%M:%S")] Tweaking to Reduce Latency " >> $LOG
echo 12000000 > $KL/sched_wakeup_granularity_ns
echo 10000000 > $KL/sched_min_granularity_ns
echo 5000000 > $KL/sched_migration_cost_ns
sleep 0.5
echo -e "[$(date "+%H:%M:%S")] Done.\n" >> $LOG

# Kprofiles Tweak
# Credits to cyberknight
echo "[$(date "+%H:%M:%S")] Checking if your kernel has Kprofiles support..." >> $LOG
if [ -d $KP ]; then
    echo "[$(date "+%H:%M:%S")] Your Kernel Supports Kprofiles" >> $LOG
    echo "[$(date "+%H:%M:%S")] Tweaking it..." >> $LOG
    sleep 0.5
    echo -e "[$(date "+%H:%M:%S")] Done.\n" >> $LOG
    echo 2 > $KP/parameters/mode
else
    echo -e "[$(date "+%H:%M:%S")] Your Kernel doesn't support Kprofiles\n" >> $LOG
fi

# Ram Tweak
# The stat_interval one reduces jitter (Credits to kdrag0n)
# Credits to RedHat for dirty_ratio
echo "[$(date "+%H:%M:%S")] Applying Ram Tweaks" >> $LOG
sleep 0.5
echo 20 > $VM/vfs_cache_pressure
echo 20 > $VM/stat_interval
echo 32 > $VM/watermark_scale_factor
echo -e "[$(date "+%H:%M:%S")] Applied Ram Tweaks\n" >> $LOG

# Mglru
# Credits to Arter97
echo "[$(date "+%H:%M:%S")] Cheking if your kernel has mglru support..." >> $LOG
if [ -d $MG ]; then
    echo "[$(date "+%H:%M:%S")] Found it." >> $LOG
    echo "[$(date "+%H:%M:%S")] Tweaking it..." >> $LOG
    echo 5000 > $MG/min_ttl_ms
    echo -e "[$(date "+%H:%M:%S")] Done.\n" >> $LOG
else
    echo "[$(date "+%H:%M:%S")] Your kernel doesn't support mglru :(" >> $LOG
    echo "[$(date "+%H:%M:%S")] Aborting it..." >> $LOG
    echo -e "[$(date "+%H:%M:%S")] Done.\n" >> $LOG
fi

# Set kernel.perf_cpu_time_max_percent to 20
echo "[$(date "+%H:%M:%S")] Applying tweak for perf_cpu_time_max_percent" >> $LOG
echo 20 > $KL/perf_cpu_time_max_percent
echo -e "[$(date "+%H:%M:%S")] Done.\n" >> $LOG

# Disable some scheduler logs/stats
# Also iostats & reduce latency
# Credits to tytydraco
echo "[$(date "+%H:%M:%S")] Disabling some scheduler logs/stats" >> $LOG
if [ -e $KL/sched_schedstats ]; then
    echo 0 > $KL/sched_schedstats
fi
echo "0	0 0 0" > $KL/printk
echo off > $KL/printk_devkmsg
for queue in /sys/block/*/queue
do
    echo 0 > "$queue/iostats"
    echo 128 > "$queue/nr_requests"
done
echo -e "[$(date "+%H:%M:%S")] Done.\n" >> $LOG

# Enable Timer migration
echo "[$(date "+%H:%M:%S")] Enabling Timer Migration" >> $LOG
echo 1 > $KL/timer_migration
echo -e "[$(date "+%H:%M:%S")] Done.\n" >> $LOG

# Cgroup Tweak
echo "[$(date "+%H:%M:%S")] Checking which scheduler your kernel has" >> $LOG
sleep 0.5
if [ -e $TP ]; then
    # Uclamp Tweak
    # All credits to @darkhz
    echo "[$(date "+%H:%M:%S")] You have uclamp scheduler" >> $LOG
    echo "[$(date "+%H:%M:%S")] Applying tweaks for it..." >> $LOG
    sleep 0.3
    for ta in $CP/*/top-app
    do
        echo max > "$ta/uclamp.max"
        echo 10 > "$ta/uclamp.min"
        echo 1 > "$ta/uclamp.boosted"
        echo 1 > "$ta/uclamp.latency_sensitive"
    done
    for fd in $CP/*/foreground
    do
        echo 50 > "$fd/uclamp.max"
        echo 0 > "$fd/uclamp.min"
        echo 0 > "$fd/uclamp.boosted"
        echo 0 > "$fd/uclamp.latency_sensitive"
    done
    for bd in $CP/*/background
    do
        echo max > "$bd/uclamp.max"
        echo 20 > "$bd/uclamp.min"
        echo 0 > "$bd/uclamp.boosted"
        echo 0 > "$bd/uclamp.latency_sensitive"
    done
    for sb in $CP/*/system-background
    do
        echo 40 > "$sb/uclamp.max"
        echo 0 > "$sb/uclamp.min"
        echo 0 > "$sb/uclamp.boosted"
        echo 0 > "$sb/uclamp.latency_sensitive"
    done
    sysctl -w kernel.sched_util_clamp_min_rt_default=0
    sysctl -w kernel.sched_util_clamp_min=128
    echo -e "[$(date "+%H:%M:%S")] Done,\n" >> $LOG
else
    echo "[$(date "+%H:%M:%S")] You have normal cgroup scheduler" >> $LOG
    echo "[$(date "+%H:%M:%S")] Applying tweaks for it..." >> $LOG
    sleep 0.3
    chmod 644 $DV/top-app/schedtune.boost
    echo 1 > $DV/top-app/schedtune.boost
    chmod 664 $DV/top-app/schedtune.boost
    echo 0 > $DV/top-app/schedtune.prefer_idle
    echo 1 > $DV/foreground/schedtune.boost
    echo 0 > $DV/background/schedtune.boost
    echo 1 > $DV/background/schedtune.prefer_idle
    echo -e "[$(date "+%H:%M:%S")] Done.\n" >> $LOG
fi

# Enable ECN negotiation by default
# By kdrag0n
echo "[$(date "+%H:%M:%S")] Enabling ECN negotiation..." >> $LOG
echo 1 > /proc/sys/net/ipv4/tcp_ecn
echo -e "[$(date "+%H:%M:%S")] Done.\n" >> $LOG

# Always allow sched boosting on top-app tasks
# Credits to tytydraco
echo "[$(date "+%H:%M:%S")] Always allow sched boosting on top-app tasks" >> $LOG
echo 0 > $KL/sched_min_task_util_for_colocation
echo -e "[$(date "+%H:%M:%S")] Done.\n" >> $LOG

# Watermark Boost Tweak
echo "[$(date "+%H:%M:%S")] Checking if you have watermark boost support" >> $LOG
if [[ "$PS" == *"4.19"* ]] && [ -e $WT ]; then
    echo "[$(date "+%H:%M:%S")] Found 4.19 kernel, disabling watermark boost because doesn't work..." >> $LOG
    echo 0 > $VM/watermark_boost_factor
    echo -e "[$(date "+%H:%M:%S")] Done.\n" >> $LOG
elif [ -e $WT ]; then
    echo "[$(date "+%H:%M:%S")] Found Watermark Boost support, tweaking it" >> $LOG
    echo 15000 > $WT
    echo -e "[$(date "+%H:%M:%S")] Done.\n" >> $LOG
else
echo "[$(date "+%H:%M:%S")] Your kernel doesn't support watermark boost" >> $LOG
echo "[$(date "+%H:%M:%S")] Aborting it..." >> $LOG
echo -e "[$(date "+%H:%M:%S")] Done.\n" >> $LOG
fi

echo "[$(date "+%H:%M:%S")] Tweaking read_ahead overall..." >> $LOG
for queue2 in /sys/block/*/queue/read_ahead_kb
do
echo 128 > $queue2
done
echo -e "[$(date "+%H:%M:%S")] Tweaked read_ahead.\n" >> $LOG

# UFSTW (UFS Turbo Write Tweak)
echo "[$(date "+%H:%M:%S")] Checking if your kernel has UFS Turbo Write Support" >> $LOG
if [ -e /sys/devices/platform/soc/$BT/ufstw_lu0/tw_enable ]; then
    echo "[$(date "+%H:%M:%S")] Your kernel has UFS Turbo Write Support. Tweaking it..." >> $LOG
    echo 1 > /sys/devices/platform/soc/$BT/ufstw_lu0/tw_enable
    echo -e "[$(date "+%H:%M:%S")] Done.\n" >> $LOG
else
    echo -e "[$(date "+%H:%M:%S")] Your kernel doesn't have UFS Turbo Write Support.\n" >> $LOG
fi

# Enable fast socket open for receiver and sender
# Credits to @tytydraco
echo "[$(date "+%H:%M:%S")] Enabling Fast Socket Open..." >> $LOG
echo 3 > /proc/sys/net/ipv4/tcp_fastopen
echo -e "[$(date "+%H:%M:%S")] Done.\n" >> $LOG

# Extfrag
# Credits to @tytydraco
echo "[$(date "+%H:%M:%S")] Increasing fragmentation index..." >> $LOG
echo 750 > $VM/extfrag_threshold
sleep 0.5
echo -e "[$(date "+%H:%M:%S")] Done.\n" >> $LOG

# Disable Spi CRC
if [ -d $MC ]; then
    echo "[$(date "+%H:%M:%S")] Disabling Spi CRC" >> $LOG
    echo 0 > $MC/parameters/use_spi_crc
    echo -e "[$(date "+%H:%M:%S")] Done.\n" >> $LOG
fi

# Zswap
echo "[$(date "+%H:%M:%S")] zswap: Checking if your kernel supports zswap.." >> $LOG
if [ -d $ZW ]; then
    echo "[$(date "+%H:%M:%S")] zswap: Your kernel supports zswap, tweaking it.." >> $LOG
    echo lz4 > $ZW/parameters/compressor
    echo "[$(date "+%H:%M:%S")] zswap: Setted your zswap compressor to lz4 (Fastest compressor)." >> $LOG
    if [ "$RM" -le "5741280" ]; then
        echo zsmalloc > $ZW/parameters/zpool
        echo -e "[$(date "+%H:%M:%S")] zswap: Setted your zpool compressor to zsmalloc\nas per your device is equal or under then 6Gb of ram." >> $LOG
    else
        echo z3fold > $ZW/parameters/zpool
        echo -e "[$(date "+%H:%M:%S")] zswap: Setted your zpool compressor to z3fold\nas per your device is higher then 6Gb of ram." >> $LOG
    fi
    echo -e "[$(date "+%H:%M:%S")] zswap: Tweaked!\n" >> $LOG
else
    echo -e "[$(date "+%H:%M:%S")] zswap: Your kernel doesn't support zswap, aborting it...\n" >> $LOG
fi

# Blkio tweak
# Credits to xNombre
if [ -d $BL ]; then
    echo "[$(date "+%H:%M:%S")] Tweaking blkio..." >> $LOG
    echo 1000 > $BL/blkio.weight
    echo 200 > $BL/background/blkio.weight
    echo 2000 > $BL/blkio.group_idle
    echo 0 > $BL/background/blkio.group_idle
    echo -e "[$(date "+%H:%M:%S")] Done.\n" >> $LOG
fi

# Userdata tweak
# Credits to xNombre
if [ -d $US ]; then
    echo "[$(date "+%H:%M:%S")] Tweaking userdata..." >> $LOG
    echo 8 > $US/data_io_flag
    echo 8 > $US/node_io_flag
    echo -e "[$(date "+%H:%M:%S")] Done.\n" >> $LOG
fi

echo "[$(date "+%H:%M:%S")] The Tweak is done enjoy :)" >> $LOG
