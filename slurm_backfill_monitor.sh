#!/bin/bash
#
# Author: Christoph Schild <cvs46@nau.edu>
# This script monitors the backfill log in Slurm and uses return codes to communicate its state.
# Parses slurm.conf is used to determine if backfilling is enabled. 
# NOTE: Must be run as a user with access to slurm.conf and /var/log/slurm
#
# Determine if Backfill is enabled
if [[ $(cat /etc/slurm/slurm.conf | grep DebugFlags=Backfill) == "#"* ]]; then
   # Line is commented out, use return code 2
   exit 2
else
   # Line is NOT commented out
   # Get Date of last backfill complete (DEBUGGING IN THIS LINE)
   OLDDATE=$(tac /var/log/slurm/slurmctld.log | grep 'backfill: reached end of job queue' -m 1| cut -d '.' -f 1 | cut -d '[' -f 2 | tr -s 'T' ' ')
   # Return exit code 2 if NO backfills have completed
   if [[ -z $OLDDATE ]]; then
      exit 2
   fi   
   # Get timestamp (unix epoch) for time in log
   OLDRAW=$(date -d "$OLDDATE" +"%s")
   
   # Get timestamp (unix epoch) for current time
   NEW=$(date +"%s")

   # Use time passed as parameter to verify timeperiod
   TIMEDIFFALLOWED=$1
   
   # Subtract old from new to get time differential
   SUB=$(($NEW - $OLDRAW))
   
   # Check if time differential falls in provided range
   if [[ $SUB -le $TIMEDIFFALLOWED  ]]; then
      # It does, all is well. Return 0
      exit 0
   else
      # It does not, return exit code 1
      exit 1
   fi
fi
