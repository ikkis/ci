# -*- coding: UTF-8 -*-
'''
'''

import os
import sys
from getopt import getopt, GetoptError

from frame.lib.commonlib.xtslog import xtslog
from frame.lib.controllib.pickcase import XtsPicker
from frame.lib.controllib.compound.compound_suite import CompoundSuite
from frame.lib.controllib.result import XtsResult
from frame.lib.controllib.framemain import FrameMain

def main():
    # Initial log
    logdir = os.path.join(os.path.dirname(__file__), "../log/")
    xtslog.init_logger(logdir+"/sfserver.log")
    
    # create Picker, Suite, Result object
    picker = XtsPicker()
    suite = CompoundSuite()
    result = XtsResult()

    try:
        opts, args = getopt(sys.argv[1:], 
                            "vhE", 
                            ["single", 
                             "ignore=", 
                             "weak", 
                             "tag=", 
                             "testname=", 
                             "nocolor", 
                             "hudson", 
                             "verbose", 
                             "help",
                             "ejiabiao="
                             ])
    except GetoptError:
        xtslog.critical("Get options failed. Process suicide", exc_info=True)
        help()
        sys.exit(-1)
    for opt in opts:
        if opt[0] == "--single":
            suite.set_single(True)
            
        if opt[0] == "--ignore":
            picker.read_ignore_list(opt[1])
            
        if opt[0] == "--weak":
            suite.set_weak(True)
            
        if opt[0] == "--tag":
            picker.parse_tag(opt[1])
            
        if opt[0] == "--testname":
            picker.set_testname(opt[1])
            
        if opt[0] == "--nocolor" or opt[0] == "--hudson":
            xtslog.set_no_color()

        if opt[0] == "-E" or opt[0] == "--ejiabiao":
            product = args[0]
            localpath = args[1]
            mode = "download"
            ejb = EJB(product,  localpath)
            ejb.downfromEJB(mode)
            sys.exit(0)
            
        if opt[0] == "-v" or opt[0] == "--verbose" or opt[0] == "--hudson":
            xtslog.set_sh_debug()
            
        if opt[0] == "-h" or opt[0] == "--help":
            help()
            sys.exit(0)

    # Create FrameMain object 
    frame = FrameMain(picker, suite, result, logdir)
    
    # execute framewoork and get result
    ret = frame.execute(args)
    result.gen_junit_report(logdir+"report_FT.xml","test")
    result.gen_mail_report(logdir+"report.html","test")
    sys.exit(ret)


def help():
    print "Usage: main.sh [options] case_file_or_dir..."
    print
    print "Run cases, or cases in directories"
    print
    print "options"
    print "  --single:                         \t Run case separately"
    print "  --ignore=<file>:                  \t Ignore cases in <file>"
    print "  --weak:                           \t Quit when any case failed"
    print "  --tag=<feature>[,<feature>]...    \t Run cases which have (one of the) <feature>"
    print "                                    \t    Without this option, run ALL cases"
    print "                                    \t    Multiple --tag options means intersection"
    print "  --testname=<regex>                \t Run test whose name contains <regex>"
    print "  --nocolor                         \t Don't print color log on Screen"
    print "  --hudson                          \t Choose hudson options. Equals to --nocolor --verbose"
    print "  -v, --verbose                     \t Print DEBUG log on Screen"
    print "  -h, --help:                       \t Show this help"
    print "  -E, -e, --ejb                     \t download cases from ejb"

if __name__=='__main__':
    main()


