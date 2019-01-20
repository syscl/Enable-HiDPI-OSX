#!/bin/sh

#  enable-HiDPI.sh
#  
#
#  Created by syscl/lighting/Yating Zhou on 16/3/2.
#

#================================= GLOBAL VARS ==================================

#
# The script expects '0.5' but non-US localizations use '0,5' so we export
# LC_NUMERIC here (for the duration of the enable-HiDPI.sh) to prevent errors.
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
gDisplayProductID_reverse=""
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
gDstPath=""
# gBak_Time=$(date +%Y-%m-%d-h%H_%M_%S)
gBak_Time=$(date +%Y-%m-%d@%H_%M_%S)
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
        echo '         Table of monitors          '
        echo '------------------------------------'
        echo '  Index  |  VendorID  |  ProductID  '
        echo '------------------------------------'
        for display in "${gDisplayInf[@]}"
        do
          let index++
          #
          # Show monitors.
          #
          printf "    %d    |    ${display:16:4}    |    ${display:20:4}\n" $index
        done
        #
        # Close the table
        #
        echo '------------------------------------'
        #
        # Let user make a selection.
        #
        printf 'Choose the display to enable HiDPI'
        if [[ "${#gDisplayInf[@]}" == 2 ]]; then
            printf "[${STYLE_UNDERLINED}E${OFF}xit/1/2]"
        else
            printf "[${STYLE_UNDERLINED}E${OFF}xit/1-${index}]"
        fi
        read -p ": " selection
        case "$(_toLowerCase $selection)" in
        e|exit       ) echo "Abort."
                       exit -0
                       ;;

        [[:digit:]]* ) #
                       # Lower selection (arrays start at zero).
                       #
                       let selection-=1
                       gMonitor=${gDisplayInf[$selection]}
                       ;;

        *            )  if [[ "${#gDisplayInf[@]}" == 2  ]]; then
                            echo 'Invalid menu action, enter 1 or 2'
                        else
                            echo "Invalid menu action, enter valid number among 1, ..., ${index}"
                        fi
                       ;;
        esac
      else
        gMonitor=${gDisplayInf}
    fi
    #
    # Fix for issue #16 and #32
    #
    if [[ ${gMonitor:16:1} == 0 ]]; then
        # get rid of the prefix 0
        gDisplayVendorID_RAW=${gMonitor:17:3}
    else
        gDisplayVendorID_RAW=${gMonitor:16:4}
    fi
    # convert from hex to dec
    gDisplayVendorID=$((0x$gDisplayVendorID_RAW))
    gDisplayProductID_RAW=${gMonitor:20:4}
    #
    # Exchange two bytes
    #
    # Fix an issue that will cause wrong name of DisplayProductID
    #
    if [[ ${gDisplayProductID_RAW:2:1} == 0 ]]; then
        # get rid of the prefix 0
        gDisplayProduct_pr=${gDisplayProductID_RAW:3:1}
    else
        gDisplayProduct_pr=${gDisplayProductID_RAW:2:2}
    fi
    gDisplayProduct_st=${gDisplayProductID_RAW:0:2}
    gDisplayProductID_reverse="${gDisplayProduct_pr}${gDisplayProduct_st}"
    gDisplayProductID=$((0x$gDisplayProduct_pr$gDisplayProduct_st))

#   echo $gDisplayVendorID_RAW
#   echo $gDisplayVendorID
#   echo $gDisplayProductID_RAW
#   echo $gDisplayProductID

    gConfig=${REPO}/DisplayVendorID-$gDisplayVendorID_RAW/DisplayProductID-$gDisplayProductID_reverse
}

#
#--------------------------------------------------------------------------------
#

function _printHeader()
{
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
    echo '<plist version="1.0">'
    echo '<dict>'
    printf '\t<key>DisplayProductID</key>\n'
    printf "\t<integer>${gDisplayProductID}</integer>\n"
    printf '\t<key>DisplayVendorID</key>\n'
    printf "\t<integer>${gDisplayVendorID}</integer>\n"
    printf '\t<key>scale-resolutions</key>\n'
    printf '\t<array>\n'
}

#
#--------------------------------------------------------------------------------
#

function _closeField()
{
    printf '\t</array>\n'
    echo '</dict>'
    echo '</plist>'
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
        _tidy_exec "rm -R ${target_file}" "Remove old ${target_file}"
      else
        if [ -f ${target_file} ];
          then
            _tidy_exec "rm ${target_file}" "Remove old ${target_file}"
        fi
    fi
}

#
#--------------------------------------------------------------------------------
#

function _cleanup()
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
      printf "Enter the HiDPI resolution (e.g. 1600x900, 1440x910, ...), ${BOLD}0${OFF} to quit"
      read -p ": " gRes_RAW

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
          gRes_ENCODE=$(printf $gRes_VAL | xxd -r -p | base64)
          gRes_HiDPI_ENCODE=$(printf $gRes_HiDPI_VAL | xxd -r -p | base64)

          #
          # Inject HiDPI values.
          #
          printf "\t\t<data>${gRes_HiDPI_ENCODE}</data>\n" >> "$gConfig"

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
        gDstPath="/System/Library/Displays/Contents/Resources/Overrides"
      else
        gDstPath="/System/Library/Displays/Overrides"
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
        _tidy_exec "cp -R "$gDstPath" ${gBak_Dir}" "Backup $gDstPath"
        sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool YES

        if [ -f "/Library/Preferences/com.apple.windowserver" ];
          then
            sudo defaults delete /Library/Preferences/com.apple.windowserver DisplayResolutionDisabled 2>&1 >/dev/null
        fi

        sudo cp -R "${REPO}/DisplayVendorID-$gDisplayVendorID_RAW" "$gDstPath"
        _PRINT_MSG "OK: Done. Reboot then use Retina Display Menu (RDM) to select the HiDPI resolution just injected!"
      else
        _PRINT_MSG "NOTE: All system files remain unchanged."
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
    _cleanup
    _printHeader > "$gConfig"
    _calcsRes
    _closeField  >>"$gConfig"
    _OSCheck
    _patch
}

#==================================== START =====================================

main "$@"

#================================================================================

exit 0
