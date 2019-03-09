import socket
import subprocess
import os
import shutil

filename = "inst/record.txt"

HOST_APD_CONF = """
interface=wlan0
driver=nl80211
ssid=PIMW-NET
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=12345678
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
"""
class SetupError(Exception):
    pass

def internet_test(host="8.8.8.8", port=53, timeout=3):
    """
    Host: 8.8.8.8 (google-public-dns-a.google.com)
    OpenPort: 53/tcp
    Service: domain (DNS/TCP)
    """
    try:
        socket.setdefaulttimeout(timeout)
        socket.socket(socket.AF_INET, socket.SOCK_STREAM).connect((host, port))
        return True
    except Exception as ex:
        print(str(ex))
        return False


def system_check():
    log("Checking system")
    if not internet_test():
        raise SetupError("Cannot setup without internet.")

def exec_command(*command, **kwargs):
    try:
        return subprocess.check_output(command, universal_newlines=True, **kwargs)
    except subprocess.CalledProcessError as e:
        raise SetupError("Command {} error".format(' '.join(command))) from e


def apt_update():
    log("Updating packages")
    exec_command("apt-get", "update", "-y", "-q")
    exec_command("apt-get", "dist-upgrade", "-y", "-q")

def install_apt_packages():
    log("Installing required apt packages")
    exec_command("apt-get", "install", "-y", "bluetooth", "bluez", "libbluetooth-dev", "libudev-dev", "dnsmasq", "hostapd")
    log("Successfully installed packages")

def disable_services():
    log("Disabling services")
    exec_command("systemctl", "stop", "dnsmasq")
    exec_command("systemctl", "stop", "hostapd")
    log("Services disabled")

def install_node():
    log("Checking for node")
    if shutil.which("npm") is not None:
        try:
            if exec_command("node", "-v").startswith("v8."):
                log("Node already installed")
                return
        except SetupError:
            pass
    log("Installing node")
    exec_command("curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -", shell=True)
    exec_command("apt-get", "install", "-y", "nodejs")
    log("Node installed")

def conf_dhcpcd():
    log("Configuring DHCPCD")
    try:
        with open("/etc/dhcpcd.conf", "a") as f:
            f.write("""\ninterface wlan0\n    static ip_address=192.168.4.1/24\n    nohook wpa_supplicant""")
    except IOError as e:
        raise SetupError("Cannot change file {}".format("/etc/dhcpcd.conf")) from e
    exec_command("service", "dhcpcd", "restart")

def conf_dnsmasq():
    log("Configuring dnsmasq")
    try:
        shutil.move("/etc/dnsmasq.conf", "/etc/dnsmasq.conf.orig")
        with open("/etc/dnsmasq.conf", "w") as f:
            f.write("""interface=wlan0      # Use the require wireless interface - usually wlan0\n  dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h""")
    except IOError as e:
        raise SetupError("Cannot change file {}".format("/etc/dnsmasq.conf")) from e

def conf_hostapd():
    log("Configuring hostapd")
    try:
        with open("/etc/hostapd/hostapd.conf", "w") as f:
            f.write(HOST_APD_CONF)
    except IOError as e:
        raise SetupError("Cannot change file {}".format("/etc/hostapd/hostapd.conf")) from e
    try:
        with open("/etc/default/hostapd", "r") as f:
            contents = f.read()
        contents = contents.splitlines()
        for i, line in enumerate(contents[:]):
            if line.startswith("#DAEMON_CONF"):
                contents[i] = 'DAEMON_CONF="/etc/hostapd/hostapd.conf"'
                break
        else:
            # Was not present
            contents.append('DAEMON_CONF="/etc/hostapd/hostapd.conf"')
        contents = '\n'.join(contents)
        with open("/etc/default/hostapd", "w") as f:
            f.write(contents)
    except IOError as e:
        raise SetupError("Cannot access file {}".format("/etc/hostapd/hostapd.conf")) from e

def start_services():
    log("Enabling services")
    exec_command("systemctl", "start", "hostapd")
    exec_command("systemctl", "start", "dnsmasq")

def edit_sysctl():
    log("Editing system ctl")
    try:
        with open("/etc/sysctl.conf", "r") as f:
            contents = f.read()
        contents = contents.splitlines()
        for i, line in enumerate(contents[:]):
            if line.startswith("#net.ipv4.ip_forward=1"):
                contents[i] = 'net.ipv4.ip_forward=1'
                break
        else:
            # Was not present
            raise SetupError("Could not uncomment non existing line")
        contents = '\n'.join(contents)
        with open("/etc/sysctl.conf", "w") as f:
            f.write(contents)
    except IOError as e:
        raise SetupError("Cannot access file {}".format("/etc/sysctl.conf")) from e

def setup_iptables():
    log("Setting up iptables")
    exec_command("iptables", "-t", "nat", "-A", "", "POSTROUTING", "-o", "eth0", "-j", "MASQUERADE")
    exec_command('sh -c "iptables-save > /etc/iptables.ipv4.nat"', shell=True)
    try:
        with open("/etc/rc.local", "r") as f:
            contents = f.read()
        contents = contents.splitlines()
        for i, line in enumerate(contents[:]):
            if line.startswith("exit 0"):
                contents.insert(i, "iptables-restore < /etc/iptables.ipv4.nat")
                break
        else:
            # Was not present
            raise SetupError("Could not find exit 0 in rc.local")
        contents = '\n'.join(contents)
        with open("/etc/rc.local", "w") as f:
            f.write(contents)
    except IOError as e:
        raise SetupError("Cannot access file {}".format("/etc/rc.local")) from e



def install_npm_packages():
    log("Installing NPM packages")
    exec_command("npm", "install", "--unsafe-perm")

def log(*args):
    print("[Installer] ", end="")
    print(*args)

def record_stage(stage_no):
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with open(filename, "w") as f:
        f.write(str(stage_no))

def get_stage():
    if os.path.exists(filename):
        try:
            with open(filename, "r") as f:
                stage = int(f.read())
        except (IOError, ValueError) as e:
            raise SetupError("Cannot read file {}".format(filename)) from e
        return stage
    else:
        return 1

def stage1():
    log("Stage 1 Beginning")
    # Step 1
    system_check()
    apt_update()
    install_node()
    install_apt_packages()
    disable_services()
    record_stage(2)
    log("Stage 1 finished - please reboot and run this script again afterwards.")

def stage2():
    log("Stage 2 beginning")
    conf_dhcpcd()
    conf_dnsmasq()
    conf_hostapd()
    start_services()
    edit_sysctl()
    setup_iptables()
    record_stage(3)
    log("Stage 2 finished - please reboot and run this script again afterwards.")

def stage3():
    log("Stage 3 beginning")
    install_npm_packages()
    record_stage(4)
    log("Stage 3 finished, you are ready to start.")

def main():
    if (not os.geteuid() == 0):
        raise SetupError("Must run as sudo to setup")
    stage = get_stage()
    if stage == 1:
        stage1()
    elif stage == 2:
        stage2()
    elif stage == 3:
        stage3()
    elif stage == 4:
        log("Setup is done")
    else:
        log("BAD STAGE")

if __name__ == "__main__":
    main()
