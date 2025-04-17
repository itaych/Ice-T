#!/usr/bin/python
from __future__ import print_function
import sys

# file handle fh
fh = open(sys.argv[1])
while True:
	line = fh.readline()
	if not line:
		break
	if len(line) >= 5 and line[0] == '\t' and line[1].isalpha() and line[2].isalpha() and line[3].isalpha() and line[4] == '\t':
		line = line[:4] + ' ' + line[5:]
	print(line, end='')
fh.close()
