import socket
import subprocess
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
    if not internet_test():
        raise SetupError("Cannot setup without internet.")

def exec_command(*command, **kwargs):
    try:
        return subprocess.check_output(command, universal_newlines=True, **kwargs)
    except subprocess.CalledProcessError as e:
        raise SetupError("Command {} error".format(' '.join(command))) from e


def apt_update():
    exec_command("apt-get", "update" "-y" "-q")
    exec_command("apt-get", "dist-upgrade" "-y" "-q")

def install_node():
    exec_command("curl -sL https://deb.nodesource.com/setup_11.x | sudo -E bash -", shell=True)
    exec_command("apt-get", "install" "-y" "nodejs")


def main():
    # Step 1
    system_check()
    apt_update()
    # Step 2
    install_node()
    # Step 3
    install_packages()
    # Step 4
    # WARNING: Internet via ethernet required for connections in future
    disable_wireless()
    config_ap()
    restart_wireless()
    # FINISHED
