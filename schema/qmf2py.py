#!/usr/bin/env python

# qmf2py.py
# generates a client library for the classes from the packages listed in argv; 
# runs against a broker on localhost.

# Public domain.
# Author:  William Benton (willb@redhat.com)

from qmf.console import Session
from sys import argv
import re

s = Session()
s.addBroker()

print """
class ClientObject:
   def __init__(self, obj, console):
      self.console = console
      self.obj = obj
   
   def __getattr__(self, name):
      if name.startswith("__"):
         return self.__dict__[name]
      return self.obj.__getattr__(name)
   
   def get_object(self, obj_id, klass=None):
      obj = self.console.getObjects(_objectId=obj_id)[0]
      if klass is None:
         return obj
      else:
         return klass(obj, self.console)
   
   def __repr__(self):
      repr(self.obj)
   
class ClientError(Exception):
   def __init__(self, code, text):
      self.code = code
      self.text = text
   
   def __str__(self):
      return(repr((self.code, self.text)))
"""

qmftypes = {12:'float', 6:'sstr', 15:'map', 3:'uint32', 17:'int16', 8:'abstime', 19:'int64', 10:'ref', 2:'uint16', 16:'int8', 13:'double', 21:'list', 11:'bool', 4:'uint64', 22:'array', 1:'uint8', 9:'deltatime', 7:'lstr', 18:'int32', 14:'uuid', 20:'object'}
qmfdirs = {"I":"in", "O":"out", "IO":"in-out"}

def pp(text, indent=0):
	print '   ' * indent + text

current_method = None

def dump_method(method, indent=0):
	global current_method
	current_method = method.name
	in_args = ["self"]
	out_args = []
	in_arg_docs = []
	out_arg_docs = []	
	
	for arg in method.arguments:
		comment = "(%s:%s)" % (arg.name, qmftypes[arg.type])
		if arg.desc != None:
			comment = arg.desc
		
		if arg.dir == "I":
			in_args.append(arg.name)
			in_arg_docs.append(comment)
		
		if arg.dir == "O":
			out_args.append(arg)
			out_arg_docs.append(comment)
		
		if arg.dir == "IO":
			in_args.append(arg.name)
			out_args.append(arg)
			in_arg_docs.append(comment)
			out_arg_docs.append(comment)
		
	in_arg_list = ", ".join(in_args)
	if in_arg_list.endswith("options"):
		in_arg_list += "={}"
	
	pp("def %s(%s):" % (method.name, in_arg_list), indent)
	pp(r'"""', indent+1)
	if method.desc != None:
		desc_lines = string.split(method.desc, "\n")
		for line in desc_lines:
			pp("%s" % line, indent + 1)
	if len(in_arg_docs) > 0:
		pp("Parameters:", indent + 1)
		for line in in_arg_docs:
			pp("* %s" % line, indent + 1)
	if len(out_arg_docs) == 1:
		retdoc = out_arg_docs[0]
		pp("Returns %s" % retdoc[0].lower() + retdoc[1:], indent + 1)
	elif len(out_arg_docs) > 1:
		pp("Returns a tuple consisting of:", indent + 1)
		for line in out_arg_docs:
			pp("* %s" % line, indent + 1)
	pp(r'"""', indent + 1)	
	
	pp("result = self.obj.%s(%s)" % (method.name, ", ".join(in_args[1:])), indent + 1)
	
	pp("if result.status != 0:", indent + 1)
	pp("raise ClientError(result.status, result.text)", indent + 2)
	
	if len(out_args) == 0:
		pp("return", indent + 1)
	elif len(out_args) == 1:
		pp("return %s" % dump_arg_val(out_args[0]), indent + 1)
	else:
		pp("return %s" % ", ".join(map(dump_arg_val, out_args)), indent + 1)
		
	pp("", indent)

def dump_arg_val(arg):
	global current_method
	
	suggested_type = re.match(".*?([A-Z][a-z]+)$", current_method)
	if suggested_type is None:
		suggested_type = str(suggested_type)
	else:
		suggested_type = suggested_type.groups()[0]
		if suggested_type == "Name":
			suggested_type = "Group"
		elif suggested_type == "Param":
			suggested_type = "Parameter"
		elif suggested_type == "Subsys":
			suggested_type = "Subsystem"
	
	if arg.type in [10, 20]:
		return "self.get_object(result.outArgs['%s'], %s)" % (arg.name, suggested_type)
	else:
		return "result.outArgs['%s']" % arg.name

def dump_class(klass, indent=0):
	pp("", indent)
	pp("class %s(ClientObject):" % klass.cname, indent)
	pp(r'"""%s:%s"""' % (klass.pname, klass.cname), indent + 1)
	schema = s.getSchema(klass)
	for method in schema.getMethods():
		dump_method(method, indent + 1)

for arg in argv[1:]:
	classes = s.getClasses(arg)
	indent = 0
	for klass in classes:
		dump_class(klass)


