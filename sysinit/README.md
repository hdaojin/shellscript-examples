# Some shell scripts to initialize the system at the first installation.

There are some shell scripts to initialize the system at the first installation. The scripts are located in the `sysinit` directory.

## cinit.sh

This script is used to initialize the debian system at the Linux Environment Competition. It will install some necessary packages and set some configurations.

## init-ansible-controller.sh

This script is used to initialize the ansible controller. It will install ansible and set some configurations.

### Usage:

Switch to the root user:

```bash
su - root
```

Install curl if it is not installed:

```bash
apt install -y curl
```

Download and run the script:

```bash
curl -sSL https://raw.githubusercontent.com/hdaojin/shellscript-examples/refs/heads/main/sysinit/init-ansible-controller.sh | bash
```


