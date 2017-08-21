#!/usr/bin/env python
# Implements daemon class to poll network stats more frequently than cron
# Daemon from http://www.jejik.com/articles/2007/02/a_simple_unix_linux_daemon_in_python/
# Found via http://stackoverflow.com/questions/16420092/how-to-make-python-script-run-as-service

import sys, os, inspect, time, subprocess
from daemon import Daemon

class StatsDaemon(Daemon):
    def run(self):
        dir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))

        config_file = dir + "/../conf/get_conf.sh"
        throughput_statsfile = dir + "/put_local_net_ext_traffic.sh"
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

            # Get number of interfaces
            num_interfaces = subprocess.check_output([config_file, "num_interfaces"]).strip()
            num_interfaces = int(num_interfaces)

            # Pull bandwidth stats
            for i in range(0,num_interfaces):
                try:
                    provider = subprocess.check_output([config_file, "gateway_external_iface_provider_"+str(i)]).strip()
                    label = subprocess.check_output([config_file, "gateway_external_iface_label_"+str(i)]).strip()
                    mac = subprocess.check_output([config_file, "gateway_external_iface_mac_"+str(i)]).strip()
                    throughput_output = subprocess.check_output([throughput_statsfile, "-i", label, "-m", mac, "-p", provider])
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
