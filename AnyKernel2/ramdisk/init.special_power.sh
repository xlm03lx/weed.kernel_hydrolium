#!/system/bin/sh

################################################################################
# helper functions to allow Android init like script

function write() {
    echo -n $2 > $1
}

function copy() {
    cat $1 > $2
}

# macro to write pids to system-background cpuset
function writepid_sbg() {
    until [ ! "$1" ]; do
        echo -n $1 > /dev/cpuset/system-background/tasks;
        shift;
    done;
}

function writepid_top_app() {
    until [ ! "$1" ]; do
        echo -n $1 > /dev/cpuset/top-app/tasks;
        shift;
    done;
}
################################################################################

sleep 10

    # Bring CPUs online
    write /sys/devices/system/cpu/cpu1/online 1
    write /sys/devices/system/cpu/cpu2/online 1
    write /sys/devices/system/cpu/cpu3/online 1
    write /sys/devices/system/cpu/cpu4/online 1
    write /sys/devices/system/cpu/cpu5/online 1
    write /sys/devices/system/cpu/cpu6/online 1
    write /sys/devices/system/cpu/cpu7/online 1

    # Configure governor settings for little cluster
    write /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor "interactive"
	write /sys/devices/system/cpu/cpu0/cpufreq/interactive/above_hispeed_delay 59000
    write /sys/devices/system/cpu/cpu0/cpufreq/interactive/align_windows 0
    write /sys/devices/system/cpu/cpu0/cpufreq/interactive/fast_ramp_down 0
    write /sys/devices/system/cpu/cpu0/cpufreq/interactive/fastlane 0
    write /sys/devices/system/cpu/cpu0/cpufreq/interactive/fastlane_threshold 50
    write /sys/devices/system/cpu/cpu0/cpufreq/interactive/go_hispeed_load 80
    write /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq 1401600
    write /sys/devices/system/cpu/cpu0/cpufreq/interactive/ignore_hispeed_on_notify 0
    write /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy 0	
    write /sys/devices/system/cpu/cpu0/cpufreq/interactive/max_freq_hysteresis 0
    write /sys/devices/system/cpu/cpu0/cpufreq/interactive/min_sample_time 40000
    write /sys/devices/system/cpu/cpu0/cpufreq/interactive/powersave_bias 0
    write /sys/devices/system/cpu/cpu0/cpufreq/interactive/screen_off_maxfreq 1190000
    write /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads 1 806000:80
    write /sys/devices/system/cpu/cpu0/cpufreq/interactive/timer_rate 20000
    write /sys/devices/system/cpu/cpu0/cpufreq/interactive/timer_slack 80000	
    write /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_migration_notif 1
    write /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_sched_load 1

    # Configure governor settings for big cluster
    write /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor "interactive"
	write /sys/devices/system/cpu/cpu4/cpufreq/interactive/above_hispeed_delay 19000 1382400:39000
    write /sys/devices/system/cpu/cpu4/cpufreq/interactive/align_windows 0
    write /sys/devices/system/cpu/cpu4/cpufreq/interactive/fast_ramp_down 0
    write /sys/devices/system/cpu/cpu4/cpufreq/interactive/fastlane 0
    write /sys/devices/system/cpu/cpu4/cpufreq/interactive/fastlane_threshold 50
    write /sys/devices/system/cpu/cpu4/cpufreq/interactive/go_hispeed_load 85
    write /sys/devices/system/cpu/cpu4/cpufreq/interactive/hispeed_freq 1382400
    write /sys/devices/system/cpu/cpu4/cpufreq/interactive/ignore_hispeed_on_notify 0
    write /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy 0	
    write /sys/devices/system/cpu/cpu4/cpufreq/interactive/max_freq_hysteresis 0
    write /sys/devices/system/cpu/cpu4/cpufreq/interactive/min_sample_time 40000
    write /sys/devices/system/cpu/cpu4/cpufreq/interactive/powersave_bias 0
    write /sys/devices/system/cpu/cpu4/cpufreq/interactive/screen_off_maxfreq 1190000
    write /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads 85 1382400:90 1747200:80
    write /sys/devices/system/cpu/cpu4/cpufreq/interactive/timer_rate 20000
    write /sys/devices/system/cpu/cpu4/cpufreq/interactive/timer_slack 80000	
    write /sys/devices/system/cpu/cpu4/cpufreq/interactive/use_migration_notif 1
    write /sys/devices/system/cpu/cpu4/cpufreq/interactive/use_sched_load 1

    # cpufreq max
    write /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq 400000
    write /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 1401600
    write /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq 400000
    write /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq 1804800

	# Set ice-COOL display
	write /sys/devices/platform/kcal_ctrl.0/kcal_cont 256
	write /sys/devices/platform/kcal_ctrl.0/kcal_val 256
	write /sys/devices/platform/kcal_ctrl.0/kcal_sat 250
	write /sys/devices/platform/kcal_ctrl.0/kcal_min 25
	write /sys/devices/platform/kcal_ctrl.0/kcal 256 256 256 
	write /sys/devices/platform/kcal_ctrl.0/kcal_enable 1
	
	# Virtual memory tweaks
	write /proc/sys/vm/dirty_ratio 20
	write /proc/sys/vm/dirty_background_ratio 5
	write /proc/sys/vm/dirty_expire_centisecs 200
	write /proc/sys/vm/dirty_writeback_centisecs 500
	write /proc/sys/vm/min_free_kbytes 6541
	write /proc/sys/vm/oom_kill_allocating_task 0
	write /proc/sys/vm/overcommit_ratio 50
	write /proc/sys/vm/swappiness 60
	write /proc/sys/vm/vfs_cache_pressure 100
	write /proc/sys/vm/laptop_mode 0
	write /proc/sys/vm/extra_free_kbytes 24300
	write /sys/block/zram0/disksize 0	
	
	#Set block I/O scheduler
	setprop sys.io.scheduler "maple"
	write /sys/block/mmcblk0/queue/read_ahead_kb 128
	write /sys/block/mmcblk0/queue/iostats 0
	write /sys/block/mmcblk0/queue/add_random 1
	write /sys/module/lowmemorykiller/parameters/lmk_fast_run 1
	write /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk 1
	write /sys/module/lowmemorykiller/parameters/cost 32
	write /sys/module/lowmemorykiller/parameters/adj_max_shift 353
	write /sys/module/lowmemorykiller/parameters/adj 0 , 100 , 200 , 300 , 900 , 906
	write /sys/module/lowmemorykiller/parameters/minfree "21771,29028,36285,79827,108855,116112"
	
	#entropy
	write /proc/sys/kernel/random/read_wakeup_threshold 64
	write /proc/sys/kernel/random/write_wakeup_threshold 128
	
	##HOTPLUG##
	#core ctrl 
	write sys/devices/system/cpu/cpu4/core_ctl/min_cpus 4
	# disable lazyplug
	write sys/module/lazyplug/parameters/lazyplug_active 0
	write sys/module/lazyplug/parameters/touch_boost_active 0
	write sys/module/lazyplug/parameters/nr_run_hysteresis 17
	write sys/module/lazyplug/parameters/nr_possible_cores 8
	write sys/module/lazyplug/parameters/nr_run_profile_sel 0
	# disable alucard plug
	write sys/kernel/alucard_hotplug/hotplug_enable 0
	write sys/kernel/alucard_hotplug/hotplug_sampling_rate 48
	write sys/kernel/alucard_hotplug/hp_io_is_busy 0
	write sys/kernel/alucard_hotplug/min_cpus_online 8
	write sys/kernel/alucard_hotplug/maxcoreslimit_sleep 1
	#disbable brick plug
	write sys/kernel/msm_mpdecision/conf/enabled 0
	write sys/kernel/msm_mpdecision/conf/delay 40
	write sys/kernel/msm_mpdecision/conf/startdelay 1000
	write sys/kernel/msm_mpdecision/conf/idle_freq 400000
	write sys/kernel/msm_mpdecision/conf/max_cpus_online_susp 1
	write sys/kernel/msm_mpdecision/conf/min_cpus 8
	write sys/kernel/msm_mpdecision/conf/max_cpus 8
	#enable intelliplug 
	write sys/kernel/intelli_plug/intelli_plug_active 0
	write sys/kernel/intelli_plug/full_mode_profile 0
	write sys/kernel/intelli_plug/nr_run_hysteresis 10
	write sys/kernel/intelli_plug/cpu_nr_run_threshold 860
	write sys/kernel/intelli_plug/cpus_boosted 1
	write sys/kernel/intelli_plug/min_cpus_online 8
	write sys/kernel/intelli_plug/max_cpus_online 8
	write sys/kernel/intelli_plug/def_sampling_ms 268
	write sys/kernel/intelli_plug/down_lock_duration 2000
	write sys/kernel/intelli_plug/boost_lock_duration 2500
	write sys/kernel/intelli_plug/max_cpus_online_susp 1
	write sys/kernel/intelli_plug/nr_fshift 1

	#Enable CPU power saving
	write /sys/module/workqueue/parameters/power_efficient Y
	write /sys/module/sync/parameters/fsync_enabled Y
	write /sys/kernel/dyn_fsync/Dyn_fsync_active 1
	write /sys/kernel/power_suspend/power_suspend_mode 3
	write /sys/kernel/sched/gentle_fair_sleepers 0
	write /sys/kernel/sched/arch_power 1

	#Disable Core Control and Control VDD and MSM Thermal Throttling allowing for longer sustained performance
	write /sys/module/msm_thermal/core_control/enabled 1
	write /sys/module/msm_thermal/vdd_restriction/enabled 0	
	write /sys/module/msm_thermal/parameters/enabled N
	write /sys/module/msm_thermal/parameters/poll_ms 250	
	write /sys/module/msm_thermal/parameters/temp_threshold 70