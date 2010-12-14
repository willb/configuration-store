#!/usr/bin/env python

# qmf2markdown.py
# documents the QMF classes from the packages listed in argv; 
# runs against a broker in localhost.

# Public domain.
# Author:  William Benton (willb@redhat.com)

from qmf.console import Session
from sys import argv

s = Session()
s.addBroker()

qmftypes = {12:'float', 6:'sstr', 15:'map', 3:'uint32', 17:'int16', 8:'abstime', 19:'int64', 10:'ref', 2:'uint16', 16:'int8', 13:'double', 21:'list', 11:'bool', 4:'uint64', 22:'array', 1:'uint8', 9:'deltatime', 7:'lstr', 18:'int32', 14:'uuid', 20:'object'}
qmfdirs = {"I":"in", "O":"out", "IO":"in-out"}

for arg in argv[1:]:
  classes = s.getClasses(arg)
  for klass in classes:
    print "## %s:%s ##" % (klass.pname, klass.cname)
    schema = s.getSchema(klass)
    for prop in schema.getProperties():
      print "  * `%s` (`%s` property)" % (prop.name, qmftypes[prop.type])
      if prop.desc != None:
        print ""
        print "    %s" % prop.desc
    for stat in schema.getStatistics():
      print "  * `%s` (`%s` statistic)" % (stat.name, qmftypes[stat.type])
      if stat.desc != None:
        print ""
        print "    %s" % stat.desc
    for meth in schema.getMethods():
      print "  * `%s`" % repr(meth)
      if meth.desc != None:
        print ""
        print "    %s" % meth.desc
      for arg in meth.arguments:
        print "    * `%s` (`%s`/%s)" % (arg.name, qmftypes[arg.type], qmfdirs[arg.dir])
        if arg.desc != None:
          print ""
          print "      %s" % arg.desc
    print ""


