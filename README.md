# hardening-script-el6

## About

DISA STIG Scripts to harden a system to the RHEL 6 STIG.

This script is currently being used for bare metal systems
see https://people.redhat.com/fcaviggi/stig-fix for the 
associated kickstart. Work is being done to merge in AWS,
Puppet, and Chef content.

These scripts will harden a system to specifications that
are based upon the the following hardening and specifications
provided by the following projects:

* [DISA RHEL 6 STIG V1 R2](http://iase.disa.mil/stigs/os/unix-linux/Pages/red-hat.aspx)
* [NIST 800-53 (USGCB) Content for RHEL 5](http://usgcb.nist.gov/usgcb/rhel_content.html)
* [NSA SNAC Guide for Red Hat Enterprise Linux 5](http://www.nsa.gov/ia/_files/os/redhat/NSA_RHEL_5_GUIDE_v4.2.pdf)
* [Aqueduct Project](https://fedorahosted.org/aqueduct)
* [Tresys Certifiable Linux Integration Platform (CLIP)](http://oss.tresys.com/projects/clip)
     
## Content

Scripts are designed to run out of ```/opt/stig-fix/``` on a preferably fresh
installation of RHEL 6.4+ (RHEL 6.4 updated ```pam_lastlog.so``` to disable 
inactive users.)

* ```apply.sh``` - master script that runs scripts in cat1-cat4 and misc
* ```checkpoint.sh``` - checkpoint the current configuration so re-running apply.sh will not squash changes
* ```toggle_ipv6.sh``` - toggles IPv6 support, requires reboot (default is off)
* ```toggle_nousb.sh``` - toggles the 'nousb' kernel flag only
* ```toggle_udf.sh``` - toggles 'udf' mounting of DVDs (USGCB Blacklists udf) 
* ```toggle_usb.sh``` - toggles 'nousb' kernel flag and the mass storage kernel module
* ```config``` - Directory with some pre-STIGed configurations (auditd,iptables,system-auth-local,etc.) 
* ```scripts``` - Hardening Scripts
* ```misc``` - NSA SNAC, GNOME, and Other miscellenous lockdown scripts
* ```manual``` - Manually run (There be dragons here)
* ```backups``` - Backup copy of modified files to compare and restore configurations

Run is logged in ```/var/log/stig-fix-YYYY-MM-DD.log```

## How-to
1. Hardening the BIOS configuration (Disable USB Booting, set administrative passwords, etc.)
2. Enable Drive Encryption (LUKS on your LVM VG or Hardware-based FIPS 140-2 compliant)
3. Partitioning the system to minimally include the following:
  * ```/boot```
  * ```swap```
  * ```/```
  * ```/home```
  * ```/tmp```
  * ```/var```
  * ```/var/log```
  * ```/var/log/audit```
  * ```/var/www``` (Optional, Web Servers)
  * ```/rhnsat``` (Optional, RHN Satellite 5.5 and earlier, 5.6 uses /var)
  * ```/opt``` (Optional, Commercial Applications)
4. Select a GRUB password (SHA512, using grub-crypt or during Install)
5. Install a minimal installation (include rsyslog, ntp, aide, scrub, vlock, screen, logwatch, openswan, openscap, openscap-utils, dracut-fips) [RPM pulls the base requirements]
6. Register a system with a patch server - either a disconnected RHN Satellite or local/web-based (preferably SSL) repository:
  * Kickstart can register a system with ```rhnreg_ks --activationkey="<KEY>"```
  * With a disconnected RHN Satellite, be sure to include the proper ```/etc/sysconfig/rhn/up2date``` configuration and SSL Certificate.
  * For a local or web-based repository, create a ```.repo``` file in ```/etc/yum.repos.d/```

    ```
    # vi /etc/yum.repos.d/rhel-dvd.repo
                                  
    [rhel-dvd]
    name=Red Hat Enterprise Linux $releasever - $basearch - DVD
    baseurl=file:///media/
    enabled=1
    gpgcheck=1
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
    
    # mount /dev/dvd /media
    # yum clean all
    # yum update
    ```

  * For a repository, synchronize patches via a RHEL system connected to the Public RHN:
    * To synchronize a channel with only the newest packages, use the following command:

    ``` 
    # reposync -n -l -p <directory> -repoid=’<channel>’
    ```

    * To synchronize an entire channel, use the following command:

    ```
    # reposync -l -p <directory> -repoid=’<channel>’
    ```

    * After the packages have been downloaded into the directory in the previous step, create a repository with the RPMs.

    ```
    # createrepo <directory>
    ```

    * To export the directory, create an ISO image from the directory to burn to DVD:

    ```
    # mkisofs -RJ -o repo-export.iso <directory>
    ```

7. Include the stig-fix scirpts in the Kickstart and run the configuration ```/sbin/stig-fix -q &> /dev/null``` in the ```%post``` section -OR- install the RPM afterwards and run manually (```/sbin/stig-fix```)
8. Configure NTP (```/etc/ntp.conf```) for the local time sources (or military ones) that are approved
9. Configure Syslog forwarding (```/etc/rsyslog.conf```) to a local rsyslog instance (or Splunk as the case may be)
10. Add users with root access to the ```wheel``` group, for users with ssh access add them to the ```sshusers``` group.
11. Review the manual scripts in (```/opt/stig-fix/manual```) - putting the kernel in FIPS 140-2 mode can cause various weaker authentication not to work (e.g. RHN Satellite is still using md5)
12. The following scripts have been included for convenience (RPM Symbolic Links to scripts):
  * ```/sbin/toggle_ipv6``` (for IPv6 support - defualt is off)
  * ```/sbin/toggle_udf``` (for mounting DVDs)
  * ```/sbin/toggle_usb``` (for enabling and disabling USB storage)
  * ```/sbin/toggle_nousb``` (for enabling USB Keyboards that don't work with the ```nousb``` kernel option)
13. Configure Firewalls/TCP_WRAPPERS:
  * Edit the iptables, ip6tables, hosts.allow, and hosts.deny as requried, copy any changes back to the ```./config/``` directory for iptables/ip6tables and modify ```cat2/gen006620.sh``` (TCP_WRAPPERS) to ensure changes are applied if the stig-fix command is run again.
14. Install site approved monitoring tools and virus scan. Examples include, but are not limited to, the following:
  * McAfee VSE for Linux
  * McAfee HBSS
  * ClamAV
  * HP OpenView
15. Create users:
  * Remote Access (no ssh without this group)

    ```
    # useradd -m -c "Remote User" -G sshusers remoteuser
    ```

  * System Administrator (SA)

    ```
    # useradd -m -c "System Administrator" -G sshusers,wheel admin
    ```

  * Audit Administrator (AA)

    ```
    # useradd -m -c "Audit Administrator" -G sshusers,isso auditor
    ```

  * (Optional) After adding SAs to the system, lock the root account:

    ```
    # passwd -l root
    ```

16. System Checkpoint - to prevent apply.sh from overwriting your configuration you should checkpoint your system. A checkpoint will backup the current configuration into the 'backup' directory and overwrite the configurations contained in the 'config' directory.

    ```
    # ./checkpoint.sh
    ```

  * Created the ability to make an RPM from the configuration using the following commands as root:
    * Install Requirements:

    ```
    # yum install rpmbuild make autoconf
    ```

    * Create RPM

    ```
    # make rpm
    ```

    * Clean up

    ```
    # make clean
    ```

## Project Work

* Map DISA STIG RHEL 5 GEN controls to DISA STIG RHEL 6 SRG and NIST 800-53 controls (each sub script has an echo block stating what GEN it applies to - adding the SRG and NIST controls will help security people to understand what was intended during the C&A process.
* Help verify the configurations against SSG OpenSCAP Content
* Add updates to with new security features in RHEL 6.5 and newer
* Merge in work for AWS, Puppet, Chef
