### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# global properties
properties() { '
kernel.string=Garnet CPU Overclock Module (Elysium 5.10.251)
do.devicecheck=0
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=garnet
device.name2=garnetin
device.name3=
device.name4=
device.name5=
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties

### AnyKernel install

## boot shell variables
block=vendor_boot
is_slot_device=1
ramdisk_compression=auto
patch_vbmeta_flag=auto

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh

dump_boot

########## FLASH VENDOR_BOOT START ##########

QCOM_CPUFREQ_HW_MOD=${ramdisk}/lib/modules/qcom-cpufreq-hw.ko

[ -f ${QCOM_CPUFREQ_HW_MOD} ] || abort "Error: Cannot find qcom-cpufreq-hw.ko in vendor_boot ramdisk!"

if [ -f ${QCOM_CPUFREQ_HW_MOD}.BAK ]; then
	ui_print " "
	ui_print "==================================="
	ui_print " Module sudah pernah di-patch"
	ui_print "==================================="
	ui_print " "
	ui_print "- Tekan Vol+ untuk RESTORE original"
	ui_print "- Tekan Vol- untuk ABORT"
	ui_print " "

	${bin}/keycheck
	rc_1=$?
	${bin}/keycheck
	rc_2=$?

	if [ "$rc_1" == "42" ] || [ "$rc_2" == "42" ]; then
		ui_print " "
		ui_print "- Restoring original module..."
		mv -f ${QCOM_CPUFREQ_HW_MOD}.BAK ${QCOM_CPUFREQ_HW_MOD}
		set_perm 0 0 0644 ${QCOM_CPUFREQ_HW_MOD}
		ui_print "- Original restored!"
		ui_print "- Reboot to apply."
	else
  		abort "! Abort by user."
	fi
else
	ui_print " "
	ui_print "==================================="
	ui_print " Garnet CPU Overclock Module"
	ui_print " Kernel: Elysium 5.10.251"
	ui_print " Device: Poco X6 5G / RN13 Pro"
	ui_print "==================================="
	ui_print " "
	ui_print "- Tekan Vol+ untuk INSTALL"
	ui_print "- Tekan Vol- untuk ABORT"
	ui_print " "

	${bin}/keycheck
	rc_1=$?
	${bin}/keycheck
	rc_2=$?

  	if [ "$rc_1" == "42" ] || [ "$rc_2" == "42" ]; then
		ui_print " "
		ui_print "- Installing..."
		cp -f ${QCOM_CPUFREQ_HW_MOD} ${QCOM_CPUFREQ_HW_MOD}.BAK
		cp -f ${home}/_vendor_boot_modules/qcom-cpufreq-hw.ko ${QCOM_CPUFREQ_HW_MOD}
		set_perm 0 0 0644 ${QCOM_CPUFREQ_HW_MOD}
		ui_print "- Module replaced successfully!"
		ui_print "- Reboot to apply changes."
	else
		abort "! Abort by user."
	fi
fi

write_boot

########## FLASH VENDOR_BOOT END ##########

# Patch vbmeta untuk disable AVB verification
ui_print " "
for vbmeta_blk in /dev/block/by-name/vbmeta*; do
	ui_print "- Patching $(basename $vbmeta_blk) ..."
	${bin}/vbmeta-disable-verification $vbmeta_blk || {
		ui_print "! Failed to patch ${vbmeta_blk}!"
		ui_print "- If device won't boot, disable AVB manually in TWRP"
	}
done

ui_print " "
ui_print "==================================="
ui_print " Installation complete!"
ui_print " Reboot now."
ui_print "==================================="
ui_print " "

## end boot install
