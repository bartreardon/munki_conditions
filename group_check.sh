#!/bin/sh

# security groups to check
#declare -a GROUP_ARRAY=("ACL_SCCM_WebExProdToolsTestUsers_Install" \
#						"ACL_SCCM_WebExProdTools_Install")

DEFAULTS=/usr/bin/defaults
MUNKI_DIR=$($DEFAULTS read /Library/Preferences/ManagedInstalls ManagedInstallDir)
COND_DOMAIN="$MUNKI_DIR/ConditionalItems"
GROUPFILE="$MUNKI_DIR/Group_List"

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

# determine is user is included in the right group

while read LINE; do
	GROUP_MEMBERSHIP=$(dsmemberutil checkmembership -U "$USER_ACC" -G "$LINE")

	if [[ $GROUP_MEMBERSHIP == "user is a member of the group" ]]; then
		#exit 0
		$DEFAULTS write "$COND_DOMAIN" "$LINE" -bool TRUE
	else
		#exit 1
		$DEFAULTS write "$COND_DOMAIN" "$LINE" -bool FALSE
	fi
done < "$GROUPFILE"

exit 0
