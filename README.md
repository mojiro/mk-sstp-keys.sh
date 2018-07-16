# mk-sstp-keys.sh
A bash script that simplifies ssl keys creation.

I wrote that script to create easily many keys and use them onto Mikrotik routers for the SSTP VPN's

Current version: 0.9
Latest update: 2017-07-20

```
Usage:
Open the script and check the "Settings" area.

The script is going to create keys for every host that it is defined in the variable "Hosts". If there are created keys for a specific host, there are not being overwritten.

Execute:
./mk-sstp-keys.sh
```
