#!/bin/sh

# custom user-related conditions:
# console_user_ad_group_member_of: list of AD groups the current console user is a member of

DEFAULTS=/usr/bin/defaults
MUNKI_DIR=$($DEFAULTS read /Library/Preferences/ManagedInstalls ManagedInstallDir)
COND_DOMAIN="$MUNKI_DIR/ConditionalItems"

# get AD info
AD_NODE=$(dscl localhost -list "/Active Directory")

if [[ $AD_NODE == "" ]; then
	echo "Not joined to a domain - exiting"
	exit 0
fi

# determine the current console user
CONSOLE_USER=$(who | grep console | cut -d ' ' -f1)

# run test based on the current console user - if no console user, take the user with the most time on the machine.
if [[ $CONSOLE_USER != "" ]]; then
	USER_ACC=$CONSOLE_USER
else
	# determine the main user of the machine
	AC_RESULT=$(ac -p | awk '!/total/' | sort -rnk 2 | head -n 1)
	USER_ACC=$(echo "$AC_RESULT" | awk '{print $1}')
fi

USER_AD_GROUPS=$(dscl "/Active Directory/$AD_NODE/All Domains" -read /Users/$USER_ACC dsAttrTypeNative:memberOf | sed -e 's/.*CN=//g;s/,OU=.*//g')
IFS=$'\n'

for GROUP_NAME in $USER_AD_GROUPS; do
	echo $GROUP_NAME
	$DEFAULTS write "$COND_DOMAIN" console_user_ad_group_member_of -array-add "$GROUP_NAME"
done

