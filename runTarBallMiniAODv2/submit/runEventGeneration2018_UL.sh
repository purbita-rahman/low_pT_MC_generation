B#!/bin/bash
###########
# setup
export BASEDIR=`pwd`
############# inputs
export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
source $VO_CMS_SW_DIR/cmsset_default.sh
source inputs.sh

############# make a working area

echo " Start to work now"
pwd
mkdir -p ./work
cd    ./work
export WORKDIR=`pwd`

############## generate LHEs

RANDOMSEED=`od -vAn -N4 -tu4 < /dev/urandom`
RANDOMSEED=`echo $RANDOMSEED | rev | cut -c 3- | rev` #Sometimes the RANDOMSEED is too long for madgraph

#Run
TempNumber=${RANDOMSEED}
outfilename_tmp="$PROCESS"'_'"$RANDOMSEED"
outfilename="${outfilename_tmp//[[:space:]]/}"


echo $PROCESS
echo $dirname

#
#############
#############
# Generate GEN-SIM
export SCRAM_ARCH=slc7_amd64_gcc700
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_10_6_27/src ] ; then
 echo release CMSSW_10_6_27 already exists
else
scram p CMSSW CMSSW_10_6_27
fi
cd CMSSW_10_6_27/src
eval `scram runtime -sh`
mkdir -p Configuration/GenProduction/python/
cd Configuration/GenProduction/python/
cp ${BASEDIR}/input/${HADRONIZER} ./
echo  ${HADRONIZER}
echo ${TARBALL}
echo $PWD
cp ${BASEDIR}/input/${TARBALL} ./
sed -i "s@XY-Hadronzer_Path@$(pwd)@" ${HADRONIZER}
cd ../../../
scram b -j 8
cd ../../

cmsDriver.py Configuration/GenProduction/python/${HADRONIZER}  --python_filename ${outfilename}_gensim.py --eventcontent RAWSIM,LHE --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN,LHE --fileout file:${outfilename}_gen.root --conditions 106X_upgrade2018_realistic_v4 --beamspot Realistic25ns13TeVEarly2018Collision --customise_commands process.source.numberEventsInLuminosityBlock="cms.untracked.uint32(212)"\\nprocess.RandomNumberGeneratorService.externalLHEProducer.initialSeed="int(${RANDOMSEED})" --step LHE,GEN --geometry DB:Extended --era Run2_2018 --no_exec --mc -n 2000

#cmsDriver.py Configuration/GenProduction/python/${HADRONIZER} --python_filename ${outfilename}_gensim.py --eventcontent RAWSIM,LHE --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN,LHE --fileout file:${outfilename}_gen.root --conditions 106X_upgrade2018_realistic_v15_L1v1 --beamspot Realistic25ns13TeVEarly2018Collision --customise_commands process.source.numberEventsInLuminosityBlock="cms.untracked.uint32(2272)"\\nprocess.RandomNumberGeneratorService.externalLHEProducer.initialSeed="int(${RANDOMSEED})" --step LHE,GEN --geometry DB:Extended --era Run2_2018 --no_exec --mc -n 2000 

#Run
cmsRun ${outfilename}_gensim.py

#SIM STEP
export SCRAM_ARCH=slc7_amd64_gcc700
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_10_6_17_patch1/src ] ; then
  echo release CMSSW_10_6_17_patch1 already exists
else
  scram p CMSSW CMSSW_10_6_17_patch1
fi
cd CMSSW_10_6_17_patch1/src
eval `scram runtime -sh`

scram b
cd ../..

cmsDriver.py step2 --python_filename ${outfilename}_SIM.py --eventcontent RAWSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN-SIM --fileout file:${outfilename}_sim.root --conditions 106X_upgrade2018_realistic_v11_L1v1 --beamspot Realistic25ns13TeVEarly2018Collision --step SIM --geometry DB:Extended --filein file:${outfilename}_gen.root --era Run2_2018 --runUnscheduled --no_exec --mc -n 9999

#cmsDriver.py step2 --filein file:${outfilename}_gen.root --fileout file:${outfilename}_sim.root --mc --eventcontent RAWSIM --runUnscheduled --datatier GEN-SIM --conditions 106X_upgrade2018_realistic_v15_L1v1 --beamspot Realistic25ns13TeVEarly2018Collision --step SIM --nThreads 8 --geometry DB:Extended --era Run2_2018 --python_filename ${outfilename}_SIM.py -n 9999 --no_exec 
#Run
cmsRun ${outfilename}_SIM.py

#DIGI (premix): 

cmsDriver.py step3  --python_filename ${outfilename}_1_cfg.py --eventcontent PREMIXRAW --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN-SIM-DIGI --fileout file:${outfilename}_step1.root --pileup_input "dbs:/Neutrino_E-10_gun/RunIISummer20ULPrePremix-UL18_106X_upgrade2018_realistic_v11_L1v1-v2/PREMIX" --conditions 106X_upgrade2018_realistic_v11_L1v1 --step DIGI,DATAMIX,L1,DIGI2RAW --procModifiers premix_stage2 --geometry DB:Extended --filein file:${outfilename}_sim.root --datamix PreMix --era Run2_2018 --runUnscheduled --no_exec --mc -n 9999

#cmsDriver.py step3 --filein file:${outfilename}_sim.root --fileout file:${outfilename}_step1.root  --pileup_input "dbs:/Neutrino_E-10_gun/RunIISummer20ULPrePremix-UL18_106X_upgrade2018_realistic_v11_L1v1-v2/PREMIX" --mc --eventcontent PREMIXRAW --runUnscheduled --datatier GEN-SIM-DIGI --conditions 106X_upgrade2018_realistic_v15_L1v1 --step DIGI,DATAMIX,L1,DIGI2RAW --procModifiers premix_stage2 --nThreads 8 --geometry DB:Extended --datamix PreMix --era Run2_2018 --python_filename ${outfilename}_1_cfg.py -n 9999 --no_exec

############
# Generate PreMIX

#cp ${BASEDIR}/input/pu_files2018UL.py .
#cp ${BASEDIR}/input/aod_template2018UL.py .
#sed -i 's/XX-GENSIM-XX/'${outfilename}'/g' aod_template2018UL.py
#sed -i 's/XX-AODFILE-XX/'${outfilename}'/g' aod_template2018UL.py
#mv aod_template2018UL.py ${outfilename}_1_cfg.py

cmsRun ${outfilename}_1_cfg.py


##############
#HLT 
echo "Starting  the HLT Step"
export SCRAM_ARCH=slc7_amd64_gcc530
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_10_2_16_UL/src ] ; then
 echo release CMSSW_10_2_16_UL already exists
else
scram p CMSSW CMSSW_10_2_16_UL
fi
cd CMSSW_10_2_16_UL/src
eval `scram runtime -sh`
scram b -j8
cd -


# cmsDriver command
cmsDriver.py step4  --python_filename ${outfilename}_hlt_cfg.py --eventcontent RAWSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN-SIM-RAW --fileout file:${outfilename}_HLT.root --conditions 102X_upgrade2018_realistic_v15 --customise_commands 'process.source.bypassVersionCheck = cms.untracked.bool(True)' --step HLT:2018v32 --geometry DB:Extended --filein file:${outfilename}_step1.root --era Run2_2018 --no_exec --mc -n 9999

#cmsDriver.py step4 --filein file:${outfilename}_step1.root --fileout file:${outfilename}_HLT.root --mc --eventcontent RAWSIM --datatier GEN-SIM-RAW --conditions 102X_upgrade2018_realistic_v15 --customise_commands 'process.source.bypassVersionCheck = cms.untracked.bool(True)' --step HLT:2018v32 --nThreads 8 --geometry DB:Extended --era Run2_2018 --python_filename ${outfilename}_hlt_cfg.py -n 9999 --no_exec

#Run
cmsRun ${outfilename}_hlt_cfg.py

###########
# Generate RECOAOD 
export SCRAM_ARCH=slc7_amd64_gcc700

source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_10_6_17_patch1/src ] ; then
  echo release CMSSW_10_6_17_patch1 already exists
else
  scram p CMSSW CMSSW_10_6_17_patch1
fi
cd CMSSW_10_6_17_patch1/src
eval `scram runtime -sh`

scram b
cd ../..
cmsDriver.py step5 --python_filename ${outfilename}_reco_cfg.py --eventcontent AODSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier AODSIM --fileout file:${outfilename}_RECO.root  --conditions 106X_upgrade2018_realistic_v11_L1v1 --step RAW2DIGI,L1Reco,RECO,RECOSIM,EI --geometry DB:Extended --filein file:${outfilename}_HLT.root --era Run2_2018 --runUnscheduled --no_exec --mc -n 9999

#cmsDriver.py step5 --filein file:${outfilename}_HLT.root --fileout file:${outfilename}_RECO.root --mc --eventcontent AODSIM --runUnscheduled --datatier AODSIM --conditions 106X_upgrade2018_realistic_v15_L1v1 --step RAW2DIGI,L1Reco,RECO,RECOSIM,EI --nThreads 8 --geometry DB:Extended --era Run2_2018 --python_filename ${outfilename}_reco_cfg.py -n 9999 --no_exec


cmsRun ${outfilename}_reco_cfg.py

##########
#MiniAOD 
export SCRAM_ARCH=slc7_amd64_gcc700

source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_10_6_20/src ] ; then
  echo release CMSSW_10_6_20 already exists
else
  scram p CMSSW CMSSW_10_6_20
fi
cd CMSSW_10_6_20/src
eval `scram runtime -sh`

scram b
cd ../..

cmsDriver.py step6 --python_filename ${outfilename}_miniaod_cfg.py --eventcontent MINIAODSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier MINIAODSIM --fileout file:${outfilename}_miniaod.root --conditions 106X_upgrade2018_realistic_v16_L1v1 --step PAT --procModifiers run2_miniAOD_UL --geometry DB:Extended --filein file:${outfilename}_RECO.root --era Run2_2018 --runUnscheduled --no_exec --mc -n 9999

#cmsDriver.py step6 --python_filename ${outfilename}_miniaod_cfg.py --eventcontent MINIAODSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier MINIAODSIM --fileout file:${outfilename}_miniaod.root  --conditions 106X_upgrade2018_realistic_v16_L1v1 --step PAT --procModifiers run2_miniAOD_UL --geometry DB:Extended --filein file:${outfilename}_RECO.root --era Run2_2018 --runUnscheduled --no_exec --mc -n 9999

#Run
cmsRun ${outfilename}_miniaod_cfg.py

###########
# Stage out #v1
echo "Copying the  MiniAOD  to WISC storage"
#xrdcp ${outfilename}_miniaod.root  root://cmsxrootd.hep.wisc.edu//store/user/sdogra/DarkPhoton/signal_UL2018/${dirname}/${outfilename}_miniaod.root
echo "Copying the  MiniAOD  to FNAL storage"
xrdcp ${outfilename}_miniaod.root  root://cmseos.fnal.gov//store/group/lpcmetx/Monotop/Signal20UL18MiniAODv2/${dirname}/Monotop_${dirname}_${TempNumber}_miniaod.root

echo "Copy  DONE."
