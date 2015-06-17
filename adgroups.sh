#!/bin/sh

# custom user-related conditions:
# console_user_ad_group_member_of: list of AD groups the current console user is a member of

DEFAULTS=/usr/bin/defaults
MUNKI_DIR=$($DEFAULTS read /Library/Preferences/ManagedInstalls ManagedInstallDir)
COND_DOMAIN="$MUNKI_DIR/ConditionalItems"
NET_DOMAIN=$(dsconfigad -show | grep "Directory Domain" | awk -F"= " '{print $2}' | awk -F"." '{print $1}' | tr [a-z] [A-Z])

CONSOLE_USER=$(who | grep console | grep -v _ | awk '{print $1}')
USER_AD_GROUPS=$(dscl /Active\ Directory/$NET_DOMAIN/All\ Domains -read /Users/$CONSOLE_USER dsAttrTypeNative:memberOf | sed -e 's/.*CN=//g;s/,OU=.*//g')
IFS=$'\n'

for GROUP_NAME in $USER_AD_GROUPS; do
	echo $GROUP_NAME
	$DEFAULTS write "$COND_DOMAIN" console_user_ad_group_member_of -array-add "$GROUP_NAME"
done
