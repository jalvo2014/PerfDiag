Last updated 12/2/2010

NOTE:  The sar command requires root authority, so these scripts must be run from root.

To setup on a AIX, Solaris, xLinux or zLinux machine, 

1) create a /usr/perfdata directory (or some other directory of your choice)
2) copy the scripts in this directory to /usr/perfdata
3) give "execute" permission for the scripts (chmod +x perfdata.*.sh)
4) If you used a directory other than /usr/perfdata, edit the perfdata.start.sh 
   script and change the OUTPUTPATH variable to reflect your directory name

5) To start data collection, run perfdata.start.sh

  USAGE:  perfdata.start.sh <-d dcinterval> <-l numloops> <-p path for output> <-f filename for output>

  Default values:
  DCINTERVAL=60  # Data collection interval (seconds)
  NUMLOOPS=1440    # Number of loops
                  # 1440 loops * 1 min/loop = 1440 mins / 60 = 24 hours
                  # note the loop many not actually run on true 1 minute intervals
  OUTPUTPATH=/usr/perfdata
  OUTPUTFILE=$hostname.20yymmdd.hhmm.perfdata.log

  To run perfdata.start.sh in the background, invoke it as follows:
	nohup /usr/perfdata/perfdata.start.sh & 

6) To stop data collection, use Ctrl-C if perfdata.start.sh is running in the foreground.  
   If perfdata.start.sh is running in the background, you can run perfdata.stop.sh or 
   issue "kill -9" for the perfdata.start.sh process ID.
