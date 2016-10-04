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
STYLE_UNDERLINED="\e[4m"

#
# Define two status: 0 - Success, Turn on,
#                    1 - Failure, Turn off
#
kBASHReturnSuccess=0
kBASHReturnFailure=1

#
# Repository location
#
REPO=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

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
gBak_Time=$(date +%Y-%m-%d-h%H_%M_%S)
gBak_Dir="${REPO}/Display-Backups/${gBak_Time}"

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

    case "$message" in
      OK*    ) local message=$(echo $message | sed -e 's/.*OK://')
               echo "[  ${GREEN}OK${OFF}  ] ${message}."
               ;;

      FAILED*) local message=$(echo $message | sed -e 's/.*://')
               echo "[${RED}FAILED${OFF}] ${message}."
               ;;

      ---*   ) local message=$(echo $message | sed -e 's/.*--->://')
               echo "[ ${GREEN}--->${OFF} ] ${message}"
               ;;

      NOTE*  ) local message=$(echo $message | sed -e 's/.*NOTE://')
               echo "[ ${RED}Note${OFF} ] ${message}."
               ;;
    esac
}

#
#--------------------------------------------------------------------------------
#

function _tidy_exec()
{
    if [ $gDebug -eq 0 ];
      then
        #
        # Using debug mode to output all the details.
        #
        _PRINT_MSG "DEBUG: $2"
        $1
      else
        #
        # Make the output clear.
        #
        $1 >/tmp/report 2>&1 && RETURN_VAL=${kBASHReturnSuccess} || RETURN_VAL=${kBASHReturnFailure}

        if [ "${RETURN_VAL}" == ${kBASHReturnSuccess} ];
          then
            _PRINT_MSG "OK: $2"
          else
            _PRINT_MSG "FAILED: $2"
            cat /tmp/report
        fi

        rm /tmp/report &> /dev/null
    fi
}

#
#--------------------------------------------------------------------------------
#

function _find_plistbuddy()
{
    #
    # Check if plistBuddy is in place.
    #
    if [ ! -f /usr/libexec/plistbuddy ];
      then
        _PRINT_MSG "--->: Downloading plistbuddy ..."
        _tidy_exec "sudo curl https://raw.github.com/syscl/Enable-HiDPI-OSX/master/Tools/plistbuddy -o /usr/libexec/plistbuddy --create-dirs" "Install plistbuddy"
        _tidy_exec "sudo chmod +x /usr/libexec/plistbuddy" "Change the permissions of plistbuddy (add +x) so that it can be run"
    fi
}

#
#--------------------------------------------------------------------------------
#

function _getEDID()
{
    local index=0
    local selection=0

    gDisplayInf=($(ioreg -lw0 | grep -i "IODisplayEDID" | sed -e "/[^<]*</s///" -e "s/\>//"))

    if [[ "${#gDisplayInf[@]}" -ge 2 ]];
      then
        #
        # Multi monitors detected. Choose target monitor.
        #
        echo " Multi monitors detected, please choose target monitor: "
        for display in "${gDisplayInf[@]}"
        do
          let index++
          #
          # Show monitors.
          #
          printf " [ %d ] ${display:16:4}::${display:20:4}" $index
          echo ''
        done
        #
        #
        #
        echo ''
        #
        # Let user make a selection.
        #
        printf "Please choose the desired display for enable Hi-DPI (${STYLE_UNDERLINED}E${OFF}xit/1-${index})"
        read -p " ? " selection
        case "$(_toLowerCase $selection)" in
        e|exit       ) echo "Abort script."
                       exit -0
                       ;;

        [[:digit:]]* ) #
                       # Lower selection (arrays start at zero).
                       #
                       let selection-=1
                       gMonitor=${gDisplayInf[$selection]}
                       ;;

        *            ) echo "Invalid menu action, please type valid among 1, ..., ${index}"
                       ;;
        esac
      else
        gMonitor=${gDisplayInf}
    fi

    gDisplayVendorID_RAW=${gMonitor:16:4}
    gDisplayVendorID=$((0x$gDisplayVendorID_RAW))
    gDisplayProductID_RAW=${gMonitor:20:4}

    #
    # Exchange two bytes
    #
    gDisplayProduct_pr=${gDisplayProductID_RAW:2:2}
    gDisplayProduct_st=${gDisplayProductID_RAW:0:2}
    gDisplayProductID_sfix=$(echo $gDisplayProduct_pr$gDisplayProduct_st)
    gDisplayProductID=$((0x$gDisplayProduct_pr$gDisplayProduct_st))

    #
    # Fix an issue that will cause wrong name of DisplayProductID
    #
    if [[ $gDisplayProduct_pr == "0"* ]];
      then
        gDisplayProductID_fix=${gDisplayProductID_sfix:1:3}
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
    echo '  <key>dmdg</key>'                                                                                                           >> "$gConfig"
    echo '  <data>AAAAAg==</data>'                                                                                                     >> "$gConfig"
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
        mkdir -p "$1"
    fi
}

#
#--------------------------------------------------------------------------------
#

function _del()
{
    local target_file=$1

    if [ -d ${target_file} ];
      then
        _tidy_exec "sudo rm -R ${target_file}" "Remove ${target_file}"
      else
        if [ -f ${target_file} ];
          then
            _tidy_exec "sudo rm ${target_file}" "Remove ${target_file}"
        fi
    fi
}

#
#--------------------------------------------------------------------------------
#

function _buildconfig()
{
    _create_dir ${gBak_Dir}
    _del ${REPO}/DisplayVendorID-*
    _create_dir ${REPO}/DisplayVendorID-$gDisplayVendorID_RAW
}

#
#--------------------------------------------------------------------------------
#

function _toLowerCase()
{
    echo "`echo $1 | tr '[:upper:]' '[:lower:]'`"
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
      read -p "Enter the Resolution you want to enable HiDPI(e.g. 1600x900, 1440x910, ...), enter 0 to quit: " gRes_RAW

      if [[ $gRes_RAW != 0 ]];
        then
          #
          # Raw Datas
          #
          gHeightVAL=$(echo $gRes_RAW | cut -f 1 -d "x")
          gWideVAL=$(echo $gRes_RAW | cut -f 2 -d "x")


          #
          # Generate Resolution Values (Hex)
          #
          gRes_VAL=$(printf '%08x %08x 00000001 02000000' $gHeightVAL $gWideVAL)
          # HiDPI is twice the size.
          gRes_HiDPI_VAL=$(printf '%08x %08x 00000001 02000000' $((gHeightVAL*2)) $((gWideVAL*2)))

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
        sudo cp -R "$gDespath" ${gBak_Dir}
        sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool YES

        if [ -f "/Library/Preferences/com.apple.windowserver" ];
          then
            sudo defaults delete /Library/Preferences/com.apple.windowserver DisplayResolutionDisabled 2>&1 >/dev/null
        fi

        sudo cp -R "${REPO}/DisplayVendorID-$gDisplayVendorID_RAW" "$gDespath"
        _PRINT_MSG "OK: Done, Please Reboot to see the change! Pay attention to use Retina Display Menu(RDM) to select the HiDPI resolution!"
      else
        _PRINT_MSG "NOTE: Since you stop the operation, don't worry all your files in system hasnt been touched."
    fi
}

#
#--------------------------------------------------------------------------------
#

function main()
{
    #
    # Get argument.
    #
    gArgv=$(echo "$@" | tr '[:lower:]' '[:upper:]')
    if [[ $# -eq 1 && "$gArgv" == "-D" || "$gArgv" == "-DEBUG" ]];
      then
        #
        # Yes, we do need debug mode.
        #
        _PRINT_MSG "NOTE: Use ${BLUE}DEBUG${OFF} mode"
        gDebug=0
      else
        #
        # No, we need a clean output style.
        #
        gDebug=1
    fi

    _getEDID
    _buildconfig
    _printHeader
    _calcsRes
    _OSCheck
    _patch
}

#==================================== START =====================================

main "$@"

#================================================================================

exit 0
