#!/bin/bash
# BASED ON: Paul Colby (http://colby.id.au), no rights reserved ;)

declare -a PREV_TOTAL
declare -a PREV_IDLE

CPUCOUNT=$(nproc --all)
CPUNUM=""

echo -n "TIME                ALL   "

for ((ITER=0;ITER<=$CPUCOUNT;ITER++)); do
  echo -n "$CPUNUM"
  CPUNUM=$(printf "CPU%02d " $ITER)
  PREV_TOTAL[$ITER]=0
  PREV_IDLE[$ITER]=0
done

echo

while true; do
  # Get the total CPU statistics, discarding the 'cpu ' prefix.
  readarray -t STATS <<< $(sed -n 's/^cpu[0-9]*\s*//p' /proc/stat)

  echo -n "$(date +%Y-%m-%dT%H:%M:%S) "

  for KEY in "${!STATS[@]}"; do
    TOTAL=0
    ITER=0
    for VALUE in ${STATS[$KEY]}; do
      TOTAL=$((TOTAL+VALUE)) # Calculate the total CPU time.
      if [ $ITER == 3 ]; then
        IDLE=$VALUE # Just the idle CPU time.
      fi
      ITER=$((ITER + 1))
    done

    # Calculate the CPU usage since we last checked.
    DIFF_TOTAL=$((TOTAL-PREV_TOTAL[$KEY]))
    DIFF_IDLE=$((IDLE-PREV_IDLE[$KEY]))
    DIFF_USAGE=$(bc -q <<< "scale=2; 100*($DIFF_TOTAL-$DIFF_IDLE)/$DIFF_TOTAL")

    LC_NUMERIC=C printf "%05.2f " $DIFF_USAGE

    # Remember the total and idle CPU times for the next check.
    PREV_TOTAL[$KEY]=$TOTAL
    PREV_IDLE[$KEY]=$IDLE
  done

  echo

  # Wait before checking again.
  sleep 1
done
