#!/bin/bash

# Author: Chritoph Schild <cvs46@nau.edu>
# This program enables the semi-efficient monitoring of the Slurm backfill log
# by enabling the "DebugFlags=Backfill" parameter in slurm.conf and then disabling it
# a predetermined amount of time. During the time it's enabled, we check if the backfill has occured.

# Time to collect sample (in seconds)
SAMPLETIME=30

# Slurm config file
SLURMCONFIG="/home/cvs46/backfill_v2/slurm.conf"

# Slurmctld log
SLURMCTLDLOG="/var/log/slurm/slurmctld.log"

# Comment to include in config file
CONFCOMMENT="# Edited by Backfill Monitor"

# Log File
LOGFILE="/home/cvs46/backfill_log.txt"

# All good action
SUCCESS="echo All good"

# Backfill issue
FAILURE="echo There was an issue."


################# Enable Debugging, Wait, Disable and Listen #############################

# Uncomment backfill line
sudo sed -i 's/#DebugFlags=Backfill/DebugFlags=Backfill/' $SLURMCONFIG

# Kill process
kill -1 $(pgrep slurmctld)

# Sleep
sleep $SAMPLETIME

# Reinstate comment
sudo sed -i 's/DebugFlags=Backfill/#DebugFlags=Backfill/' $SLURMCONFIG


############ Get data from logs regarding backfill ######################################

# Get date of last backfill
OLDDATE=$(sudo tac /var/log/slurm/slurmctld.log | grep 'backfill: reached end of job queue' -m 1| cut -d '.' -f 1 | cut -d '[' -f 2 | tr -s 'T' ' ')

# Check if date is blank (no backfill records) exit with status 2
if [[ -z $OLDDATE ]]; then
   exit 2
fi 

# If you ar here, there was a backfill at /Some/ point

# Get timestamp (unix epoch) for time in log
OLDTIMERAW=$(date -d "$OLDDATE" +"%s")

# Get timestamp (unix epoch) for current time
NEWTIMERAW=$(date +"%s")

# Subtract old from new to get time differential
TIMEDIFFERENCE=$(($NEWTIMERAW - $OLDTIMERAW))

# Check if time differential falls in provided range
if [[ $TIMEDIFFERENCE -le $SAMPLETIME  ]]; then
   # It does, all is well. Return 0
   exit 0
else
   # It does not, return exit code 1
   exit 1
fi
