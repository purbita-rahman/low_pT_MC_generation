#!/usr/bin/env python

from sys import argv
from os import system,getenv,getuid,getcwd

logpath='/uscmst1b_scratch/lpc1/3DayLifetime/sdogra/2016pre'
workpath=getcwd()+'/'+str(argv[1])
uid=getuid()

njobs = argv[2]
classad='''
universe = vanilla
executable = {0}/exec2016pre.sh
should_transfer_files = YES
when_to_transfer_output = ON_EXIT
transfer_input_files = {0}/submit.tgz
transfer_output_files = ""
input = /dev/null
use_x509userproxy = True
x509userproxy = /uscms/home/sdogra/x509up_u53290
output = {1}/$(Cluster)_$(Process).out
error = {1}/$(Cluster)_$(Process).err
log = {1}/$(Cluster)_$(Process).log
arguments = $(Process)
request_memory = 8192
queue {3}
'''.format(workpath,logpath,uid,njobs)

with open(logpath+'/condor.jdl','w') as jdlfile:
  jdlfile.write(classad)

system('condor_submit %s/condor.jdl'%logpath)
