# IPsecCaManager

Simple Certificate Manager for IPsec...

**Dependencies:** gtk2, polkit, openssl

When creating a connection via `Network Manager` (e.g. IKEv2/IPsec), the connection settings must specify the corresponding certificates (e.g. Ca in case of public VPNs). Since the `IPsec` working directory is `/etc/ipsec.d` and certificates must be located in its subdirectories ([see IPSec help](https://wiki.strongswan.org/projects/strongswan/wiki/IpsecDirectory/5)), `NM` does not have access privileges to this directory by default.

![](https://github.com/AKotov-dev/IPsecCaManager/blob/main/ScreenShot1.png)

`IPSecCaManager` is designed to manage `IPSec` certificate files. In addition to convenient work in the GUI, it always recursively changes the rights to the working directory and files after startup and during current operations:
```
mkdir -p /etc/ipsec.d/{cacerts,certs,private}; chmod -R 755 /etc/ipsec.d
```
As a result, this makes it accessible to `NM` and there are no connection problems.

Below is a screenshot of an already configured `IKEv2/IPsec` connection with a server certificate + user identification by name and password:

![](https://github.com/AKotov-dev/IPsecCaManager/blob/main/ScreenShot2.png)

Let me remind you that to create an `IKEv2/IPsec` connection using `Network Manager` in Mageia Linux, the following packages are required:
```
networkmanager-strongswan-gnome (or plasma-applet-nm-strongswan for KDE) networkmanager-strongswan strongswan-charon-nm strongswan libreswan (needed to create L2TP/IPsec)
```

The program can be launched either from the installed package or from the archive by running `StartAsRoot`.

**Note:** I haven't found a more secure solution with `IPSec` certificates. Use as is... :)
