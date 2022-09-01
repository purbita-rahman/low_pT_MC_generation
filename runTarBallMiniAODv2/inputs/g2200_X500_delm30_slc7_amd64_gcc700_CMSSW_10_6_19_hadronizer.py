import FWCore.ParameterSet.Config as cms
externalLHEProducer = cms.EDProducer("ExternalLHEProducer",
                                     #args = cms.vstring('XY-Hadronzer_Path/softtrack_monophoton_UL2019_GPT190_01262021_slc7_amd64_gcc700_CMSSW_10_6_0_tarball.tar.xz'),
args = cms.vstring('XY-Hadronzer_Path/g2200_X500_delm30_slc7_amd64_gcc700_CMSSW_10_6_19_tarball.tar.xz'),
#args = cms.vstring('/uscms/home/pprova/nobackup/runTarBallMiniAODv2/inputs/g2200_X100_delm30_slc7_amd64_gcc700_CMSSW_10_6_19_tarball.tar.xz' ),                                     
nEvents = cms.untracked.uint32(99999),
                                     numberOfParameters = cms.uint32(1),
                                     outputFile = cms.string('cmsgrid_final.lhe'),
                                     scriptName = cms.FileInPath('GeneratorInterface/LHEInterface/data/run_generic_tarball_cvmfs.sh')
                                 )
import FWCore.ParameterSet.Config as cms
from Configuration.Generator.Pythia8CommonSettings_cfi import *
from Configuration.Generator.MCTunes2017.PythiaCP5Settings_cfi import *
from Configuration.Generator.PSweightsPythia.PythiaPSweightsSettings_cfi import *


generator = cms.EDFilter("Pythia8HadronizerFilter",
                         maxEventsToPrint = cms.untracked.int32(1),
                         pythiaPylistVerbosity = cms.untracked.int32(1),
                         filterEfficiency = cms.untracked.double(1.0),
                         pythiaHepMCVerbosity = cms.untracked.bool(False),
                         comEnergy = cms.double(13000.),
                         PythiaParameters = cms.PSet(
                             pythia8CommonSettingsBlock,
                             pythia8CP5SettingsBlock,
                             pythia8PSweightsSettingsBlock,
                             processParameters = cms.vstring(
                                 'JetMatching:setMad = off',
                                 'JetMatching:scheme = 1',
                                 'JetMatching:merge = on',
                                 'JetMatching:jetAlgorithm = 2',
                                 'JetMatching:etaJetMax = 5.',
                                 'JetMatching:coneRadius = 1.',
                                 'JetMatching:slowJetPower = 1',
                                 'JetMatching:qCut = 60.', #this is the actual merging scale
                                 'JetMatching:nQmatch = 5', #5 for 5-flavour scheme (matching of b-quarks)
                                 'JetMatching:nJetMax = 2', #number of partons in born matrix element for highest multiplicity
                                 'JetMatching:doShowerKt = off', #off for MLM matching, turn on for shower-kT matching
                             ),
                            parameterSets = cms.vstring('pythia8CommonSettings',
                                                        'pythia8CP5Settings',
                                                        'pythia8PSweightsSettings',
                                                        'processParameters',
                                                    )
                         )
                    )
