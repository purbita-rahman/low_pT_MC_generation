#!/bin/bash

export TARBALLDIR="/uscms/home/pprova/nobackup/runTarBallMiniAODv2"
#export TARBALLDIR="/uscms_data/d3/dxiong/thesisgen21/runTarBallMiniAODv2"

#for FILE in inputs/softtrack_monophoton_UL2019_GPT190_01262021*.xz

for FILE in inputs/g2200_X700_delm100_slc7_amd64_gcc700_CMSSW_10_6_19_tarball.tar.xz
#for FILE in inputs/softtrackstudy_022822*.xz
do
    echo  $FILE
    PROCESS=$(echo ${FILE} | cut -d "/" -f 2 | sed 's/\_tarball.tar.xz//')
    echo ${PROCESS}
    export BASEDIR=${PWD}
    rm -r work${1}_${PROCESS}
    mkdir work${1}_${PROCESS}
    export SUBMIT_WORKDIR=${PWD}/work${1}_${PROCESS}
    year=${1}
    if [ ${year} -eq 2016 ]; then
        cp  inputs/softtrack_monophoton.py inputs/${PROCESS}_hadronizer.py
    fi
    if [ ${year} -eq 2018 ]; then
        cp  inputs/softtrack_monophoton.py inputs/${PROCESS}_hadronizer.py
    fi
    if [ ${year} -eq 2017 ]; then
        cp  inputs/softtrack_monophoton.py inputs/${PROCESS}_hadronizer.py
    fi
    sed -i "s/processname/${PROCESS}/"  inputs/${PROCESS}_hadronizer.py
    dirname_tmp=${PROCESS}
    dirname=$(echo ${dirname_tmp} | cut -d "/" -f 2 | sed 's/\_slc7_amd64_gcc700_CMSSW_10_6_0//')
    echo $dirname


    echo "TARBALL=${PROCESS}_tarball.tar.xz" > ./submit/inputs.sh
    echo "HADRONIZER=${PROCESS}_hadronizer.py" >> ./submit/inputs.sh
    echo "PROCESS=${PROCESS}" >> ./submit/inputs.sh
    echo "dirname=${dirname}" >> ./submit/inputs.sh
    echo "USERNAME=${USER}" >> ./submit/inputs.sh    
    

    if [ -z "$2" ]
    then
	echo "MERGE=0" >> ./submit/inputs.sh
	echo "You want to produce events for $1. Good luck!"
    else
	echo "MERGE=1" >> ./submit/inputs.sh
	echo "You want to merge the T2 files for $1? Ok."
    fi
    
    
    if [ ${year} -eq 2016 ]; then
	mkdir -p ./submit/input/
	cp ${TARBALLDIR}/inputs/${PROCESS}_tarball.tar.xz ./submit/input/
	cp ${TARBALLDIR}/inputs/${PROCESS}_hadronizer.py ./submit/input/
	cp ${BASEDIR}/exec2016pre.sh $SUBMIT_WORKDIR
	cp ${BASEDIR}/exec2016post.sh $SUBMIT_WORKDIR
    fi
    
    if [ ${year} -eq 2017 ]; then
	mkdir -p ./submit/input/
	cp ${TARBALLDIR}/inputs/${PROCESS}_tarball.tar.xz ./submit/input/
	cp ${TARBALLDIR}/inputs/${PROCESS}_hadronizer.py ./submit/input/
	cp ${BASEDIR}/exec2017.sh $SUBMIT_WORKDIR
    fi
    
    if [ ${year} -eq 2018 ]; then
	mkdir -p ./submit/input/
	cp ${TARBALLDIR}/inputs/${PROCESS}_tarball.tar.xz ./submit/input/
	cp ${TARBALLDIR}/inputs/${PROCESS}_hadronizer.py ./submit/input/
	cp ${BASEDIR}/exec2018.sh $SUBMIT_WORKDIR
    fi
    
    ##x509
    ##voms-proxy-init -voms cms -valid 172:00
    ##cp /tmp/x509up_u$UID $SUBMIT_WORKDIR/x509up
    #cp ${HOME}/x509up_u$UID $SUBMIT_WORKDIR
    
    #creating tarball
    echo "Tarring up submit..."
    tar -chzf submit.tgz submit  #why make this??
    rm -r ${BASEDIR}/submit/input/*
    
    mv submit.tgz $SUBMIT_WORKDIR
    
    ##cp ${BASEDIR}/exec.sh $SUBMIT_WORKDIR
    
    #does everything look okay?
    ls -lh $SUBMIT_WORKDIR
   # mkdir  -p  logs/dirname
done
