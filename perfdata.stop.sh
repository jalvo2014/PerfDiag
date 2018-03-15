#!/bin/ksh
# Performance data collection script for AIX, Solaris and Linux
#
#  NOTE:  sar, ps, vmstat and netstat commands are required
#
#  USAGE:  perfdata.start.sh <-d interval> <-l loopcount> 
#                      <-p path for output> <-f filename for output>
#
#     -d number of seconds for data collection interval (default 60)
#     -l loop count (defualt 1440)
#     -p path for output (default /usr/perfdata)
#     -f filename for output (default <hostname>.20yymmdd.hhmm.perfdata.log)
#  
#  Author:     Thad Jennings
#
#  Change history:
#  01 JTJ 06-07-10 Created simplified cross-platform version, based on
#                    original OS-specific perfdata scripts from Rich Hal

#
# Set argument defaults
#
# Default settings are to collect data once per minute for one day
DCINTERVAL=60   # Data collection interval (seconds)
                # Default 60 seconds, minimum 5 seconds, maximum 3600 seconds
NUMLOOPS=1440   # Number of loops 
                # 1440 loops * 1 min/loop = 1440 mins / 60 = 24 hours
                # note the loop many not actually run on true 1 minute intervals
OUTPUTPATH=/usr/perfdata

#
#  Parse args
#
ARGC=$#
while [ $ARGC != 0 ]
do
    case $1 in

        "-d")   # Data collection interval (seconds)
                DCINTERVAL=$2
                shift 2
                ARGC=`expr $ARGC - 2`
                ;;

        "-l")   # Number of loops
                NUMLOOPS=$2
                shift 2
                ARGC=`expr $ARGC - 2`
                ;;

        "-p")   # Path for output 
                OUTPUTPATH=$2
                shift 2
                ARGC=`expr $ARGC - 2`
                ;;

        "-f")   # Filename for output 
                OUTPUTFILE=$2
                shift 2
                ARGC=`expr $ARGC - 2`
                ;;

        *)      # Print command usage info
                echo "USAGE:  perfdata.start.sh <-d dcinterval> <-l numloops> <-p path for output> <-f filename for output>"
                echo
                exit 1 ;;
    esac
done

OSNAME=`uname`

# Only root user can run sar
if [[ $OSNAME = "SunOS" ]]
then
    MYUSERNAME="`who am i | awk '{ print $1 }'`"
else
    MYUSERNAME="`whoami`"
fi
if [ $MYUSERNAME != "root" ]
then
   echo "You must be a super-user for sar ..."
   exit
 fi

# Use this function to label output in the output file.  It will help
#    you find stuff later.
function tag {
   echo "<===== perfdata.sh =====> $*" >>${OUTFILE}
}

# This function invokes the ps command with slightly different options 
#   for each OS.  This is in a separate function because it is called in more
#   than one place in the script.
run_ps ()
{
  if [[ $OSNAME = "AIX" ]]
  then
    tag "ps -efo thcount,scount,vsz,pid,ppid,etime,time,comm,args output ;"
    ps -efo thcount,scount,vsz,pid,ppid,etime,time,comm,args  >>${OUTFILE}
    tag "ps avxww output ;"
    ps avxww  >>${OUTFILE}
  elif [[ $OSNAME = "Linux" ]]
  then
    tag "ps w -eo uid,pri,pid,ppid,vsz,rss,sz,etime,time,args output ;"
    ps w -eo uid,pri,pid,ppid,vsz,rss,sz,etime,time,args  >>${OUTFILE}
  elif [[ $OSNAME = "SunOS" ]]
  then
    tag "ps -eo uid,pri,pid,ppid,nlwp,osz,rss,stime,time,vsz,args output ;"
    ps -eo uid,pri,pid,ppid,nlwp,osz,rss,stime,time,vsz,args  >>${OUTFILE}
  fi
}

# This function stops data collection and invokes the ps command one last time
stop_DC ()
{
  echo "trap hit ;" >>${OUTFILE}
  tag "Stopping data collection"
  echo "Stopping data collection"
  date >>${OUTFILE}
  run_ps
}

tag "Data collection started at: "`date`" with delay = " $DCINTERVAL
echo "Output stored in" ${OUTFILE}

tag uname -a command output
uname -a >>${OUTFILE}

trap ' stop_DC;exit 1' 1 2 9 15

echo "Performance Measurement In Progress ... "
echo  " "
echo  " use cntl-c to stop data collection "
echo  " "

echo " " >>${OUTFILE}
tag "start data collection loop"
echo " " >>${OUTFILE}

loopcnt=0
typeset -Z3 loopcnt0=0

# Attempt to delay data collection until next multiple of collection interval
MINUTESTRING=`date +"%M"`
SECONDSTRING=`date +"%S"`
SECONDSINTOHOUR=`expr $MINUTESTRING \* 60 \+ $SECONDSTRING`
SECONDSSINCEMULTIPLE=`expr $SECONDSINTOHOUR % $DCINTERVAL`
FIRSTDELAY=`expr $DCINTERVAL \- $SECONDSSINCEMULTIPLE`
echo Delaying $FIRSTDELAY seconds to wait for next even multiple of data collection interval
sleep $FIRSTDELAY

# Build the default output filename from the short hostname and date/time
THISHOST=$(hostname)
THISHOST=`echo $THISHOST | awk -F\. '{ print $1 }'`
DATETIMESTRING=`date +"20%y%m%d.%H%M"`
OUTPUTFILE=$THISHOST.$DATETIMESTRING.perfdata.log
OUTFILE=$OUTPUTPATH"/"$OUTPUTFILE

while (( $loopcnt < $NUMLOOPS ))
do
  let loopcnt=loopcnt+1
  let loopcnt0=loopcnt0+1
  datetime=`date`
  echo "datetime:" $datetime "loopcnt:" $loopcnt ";" >>${OUTFILE}
  echo "datetime:" $datetime "loopcnt:" $loopcnt

  # Invoke ps command, which is slightly different for each OS
  run_ps

  tag "vmstat -s output :"
  vmstat -s >>${OUTFILE}
  
  tag "netstat -s output :"
  netstat -s >>${OUTFILE}
  
  # Adjust SAR delay if necessary to line up to even data collection boundary
  MINUTESTRING=`date +"%M"`
  SECONDSTRING=`date +"%S"`
  SECONDSINTOHOUR=`expr $MINUTESTRING \* 60 \+ $SECONDSTRING`
  SECONDSSINCEMULTIPLE=`expr $SECONDSINTOHOUR % $DCINTERVAL`
  SARDELAY=`expr $DCINTERVAL \- $SECONDSSINCEMULTIPLE`

  # sar acts as a sleep and collects system level CPU and disk data
  if [[ $OSNAME = "Linux" ]]
  then
    # Options for Linux are to remove the detailed CPU interrupt rates
    tag "sar -bBcdqrRuvwWy -n ALL -P ALL" $SARDELAY "1 output ;"
    sar -bBcdqrRuvwWy -n ALL -P ALL $SARDELAY 1 >>${OUTFILE}
  else
    tag "sar -A" $SARDELAY "1 output ;"
    sar -A $SARDELAY 1 >>${OUTFILE}
  fi
done

stop_DC

exit 0
