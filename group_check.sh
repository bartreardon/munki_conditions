#!/bin/sh

# custom user-related conditions:
# read list of groups from file and determin if the user is a member of the group
# condition created is group_name == TRUE/FALSE

DEFAULTS=/usr/bin/defaults
MUNKI_DIR=$($DEFAULTS read /Library/Preferences/ManagedInstalls ManagedInstallDir)
COND_DOMAIN="$MUNKI_DIR/ConditionalItems"
GROUP_LIST="$MUNKI_DIR/Group_List"

if [ ! -f "$GROUP_LIST" ]; then
	touch "$GROUP_LIST"
	#no point continuing at this stage is the group list file wasn't there to begin with
	exit 0
fi
# determine the current console user
CONSOLE_USER=$(who | grep console | cut -d ' ' -f1)

# run test based on the current console user - if no console user, take the user with the most time on the machine.
if [[ $CONSOLE_USER != "" ]]; then
	USER_ACC=$CONSOLE_USER
else
	# Console user failed - determine the main user of the machine
	AC_RESULT=$(ac -p | awk '!/total/' | sort -rnk 2 | head -n 1)
	USER_ACC=$(echo "$AC_RESULT" | awk '{print $1}')
fi

# determine is user is included in the right group
while read LINE; do
	GROUP_MEMBERSHIP=$(dsmemberutil checkmembership -U "$USER_ACC" -G "$LINE")

	if [[ $GROUP_MEMBERSHIP == "user is a member of the group" ]]; then
		IS_MEMBER="TRUE"
	else
		IS_MEMBER="FALSE"
	fi

	$DEFAULTS write ""$COND_DOMAIN" "$LINE" -bool $IS_MEMBER

done < "$GROUP_LIST"

exit 0
