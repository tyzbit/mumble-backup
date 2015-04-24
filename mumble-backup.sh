#!/bin/bash
# Daily, Weekly, Monthly backups of mumble sqlite DB
# version 2
# TODO: restore functionality

# Where is your mumble sqlite DB?
mumbledbdir=/var/lib/mumble-server
# What is the file called?
mumbledb=mumble-server.sqlite
# Where do you want to store the backups?
backupdir=/root/mumble-db-backups
# How many days do you want to keep by default?
globalnumdays=7


log=/var/log/mumble-backup.log
#
# basic usage
#

function usage ()
{
	echo "Usage: "$0" [-b|backup|--backup] [-c|cleanup|--cleanup [-d days]] [-r|restore|--restore]"
	echo -e "  -b, [--]backup \tperform a backup"
	echo -e "  -c, [--]cleanup \tperform a cleanup (use -d to specify the number of days to keep)"
	echo -e "  -r, [--]restore \tperform a restore"
}

#
# Take a backup
#
function backup ()
{
	# check backupdir exists first
	if [ -d $backupdir ]; then
		echo $(timestamp)"Starting Backup"
		# copy the file
		cp $mumbledbdir/$mumbledb $backupdir/$mumbledb.$(date +%Y%m%d) >> $log
		# did copy run into issues?
		exit=$?
		if [ $exit -eq 0 ]; then
			echo $(timestamp)"Finished Backup with no errors"
		else
			echo $(timestamp)"Finished Backup, errors seen, check "$log" for more information"
			exit 1
		fi
	else
		echo $(timestamp)"Backup directory does not exist, expecting the path "$backupdir
		exit 1
	fi
}

#
# Clean up the backup directory
# Arguments: number of days to keep
#
function cleanup () 
{
	echo $(timestamp)"Staring Cleanup"
		echo $(timestamp)"Deleting Backups older than "$1" days"
		# find all files in the directory that are older than numdays (specified above), and remove them
		find $backupdir -mtime +$1 -exec rm -f {} \;
		# did find encounter any issues
		exit=$?
		if [ $exit -gt 0 ]; then
			echo $(timestamp)"Finished Cleanup with Errors, check "$log" for more information"
			exit 1
		fi
	echo $(timestamp)"Finished Cleanup with no errors"
}

#
# Easily restore a backup (not finished)
#

function restorebackup () 
{
	echo "not finished yet"
	exit 1
}

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
			restorebackup
			break
			;;
		*)
			echo $(timestamp)"Bad command, check --help for usage"
			exit 1
	esac
done
