#!/bin/bash
# Daily, Weekly, Monthly backups of mumble sqlite DB
# version 2
# TODO: add backing up/restoring the config

# Where is your mumble sqlite DB?
mumbledbdir="/var/lib/mumble-server"
# What is the file called?
mumbledb="mumble-server.sqlite"
# Where do you want to store the backups?
backupdir="/root/mumble-db-backups"
# How many days do you want to keep by default?
globalnumdays=7
# User mumble runs under (usually the same as mumblegroup which is by default mumble-server)
mumbleuser="mumble-server"
# Group mumble user is in 
mumblegroup=$mumbleuser

#
# basic usage
#
function usage ()
{
	echo "Usage: "$0" [-b|backup|--backup] [-c|cleanup|--cleanup [-d days]] [-r|restore|--restore [-y]]"
	echo -e "  -b, [--]backup \tperform a backup"
	echo -e "  -c, [--]cleanup \tperform a cleanup (use -d to specify the number of days to keep)"
	echo -e "  -r, [--]restore \tperform a restore (use -y to blindly restore from yesterday's backup)"
}

# 
# Bad command entered
#
function badcommand ()
{
	echo "$(timestamp)Bad command, check --help for usage"
}

#
# Take a backup
#
function backup ()
{
	# check backupdir exists first
	if [ -d $backupdir ]; then
		echo "$(timestamp)Starting Backup"
		# copy the file
		cp $mumbledbdir/$mumbledb $backupdir/$mumbledb.$(date +%Y%m%d)
		# did copy run into issues?
		exit=$?
		if [ $exit -eq 0 ]; then
			echo "$(timestamp)Finished Backup with no errors"
		else
			echo "$$(timestamp)ERROR: Finished Backup with errors"
			exit 1
		fi
	else
		echo "$(timestamp)ERROR: Backup directory does not exist, expecting the path "$backupdir
		exit 1
	fi
}

#
# Clean up the backup directory
# Arguments: number of days to keep
#
function cleanup () 
{
	echo "$(timestamp)Staring Cleanup"
		echo "$(timestamp)Deleting Backups older than "$1" days"
		# find all files in the directory that are older than numdays (specified above), and remove them
		find $backupdir -mtime +$1 -exec rm -f {} \;
		# did find encounter any issues
		exit=$?
		if [ $exit -gt 0 ]; then
			echo "$(timestamp)ERROR: Finished Cleanup with errors"
			exit 1
		fi
	echo "$(timestamp)Finished Cleanup with no errors"
}

#
# Easily restore a backup (not finished)
# Arguments: Mode (y means yesterday, anything else and it will interactively let you restore a backup)
#
function restorebackup () 
{
	# Override menu and just restore yesterday's file
	if [[ $1 == "y" ]]; then
		restorefile=$backupdir"/"$mumbledb"."$(date -d "yesterday" '+%Y%m%d')
	else
		echo "Choose a backup to restore from:"
		# cause the array we're creating to be empty if there are no files
		shopt -s nullglob
		# put the files in the backup directory into the $files array
		files=($backupdir/*)
		# temporary counter
		i=1
		for file in "${files[@]}"; do
			echo $i": "$file
			let i=i+1
		done
		read choice
		# arrays start at 0, not 1
		let choice=choice-1
		restorefile=${files[$choice]}		
	fi
	if [ -f "$restorefile" ]; then
		echo "$(timestamp)Stopping mumble..."
		# Stop mumble, overwrite the DB, and restart it
		# if there are errors, the script will continue and try to re-start mumble (in case it has permissions to stop/start but no permissions to restore DB, for example)
		service mumble-server stop
		exit=$?
		if [ $exit -gt 0 ]; then
			echo "$(timestamp)ERROR: Unable to stop mumble, are you root?"
			exit 1
		fi
		echo "$(timestamp)Restoring..."
		# set a variable that flags if we've had an error
		backuperror=0
		cp $restorefile $mumbledbdir/$mumbledb
		exit=$?
		if [ $exit -gt 0 ]; then
			echo "$(timestamp)ERROR: Error restoring from backup!"
			backuperror=1
		fi
		chown $mumbleuser:$mumblegroup $mumbledbdir/$mumbledb
		exit=$?
		if [ $exit -gt 0 ]; then
			echo "$(timestamp)ERROR: Error setting permissions!"
			backuperror=1
		fi
		echo "$(timestamp)Starting mumble..."
		service mumble-server start
		if [ $exit -gt 0 ]; then
			echo "$(timestamp)ERROR: Unable to start mumble, is it already running?"
			exit 1
		fi
			if [ $backuperror -gt 0 ]; then
				echo "$(timestamp)ERROR: Unable to restore from "$restorefile" but was able to re-start mumble"
			else
				echo "$(timestamp)Successfully restored from "$restorefile" and restarted mumble"
			fi
	else
		echo "$(timestamp)ERROR: File to restore from does not exist"
		exit 1
	fi
}

#
# Add a specially formatted timestamp
#
function timestamp ()
{
	date "+[%H:%M:%S] %m-%d-%Y : "
}

# User did not specify any arguments
if [[ $# -eq 0 ]]; then
	usage
	exit 1
fi

# What does the user want?
while [ $# -ne 0 ]; do
	case "$1" in
		-h | --help | help)
			usage
			break
			;;
		-b | --backup | backup)
			# shift here so any further parameters are passed to the command
			shift
			backup
			;;
		-c | --cleanup | cleanup)
			shift
			# if -d was specified after cleanup, then user wanted to specify the number of days to keep.  store that in a variable here
			if [[ $1 == "-d" ]]; then
				shift
				numdays=$1
				shift
			else
				numdays=$globalnumdays
			fi
			cleanup $numdays
			;;
		-r | --restore | restore)
			shift
			# if -y was specified, we're automatically assuming restoring yesterday's backup
			if [[ $1 == "-y" ]]; then
				shift
				mode="y"
			else
				mode="n"
			fi
			restorebackup $mode
			;;
		*)
			badcommand
			exit 1
	esac
done
