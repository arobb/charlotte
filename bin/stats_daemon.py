#!/usr/bin/python
# Implements daemon class to poll network stats more frequently than cron
# Daemon from http://www.jejik.com/articles/2007/02/a_simple_unix_linux_daemon_in_python/
# Found via http://stackoverflow.com/questions/16420092/how-to-make-python-script-run-as-service

import sys, os, inspect, time, subprocess
from daemon import Daemon

class StatsDaemon(Daemon):
    def run(self):
        dir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))

        throughput_statsfile = "./" + dir + "/put_local_net_ext_traffic.sh"
        latency_statsfile = dir + "/put_standard_latency_measurements.sh"

        # Run when <current timestamp> is <delay>+ seconds later than <last saved timestamp>
        delay = 10
        timestamp = int(time.time()) + delay  # Initialize so it runs on the first round
        while True:

            # If the current time is within <delay> seconds of the previous run,
            #   then sleep a second and skip to the next cycle
            if int(time.time()) < timestamp + delay:
                time.sleep(1)
                continue

            # Reset the timestamp to current
            timestamp = int(time.time())

            # Pull bandwidth stats for Comcast
            try:
                throughput_output = subprocess.check_output([throughput_statsfile, "-i", "wan1", "-m", "B4 75 0E 06 DB 76", "-p", "comcast"])
                #print throughput_output
            except:
                # Well something went wrong...
                pass

            # Pull bandwidth stats for AT&T
            try:
                throughput_output = subprocess.check_output([throughput_statsfile, "-i", "wan2", "-m", "B4 75 0E 06 DB 77", "-p", "att"])
                #print throughput_output
            except:
                # Well something went wrong...
                pass

            # Check latency between the Pi and meaningful destinations
            try:
                latency_output = subprocess.check_output([latency_statsfile])
                #print latency_output
            except:
                # Well something went wrong...
                pass


if __name__ == "__main__":

    # We sorta need sudo for
    """
    if os.geteuid() != 0:
        exit("You need to have root privileges to run this script.\nPlease try again, this time using 'sudo'. Exiting.")
    """

    daemon = StatsDaemon('/tmp/statsdaemon.pid', stdin='/dev/null', stdout='/dev/stdout', stderr='/dev/stderr')

    if len(sys.argv) == 2:
        if 'start' == sys.argv[1]:
            daemon.start()

        elif 'stop' == sys.argv[1]:
            daemon.stop()

        elif 'restart' == sys.argv[1]:
            daemon.restart()

        else:
            print "Unknown command"
            sys.exit(2)

        sys.exit(0)

    else:
        print "usage: %s start|stop|restart" % sys.argv[0]
        sys.exit(2)
