# mumble-backup
Script for maintaining backups of a Mumble SQLite DB

## Usage:
Edit the settings near the top of the script to match your configuration

Command-line switches:

<pre>-b, [--]backup          perform a backup

-c, [--]cleanup         perform a cleanup (use -d to specify the number of days to keep)
  
-r, [--]restore         perform a restore (use -y to blindly restore from yesterday's backup)</pre>

##Example commands:

`./mumble-backup.sh -b --cleanup -d 28`

Backs up and then performs a cleanup keeping 28 days of backups

`./mumble-backup.sh restore`

Allows you to interactively choose a backup to restore from
