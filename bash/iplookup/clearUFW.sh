#!/bin/bash
############################################################################
#	clearUFW.sh
#	  Author:         Jack	
#   Last revised:   2023-02-13	
#	  Description:	  Clears DENY rules from UFW. For testing functionality
#                   of iplookup.sh
#   Usage:          sudo ./clearUFW.sh
#
#   Note:           May need to run chmod +x clearUFW.sh before this will
#                   work
############################################################################
DEFAULT="\e[39m"
RED="\e[31m"
BLUE="\e[34m"
GREEN="\e[32m"
PURPLE="\e[35m"
CYAN="\e[36m"
HORIZONTAL_LINE="======================================="

denies=$(ufw status numbered \
        | head -n-1 \
        | tail -n1 \
        | grep -Eo "\[.+\]" \
        | grep -Eo [0-9]+)

echo "Checking [$denies] rules..."

# delete DENY rules from UFW
for (( i=$denies; i>0; i-- )); do
  rule=$(ufw status numbered | grep -E "^\[ ?$i\]|\[$i\]")
  allowed=$(ufw status numbered | grep -E "^\[ ?$i\]" | grep -E "ALLOW IN")
  status="$?"

  if (($status > 0))
   then
     printf $PURPLE"$rule\n"
     printf ">>> Rule #[ $i ] is DENY ... deleting rule"
     sleep .1s
     ufw --force delete $i > /dev/null 2>&1
     printf "  ...deleted\n\n"$DEFAULT
   else
     printf $CYAN"$rule\n"
     printf ">>> Rule #[ $i ] is ALLOW ... leaving in place\n\n"$DEFAULT
   fi

done

exit 0

