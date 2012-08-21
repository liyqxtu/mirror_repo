#!/bin/bash
function start_adb {
    sudo adb start-server >/dev/null 2>&1
}

function welcome {
    clear
    echo "===================================================="
    echo "= Welcome to the AlphaRev 1.8 S-OFF HBOOT flasher =="
    echo "===================================================="
    echo -ne "\n"
    echo "This will provide you with the most current HBOOT for your phone,"
    echo "patched to ignore security and to provide extended fastboot commands."
    echo "Remember: your phone needs to be rooted already. This program will not do that for you."
    echo -ne "\n"
    echo "Please note that this will NOT set the actual security flag (@secu_flag) in"
    echo "the radio NVRAM (radio S-OFF), nor will this change your CID."
    echo "Instead, this HBOOT will ignore the security flag."
    echo -ne "\n"
    echo "This means that if you ever update to an official RUU that has a HBOOT update in it,"
    echo "this custom HBOOT will be removed and you will lose all root/security-ignore capabilities."
    echo "It is possible to circumvent this by removing HBOOT updates from the RUU you want to flash,"
    echo "since you will have the possibility to flash unsigned updates due to security-ignore."
    echo -ne "\n"
    echo "Please remember that a HBOOT update is a critical part of your phone, if anything goes wrong,"
    echo "this WILL brick your phone."
    echo "AlphaRev is NOT responsible for any bricks, murdering your cats, exploding phones or any other damage"
    echo "this might incur. By continuing, you state that you are fully aware of the risk and accept it."
    echo -ne "\n"
    echo "This version of AlphaRev currently supports the following devices:"
    echo -ne "\n"
    echo "-HTC Desire GSM (Bravo), all hardware models, including PVT4."
    echo "-HTC Legend GSM (Legend), HBOOT 1.0 and higher is unsupported."
    echo "-HTC myTouch 3G Slide (Espresso)"
    echo -ne "\n"
    read -s -n 1 -p "Press any key to continue . . ."
    clear
    echo "Please connect your phone via USB while booted up, and enable USB debugging."
    echo "==========================================================================="
    echo -ne "\n"
}

function wait_for_device {
    echo -n "Waiting for your device... "
    adb wait-for-device
    echo "FOUND!"
}

function wait_for_device_long {
    echo "Waiting for your device to boot Android, this might take a while."
    echo "Dozing off for about a minute while we wait."
    adb wait-for-device
    sleep 40
}

function wait_for_hboot {
	if [ $1 -gt 5 ];
	then
		echo "We will now need some user interaction. Timing is very important during this step."
		echo "When you are done reading this message, we will run a sequence on the phone, and let you know when to press FASTBOOT"
		echo "on your phone using the POWER key. Make sure you have the phone in your hands, ready to press the POWER button to switch from HBOOT to FASTBOOT mode,"
		echo "and ONLY when we instruct you to do so. If at first the phone does not seem to respond, just keep pressing POWER until it switches to FASTBOOT mode."
		echo -ne "\n"
		echo -n "Please press ANY key to start the sequence, then watch this space to see when to press POWER on your phone:"
		read -s -n 1
		echo -n " ----------> "
		sudo waitforhboot $1 >/dev/null 2>&1
		echo "Press FASTBOOT on your phone NOW <----------"
		sleep 1
		sudo fastboot oem boot >/dev/null 2>&1
        sleep 1
        sudo fastboot oem boot >/dev/null 2>&1
		echo -ne "\n"
	else
		echo -n "Waiting for bootloader.."
		sudo waitforhboot $1 >/dev/null 2>&1
		echo "OK!"
		echo -ne "\n"
	fi
	echo "Booting your phone for the next step."
}
	
function reboot_to_hboot {
    echo "Rebooting your phone."
    adb reboot oem-42
}

function reboot_to_fastboot {
	echo "Rebooting your phone."
	adb reboot bootloader
}

function adb_cmd {
    echo -e "su\n$*\nexit\nexit" | adb shell >/dev/null 2>&1
}

function adb_push {
	adb push $1 /data/alpha/ >/dev/null 2>&1
}

function adb_push_recovery {
	adb push $1 /data/alpha/recovery.img > /dev/null 2>&1
}

function identify_phone {
	echo "Identifying your phone:"
	adb_cmd "chmod 777 /proc/cmdline"
	adb_cmd "chmod 777 /proc/mtd"
	adb pull /proc/cmdline /tmp/cmdline >/dev/null 2>&1
	adb pull /proc/mtd /tmp/mtd >/dev/null 2>&1
	MID=`cat /tmp/cmdline|grep -o mid=[A-Za-z0-9]*|sed 's/mid=//'`
	CID=`cat /tmp/cmdline|grep -o cid=[A-Za-z0-9_]*|sed 's/cid=//'`
	LDR=`cat /tmp/cmdline|grep -o bootloader=[0-9.]*|sed 's/bootloader=//'`
    LDRMAJOR=`echo $LDR|cut -c1`
	blksize=`cat /tmp/mtd|grep misc|awk '{print $3}'`
    
    if [ $MID == "PB9920000" ] || [ $MID == "PB9921000" ] || [ $MID == "PB9922000" ];
    then
		if [ $blksize == 00020000 ];
		then
			DEV="bravo"
			MODEL="Bravo (HTC Desire)"
			SCREEN="wvga"
			return 1
		else
			DEV="bravo"
			MODEL="Bravo PVT4 (HTC Desire)"
			SCREEN="wvga"
			return 2
		fi
    elif [ $MID == "PC4910000" ]; then
        DEV="buzz"
        MODEL="Buzz (HTC Wildfire)"
		SCREEN="qvga"
        return 0
    elif [ $MID == "PB9211000" ]; then
        DEV="liberty"
        MODEL="Liberty (HTC Aria)"
		SCREEN="hvga"
        return 0
    elif [ $MID == "PB9940000" ]; then
        DEV="bravoc"
        MODEL="BravoC (HTC Desire CDMA)"
		SCREEN="wvga"
        return 0
    elif [ $MID == "PB7610000" ]; then
        DEV="legend"
        MODEL="HTC Legend"
		SCREEN="hvga"
        return 6
    elif [ $MID == "PB6510000" ]; then
        DEV="espresso"
        MODEL="Espresso (myTouch Slide)"
		SCREEN="hvga"
        return 7
    else
		DEV="unsupported"
		MODEL="$MID"
		return 0
	fi
}

function check_phone {
    if [ $TYPE == 0 ]; 
    then
        echo "Your phone was not recognized or is unsupported at this time."
		echo "If you are 100% sure your phone type should be supported in this version, please note the Model ID displayed."
        echo -ne "\n"
		echo "Powering off in 60 seconds."
        sleep 60
        sudo poweroff -nf
    elif [ $LDRMAJOR -gt 0 ];
    then
        echo "HBOOT 1.0 is not supported at this time."
        echo "This method will only work on HBOOT versions lower than 1.0."
        echo -ne "\n"
        echo "Powering off in 60 seconds."
        sleep 60
        sudo poweroff -nf
    fi
}

function display_phone {
    echo "Device model: $MODEL"
    echo "CID: $CID"
	echo "MID: $MID"
    echo "HBOOT version: $LDR"
	echo "Screen type: `echo $SCREEN|tr '[:lower:]' '[:upper:]'`"
    echo
	if [ $DEV == "bravo" ];
	then
		echo "Would you like to install ClockworkMod-AlphaRev Recovery as part of this procedure? [Y/n]"
		read a
		if [[ $a == "N" || $a == "n" ]];
		then
			RECOVERY=0
			echo "Recovery will NOT be installed as part of the S-OFF procedure."
            echo -ne "\n"
		else
			RECOVERY=1
			echo "Custom Recovery WILL be installed as part of the S-OFF procedure."
            echo -ne "\n"
		fi
    elif [ $DEV == "legend" ];
    then
        echo "Would you like to install ClockworkMod Recovery as part of this procedure? [Y/n]"
		read a
		if [[ $a == "N" || $a == "n" ]];
		then
			RECOVERY=0
			echo "Recovery will NOT be installed as part of the S-OFF procedure."
            echo -ne "\n"
		else
			RECOVERY=1
			echo "Custom Recovery WILL be installed as part of the S-OFF procedure."
            echo -ne "\n"
		fi
    elif [ $DEV == "espresso" ];
    then
        echo "Would you like to install ClockworkMod Recovery as part of this procedure? [Y/n]"
		read a
		if [[ $a == "N" || $a == "n" ]];
		then
			RECOVERY=0
			echo "Recovery will NOT be installed as part of the S-OFF procedure."
            echo -ne "\n"
		else
			RECOVERY=1
			echo "Custom Recovery WILL be installed as part of the S-OFF procedure."
            echo -ne "\n"
		fi
    fi
	sleep 5
}

function push_files {
    echo -n "Pushing necessary files to the phone.."
    echo -e 'su\ncd /data\nmkdir alpha\nchmod 777 alpha\nexit\nexit\n' | adb shell >/dev/null 2>&1
	
	FILES="flash_image dump_image $DEV-splboot.img $DEV-alphaspl.img splash-$SCREEN.img"
	
    for file in $FILES;
    do
        if ! adb_push $file;
        then
            echo "Failed to push: $file"
            return 1
        fi
    done 	

	if [ $RECOVERY -eq 1 ];
	then
		adb_push_recovery recovery-$DEV.img
	fi
	
	adb_cmd "chmod 755 /data/alpha/*_image"
	adb_cmd "/data/alpha/dump_image boot /data/alpha/boot.old"
	adb_cmd "sync"
    echo "DONE."
    echo -n "Step 1 of 3 is done, "
    return 0
}

function prepare_for_flash {
    echo "Step 2 of 3 is running.." 
    echo -n "Preparing your phone for HBOOT flash.."
    adb_cmd "/data/alpha/flash_image boot /data/alpha/$DEV-splboot.img"
    adb_cmd "sync"
    echo "DONE." 
    return 0
}

function wait_for_hboot_flash {
    echo "Step 3 of 3 is starting. During this step, you will receive instructions and progress on-screen."
    echo "This is normal. DO NOT TURN OFF YOUR PHONE DURING THIS STEP, HBOOT is being flashed during this stage,"
    echo "and turning it off WILL *BRICK* your phone!"
    echo
    echo "Waiting for flashing to complete..."
    echo
    sleep 25
    
    adbdev=`adb devices|tail -n2|awk {'print $2'}`
    while [ $adbdev == 'of' ];
    do
        sleep 5
        adbdev=`adb devices|tail -n2|awk {'print $2'}`
    done
    
    if [ $adbdev == 'recovery' ];
    then
        adb pull /tmp/feedback /tmp/feedback >/dev/null 2>&1
        status=`cat /tmp/feedback`
        while [ $status -eq 0 ];
        do
            #Get current status again and loop until status changes.
            adb pull /tmp/feedback /tmp/feedback >/dev/null 2>&1
            status=`cat /tmp/feedback`
            if [ $status -eq 0 ];
            then
                sleep 5;
            fi
        done
        
        return $status
    elif [ $adbdev == 'device' ];
    then
        return 999
    else
        return 998
    fi
}

function handle_result {            
    #Splboot status has changed. Act accordingly.
    if [ $1 -eq 1 ];
    then
        # Hboot reflash succeeded. Inform user of success!
        echo "HBOOT was flashed successfully! You can now truly take control of your security-ignore-bootloader Android phone!"
        echo "This flashing method was brought to you by AlphaRev." 
        echo "Big thanks to everyone at the unrEVOked team for their NAND unlock method and guidance."
        echo
        echo "We will now reboot your phone into the bootloader mode. You should see AlphaRev in the top line."
        echo "From here, you should be able to reboot into Android as normal."
        echo 
        echo "Enjoy your new found freedom."
        echo
        reboot_to_fastboot
        read -s -n 1 -p "Press any key to shutdown the livecd, the procedure is finished."
        sudo poweroff -nf

    elif [ $status -eq 2 ]; 
    then
        # Hboot reflash did not succeed, but the original HBOOT is still in place.
        echo "HBOOT flash failed. However, your old HBOOT is still in place. Most likely, the exploit failed."
        echo "We would like to advise you to start over."
        echo "Make sure you have met ALL prerequisites found in the thread where you found this."
        echo "First and foremost, you need ROOT for this to work."
        echo
        echo "Rebooting your phone. Feel free to start over by restarting the livecd. Shutting down in 30 seconds."
        adb reboot
        sleep 30
        sudo poweroff -nf
    elif [ $status -eq 3 ]; 
    then
        # Hboot reflash did not succeed, and the original HBOOT has been destroyed! Possible brick!!
        echo "HBOOT flash failed. We tried to restore your old HBOOT, but that did not work."
        echo "Leave your phone TURNED ON!!! As soon as you power off, you will BRICK IT, permanently."
        echo "Do NOT do this unless you're ready to return this phone under HTC warranty."
        echo
        echo "Please, get on IRC as soon as possible, and join irc.freenode.net #alpharev"
        echo "The operators there should be able to provide you with further instructions in an attempt to save your phone."
        echo
    elif [ $status -eq 4 ];
    then
        # Could not dump HBOOT. Most likely a kernel module error.
        echo "Initial HBOOT dump failed. Nothing was flashed because we could not backup your old HBOOT."
        echo "Please contact someone in irc.freenode.net #alpharev. We can then try to diagnose what is going on."
        echo
        echo "Remember: your HBOOT is NOT S-OFF, and it is not bricked. You can safely reboot to try again if you want."
        echo
    elif [ $status -eq 999 ]; 
    then
        # Phone is in device mode. Unexpected.
        read -s -n 1 -p "An unexpected error occurred. Error code 5. Press any key to shutdown."
        sudo poweroff -nf
    elif [ $status -eq 998 ]; 
    then
        # Something unexpected occured. Unable to read ADB status.
        read -s -n 1 -p "An unexpected error occurred. Error code 10. Press any key to shutdown."
        sudo poweroff -nf
    fi
}

# Init variables
DEV=""
MODEL=""
TYPE=""
MID=""
CID=""
LDR=""
SCREEN=""
RECOVERY=0

# Step 1 (Intro / Phone validation / push files)
start_adb
welcome
wait_for_device
identify_phone
TYPE=$?
display_phone
check_phone

if ! push_files; 
then
    echo "Failed to push files - aborting..."
    sleep 30
    sudo poweroff -nf
fi

reboot_to_hboot

# Step 2 (Prepare to flash hboot)
wait_for_hboot $TYPE
wait_for_device_long

if ! prepare_for_flash; 
then
    echo "Preparing for flash failed - aborting..."
    sleep 30
    sudo poweroff -nf
fi

reboot_to_hboot

# Step 3 (flash hboot)
wait_for_hboot $TYPE
wait_for_hboot_flash
handle_result $?
