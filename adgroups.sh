#!/bin/sh

# custom user-related conditions:
# console_user_ad_group_member_of: list of AD groups the current console user is a member of

DEFAULTS=/usr/bin/defaults
MUNKI_DIR=$($DEFAULTS read /Library/Preferences/ManagedInstalls ManagedInstallDir)
COND_DOMAIN="$MUNKI_DIR/ConditionalItems"

# get AD info
AD_PLIST=$(ls /Library/Preferences/OpenDirectory/Configurations/Active\ Directory/)
AD_NODE=$(defaults read /Library/Preferences/OpenDirectory/Configurations/Active\ Directory/$AD_PLIST "node name")

# determine the current console user
CONSOLE_USER=$(who | grep console | cut -d ' ' -f1)

# determine the main user of the machine
AC_RESULT=$(ac -p | awk '!/total/' | sort -rnk 2 | head -n 1)
MOST_USER=$(echo "$AC_RESULT" | awk '{print $1}')

# run test based on the current console user - if no console user, take the user with the most time on the machine.
if [[ $CONSOLE_USER != "" ]]; then
	USER_ACC=$CONSOLE_USER
else
	USER_ACC=$MOST_USER
fi

USER_AD_GROUPS=$(dscl "$AD_NODE/All Domains" -read /Users/$USER_ACC dsAttrTypeNative:memberOf | sed -e 's/.*CN=//g;s/,OU=.*//g')
IFS=$'\n'

for GROUP_NAME in $USER_AD_GROUPS; do
	echo $GROUP_NAME
	$DEFAULTS write "$COND_DOMAIN" console_user_ad_group_member_of -array-add "$GROUP_NAME"
done

