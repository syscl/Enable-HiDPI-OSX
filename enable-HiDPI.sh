#!/bin/sh

#  enable-HiDPI.sh
#  
#
#  Created by syscl/lighting/Yating Zhou on 16/3/2.
#

#================================= GLOBAL VARS ==================================

#
# The script expects '0.5' but non-US localizations use '0,5' so we export
# LC_NUMERIC here (for the duration of the ssdtPRGen.sh) to prevent errors.
#
export LC_NUMERIC="en_US.UTF-8"

#
# Prevent non-printable/control characters.
#
unset GREP_OPTIONS
unset GREP_COLORS
unset GREP_COLOR

#
# Output styling.
#
BOLD="\033[1m"
RED="\033[1;31m"
GREEN="\033[1;32m"
BLUE="\033[1;34m"
OFF="\033[m"

#
# Define variables.
# Gvariables stands for getting datas from OS X.
#
gDisplayVendorID_RAW=""
gDisplayVendorID=""
gDisplayProductID_RAW=""
gDisplayProductID_sfix=""
gDisplayProductID_fix=""
gDisplayProductID=""
gConfig=""
gRes_RAW="F"
gRes_VAL=""
gRes_ENCODE=""
gHeight_HiDPI=""
gWide_HiDPI=""
gHeight_HiDPI_VAL=""
gWide_HiDPI_VAL=""
gRes_HiDPI_VAL=""
gRes_HiDPI_ENCODE=""
gDespath=""

#
# Repository location
#
REPO=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

#
# Define gConfig
#
gConfig=""

#
#--------------------------------------------------------------------------------
#

function _PRINT_MSG()
{
    local message=$1

    if [[ $message =~ 'OK' ]];
      then
        local message=$(echo $message | sed -e 's/.*OK://')
        echo "[  ${GREEN}OK${OFF}  ] ${message}."
      else
        if [[ $message =~ 'FAILED' ]];
          then
            local message=$(echo $message | sed -e 's/.*://')
            echo "[${RED}FAILED${OFF}] ${message}."
          else
            if [[ $message =~ '--->' ]];
              then
                local message=$(echo $message | sed -e 's/.*--->://')
                echo "[ ${GREEN}--->${OFF} ] ${message}"
              else
                if [[ $message =~ 'NOTE' ]];
                  then
                    local message=$(echo $message | sed -e 's/.*NOTE://')
                    echo "[ ${RED}Note${OFF} ] ${message}."
                fi
            fi
        fi
    fi
}

#
#--------------------------------------------------------------------------------
#

function _getEDID()
{
    gDisplayVendorID_RAW=$(ioreg -lw0 | grep -i "IODisplayEDID" | sed "/[^<]*</s///" | cut -c 17-20)
    gDisplayVendorID=$((0x$gDisplayVendorID_RAW))
    gDisplayProductID_RAW=$(ioreg -lw0 | grep -i "IODisplayEDID" | sed "/[^<]*</s///" | cut -c 21-24)

    #
    # Exchange two bytes
    #
    gDisplayProduct_pr=$(echo $gDisplayProductID_RAW | cut -c 3-4)
    gDisplayProduct_st=$(echo $gDisplayProductID_RAW | cut -c 1-2)
    gDisplayProductID_sfix=$(echo $gDisplayProduct_pr$gDisplayProduct_st)
    gDisplayProductID=$((0x$gDisplayProduct_pr$gDisplayProduct_st))

    #
    # Fix an issue that will cause wrong name of DisplayProductID
    #
    if [[ $gDisplayProduct_pr == "0"* ]];
        then
            gDisplayProductID_fix=$(echo $gDisplayProductID_sfix | cut -c 2-4)
        else
            gDisplayProductID_fix=$(echo $gDisplayProductID_sfix)
    fi

#   echo $gDisplayVendorID_RAW
#   echo $gDisplayVendorID
#   echo $gDisplayProductID_RAW
#   echo $gDisplayProductID
#   echo $gDisplayProductID_fix

    gConfig=${REPO}/DisplayVendorID-$gDisplayVendorID_RAW/DisplayProductID-$gDisplayProductID_fix
}

#
#--------------------------------------------------------------------------------
#

function _printHeader()
{
    echo '<?xml version="1.0" encoding="UTF-8"?>'                                                                                       > "$gConfig"
    echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'                      >> "$gConfig"
    echo '<plist version="1.0">'                                                                                                       >> "$gConfig"
    echo '<dict>'                                                                                                                      >> "$gConfig"
    echo '	<key>DisplayProductID</key>'                                                                                               >> "$gConfig"
    echo "	<integer>${gDisplayProductID}</integer>"                                                                                   >> "$gConfig"
    echo '	<key>DisplayVendorID</key>'                                                                                                >> "$gConfig"
    echo "	<integer>${gDisplayVendorID}</integer>"                                                                                    >> "$gConfig"
    echo '	<key>scale-resolutions</key>'                                                                                              >> "$gConfig"
    echo '	<array>'                                                                                                                   >> "$gConfig"
    echo '	</array>'                                                                                                                  >> "$gConfig"
    echo '</dict>'                                                                                                                     >> "$gConfig"
    echo '</plist>'                                                                                                                    >> "$gConfig"
}

#
#--------------------------------------------------------------------------------
#

function _create_dir()
{
    if [ ! -d "$1" ];
        then
        echo "${BLUE}[Creating directory]${OFF}: $1"
        mkdir "$1"
    fi
}

#
#--------------------------------------------------------------------------------
#

function _buildconfig()
{
    _create_dir ${REPO}/backup
    rm -R ${REPO}/DisplayVendorID-*
    _create_dir ${REPO}/DisplayVendorID-$gDisplayVendorID_RAW

}

#
#--------------------------------------------------------------------------------
#

function _calcsRes()
{
	#
	# Increment i stands for adding arrays.
	#
    i=0

        while [ "$gRes_RAW" != 0 ];
        do
        	read -p "Enter the Resolution you want to enable HiDPI(If you want to stop adding or say you just add enough number of HiDPI resolution you want, enter 0: " gRes_RAW

            if [[ $gRes_RAW != 0 ]];
                then
            		#
            		# Raw Datas
            		#
            		gHeightVAL=$(echo $gRes_RAW | cut -f 1 -d "x")
            		gWideVAL=$(echo $gRes_RAW | cut -f 2 -d "x")


            		#
            		# HiDPI (note that for enable HiDPI, all Height and Val must be twice
            		#
            		gHeight_HiDPI_VAL=$(echo $((gHeightVAL*2)))
            		gWide_HiDPI_VAL=$(echo $((gWideVAL*2)))
            		#echo $gHeight_HiDPI_VAL
            		#echo $gWide_HiDPI_VAL

            		#
            		# Convet Height and Wide(decimal) into hex
            		#
            		gHeight=$(echo "obase=16;$gHeightVAL" | bc)
            		gWide=$(echo "obase=16;$gWideVAL" | bc)

            		gHeight_HiDPI=$(echo "obase=16;$gHeight_HiDPI_VAL" | bc)
            		gWide_HiDPI=$(echo "obase=16;$gWide_HiDPI_VAL" | bc)

            		#
            		# Generate Resolution Values (Hex)
            		#
            		gRes_VAL=$(echo "00000$gHeight 00000$gWide 00000001 00200000")
            		gRes_HiDPI_VAL=$(echo "00000$gHeight_HiDPI 00000$gWide_HiDPI 00000001 00200000")

            		#
            		# Encode Resolution Values(Hex) into base64
            		#
            		gRes_ENCODE=$(echo $gRes_VAL | xxd -r -p | base64)
            		gRes_HiDPI_ENCODE=$(echo $gRes_HiDPI_VAL | xxd -r -p | base64)

            		#
            		# Inject HiDPI values.
            		#
            		/usr/libexec/plistbuddy -c "Add ':scale-resolutions:$i' string" $gConfig
            		/usr/libexec/plistbuddy -c "Set ':scale-resolutions:$i' $gRes_ENCODE" $gConfig

            		/usr/libexec/plistbuddy -c "Add ':scale-resolutions:$((i+1))' string" $gConfig
            		/usr/libexec/plistbuddy -c "Set ':scale-resolutions:$((i+1))' $gRes_HiDPI_ENCODE" $gConfig

            		perl -pi -e 's/string/data/g' $gConfig
                	gRes_RAW=""
                	i=$(($i+1))
        	fi

    	done
}

#
#--------------------------------------------------------------------------------
#

function _OSCheck()
{
    #
    # Extract minor version (eg. 10.9 vs. 10.10 vs. 10.11)
    #
    MINOR_VER=$([[ "$(sw_vers -productVersion)" =~ [0-9]+\.([0-9]+) ]] && echo ${BASH_REMATCH[1]})
    if [[ $MINOR_VER -ge 11 ]]; 
        then
            gDespath=$(echo "/System/Library/Displays/Contents/Resources/Overrides/")
        else
            gDespath=$(echo "/System/Library/Displays/Overrides/")
    fi
}

#
#--------------------------------------------------------------------------------
#

function _patch()
{
	#
	# Count number indicates patch system or not.
	#
	if [ $i != 0 ];
		then
			_PRINT_MSG "--->: Backuping origin Display Information..."
			sudo cp -R "$gDespath" ${REPO}/backup
			sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool YES
			sudo defaults delete /Library/Preferences/com.apple.windowserver DisplayResolutionDisabled 2>&1 >/dev/null
			sudo cp -R "${REPO}/DisplayVendorID-$gDisplayVendorID_RAW" "$gDespath"
			_PRINT_MSG "OK: Done, Please Reboot to see the change! Pay attention to use Retina Menu Display to select the HiDPI resolution!"
		else
			_PRINT_MSG "NOTE: Since you stop the operation, don't worry all your files in system hasnt been touched."
	fi
}

#
#--------------------------------------------------------------------------------
#

function main()
{
    _getEDID
    _buildconfig
    _printHeader
    _calcsRes
    _OSCheck
    _patch
}

#==================================== START =====================================

main

#================================================================================

exit 0