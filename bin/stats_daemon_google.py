#!/usr/bin/python
# Implements daemon class to poll network stats more frequently than cron
# Daemon from http://www.jejik.com/articles/2007/02/a_simple_unix_linux_daemon_in_python/
# Found via http://stackoverflow.com/questions/16420092/how-to-make-python-script-run-as-service

import sys, os, inspect, time, subprocess
from daemon import Daemon

class StatsDaemon(Daemon):
    def run(self):
        dir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
        
        google_rtlatency_statsfile = "./" + dir + "/put_google_dns_latency.sh"
        
        while True:
            try:
                throughput_output = subprocess.check_output([google_rtlatency_statsfile, "eth0"])
                #print throughput_output

            except:
                # Well something went wrong...
                pass

            # Wait a few seconds to run again
            # There are better ways to do this to get ~1 second intervals
            time.sleep(1)

if __name__ == "__main__":
    
    # We sorta need sudo for
    """
    if os.geteuid() != 0:
        exit("You need to have root privileges to run this script.\nPlease try again, this time using 'sudo'. Exiting.")
    """
    
    daemon = StatsDaemon('/tmp/statsdaemon_google.pid', stdin='/dev/null', stdout='/dev/stdout', stderr='/dev/stderr')

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