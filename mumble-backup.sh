#!/bin/bash
# Daily, Weekly, Monthly backups of mumble sqlite DB
# version 1

# Where is your mumble sqlite DB?
mumbledbdir=/var/lib/mumble-server/
# What is the file called?
mumbledb=mumble-server.sqlite
# Where do you want to store the backups?
backupdir=/root/mumble-db-backups
# How many days do you want to keep by default?
globalnumdays=7


todayslog=/var/log/mumble-backup.$(date +%Y%m%d)
#
# basic usage
#

function usage ()
{
	echo "Usage:"
	echo $0" [backup | -b | --backup] : perform a backup"
	echo $0" [cleanup | -b | --cleanup] : perform a cleanup"
	echo -e "\t optional: [-d days]: specify the number of days to keep"
	echo $0" [restore | -b | --restore] : perform a restore"
}

#
# Take a backup
#
function backup ()
{
	# check backupdir exists first
	if [ -d $backupdir ]; then
		echo "Starting Backup"
		# copy the file
		cp $mumbledbdir/$mumbledb $backupdir/$mumbledb.$(date +%Y%m%d) >> $todayslog
		# did copy run into issues?
		exit=$?
		if [ $exit -eq 0 ]; then
			echo "Finished Backup, no errors seen"
		else
			echo "Finished Backup, errors seen, check "$todayslog" for more information"
			exit 1
		fi
	else
		echo "Backup directory does not exist, expecting the path "$backupdir
		exit 1
	fi
}

#
# Clean up the backup directory
#
function cleanup () 
{
	echo "Staring Cleanup"
		echo "Deleting backups older than "$1" days"
		# find all files in the directory that are older than numdays (specified above), and remove them
		find $backupdir -mtime +$1 -exec rm -f {} \;
		# did find encounter any issues
		exit=$?
		if [ $exit -gt 0 ]; then
			echo "Finished Cleanup with Errors, check "$todayslog" for more information"
			exit 1
		fi
	echo "Finished Cleanup with no errors"
}

#
# Easily restore a backup (not finished)
#

function restorebackup () 
{
	echo "not finished yet"
	exit 1
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
		-c | --cleanup | backup)
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
			echo "Unexpected command switch"
			exit 1
	esac
done
