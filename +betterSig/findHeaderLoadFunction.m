function loadFuncHandle = findHeaderLoadFunction(TYPE)
% Find the header load function by filetype
%
% loadFuncHandle = findHeaderLoadFunction(TYPE)
%

import betterSig.loadHeader.*

switch lower(TYPE)
  case {'edf','gdf','bdf'}, loadFuncHandle = @EDF;
  case {'bkr'}, loadFuncHandle = @BKR;
  case {'cnt','avg','eeg'},loadFuncHandle = @CNT_AVG_EEG;
  case {'epl'}, loadFuncHandle = @EPL;
  case {'eprime'}, loadFuncHandle = @ePRIME;
  case {'fef'}, loadFuncHandle = @FEF;
  case {'scp'}, loadFuncHandle = @SCP;
  case {'ebs'}, loadFuncHandle = @EBS;
  case {'rdhe'}, loadFuncHandle = @rhdE;
  case {'alpha'}, loadFuncHandle = @alpha;
  case {'demg'}, loadFuncHandle = @DEMG;
  case {'acq'}, loadFuncHandle = @ACQ;
  case {'ako'}, loadFuncHandle = @AKO;
  case {'alice4'}, loadFuncHandle = @ALICE4;
  case {'ates'}, loadFuncHandle = @ATES;
  case {'blsc1'}, loadFuncHandle = @BLSC1;
  case {'blsc2'}, loadFuncHandle = @BLSC2;
  case {'lexicore'},loadFuncHandle = @LEXICORE;
  case {'micromed trc'}, loadFuncHandle = @MicroMedTRC;
  case {'nxa'}, loadFuncHandle = @NXA;
  case {'rigsys'}, loadFuncHandle = @RigSys;
  case {'snd' }, loadFuncHandle = @SND;
  case {'delta'}, loadFuncHandle = @Delta;
  case {'sigma'}, loadFuncHandle = @Sigma;
  case {'eeg-1100'}, loadFuncHandle = @EEG_1100;
  case {'gtf'}, loadFuncHandle = @GTF;
  case {'matrixmarket'}, loadFuncHandle = @MatrixMarket;
  case {'mfer'}, loadFuncHandle = @MFER;
  case {'mpeg'}, loadFuncHandle = @MPEG;
  case {'qtff'}, loadFuncHandle = @QTFF;
  case {'asf'}, loadFuncHandle = @ASF;
  case {'midi'}, loadFuncHandle = @MIDI;
  case {'aif','iff','wav','avi'}, loadFuncHandle = @WAVAVI;
  case {'flac'}, loadFuncHandle = @FLAC;
  case {'ogg'}, loadFuncHandle = @OGG;
  case {'persyst'},loadFuncHandle = @Persyst;
  case {'rmf'}, loadFuncHandle = @RMF;
  case {'egi'}, loadFuncHandle = @EGI;
  case {'team'}, loadFuncHandle = @TEAM;
  case {'uff5b'}, loadFuncHandle = @UFF5b;
  case {'uff58b'}, loadFuncHandle = @UFF58b;
  case {'wft'}, loadFuncHandle = @WFT;
  case {'wg1'}, loadFuncHandle = @WG1;
  case {'ldr'}, loadFuncHandle = @LDR;
  case {'sma'}, loadFuncHandle = @SMA;
  case {'rdf'}, loadFuncHandle = @RDF;
  case {'labview'}, loadFuncHandle = @LABVIEW;
  case {'rg64'}, loadFuncHandle = @RG64;
  case {'ddf'}, loadFuncHandle = @DDF;
  case {'mit'}, loadFuncHandle = @MIT;
  case {'mit-atr'}, loadFuncHandle = @MIT_ATR;
  case {'tms32'}, loadFuncHandle = @TMS32;
  case {'tmsilog'}, loadFuncHandle = @TMSiLOG;
  case {'daq'}, loadFuncHandle = @DAQ;
  case {'mat4'}, loadFuncHandle = @MAT4;
  case {'bci2002b'}, loadFuncHandle = @BCI2002b;
  case {'bci2003_ia+b'}, loadFuncHandle = @BCI2003Iab;
  case {'bci2003_iii'}, loadFuncHandle = @BCI2003_III;
  case {'bci2000'}, loadFuncHandle = @BCI2000;
  case {'biosig'}, loadFuncHandle = @BioSig;
  case {'cfwb'}, loadFuncHandle = @CFWB;
  case {'ishne'}, loadFuncHandle = @ISHNE;
  case {'ddt'}, loadFuncHandle = @DDT;
  case {'nex'}, loadFuncHandle = @NEX;
  case {'plexcon'}, loadFuncHandle = @PLEXCON;
  case {'nicolet'}, loadFuncHandle = @Nicolet;
  case {'seg2'}, loadFuncHandle = @SEG2;
  case {'sigif'}, loadFuncHandle = @SIGIF;
  case {'ainf'}, loadFuncHandle = @AINF;
  case {'ctf'}, loadFuncHandle = @CTF;
  case {'brainvision_markerfile'}, loadFuncHandle = @BrainVision_Marker;
  case {'brainvision'}, loadFuncHandle = @BrainVision;
  case {'eeprobe'}, loadFuncHandle = @EEProbe;
  case {'famos'}, loadFuncHandle = @FAMOS;
  case {'fif'}, loadFuncHandle = @FIF;
  case {'andrewsherzberg1985'}, loadFuncHandle = @AndrewsHerzberg1985;
  case {'cinc2007challenge'}, loadFuncHandle = @CinC2007Challenge;
  case {'et-meg'}, loadFuncHandle = @ET_MEG;
  case {'eg-met:sqd'}, loadFuncHandle = @ET_MEG_SQD;
  case {'wineeg'}, loadFuncHandle = @WINEEG;
  case {'fs3'}, loadFuncHandle = @FS3;
  case {'fs4'}, loadFuncHandle = @FS4;
  case {'geo:stl:bin'}, loadFuncHandle = @GEO_STL_BIN;
  case {'tri'}, loadFuncHandle = @TRI;
  case {'dicom'}, loadFuncHandle = @DICOM;
  case {'dxf'}, loadFuncHandle = @DXF;
  case {'stx'}, loadFuncHandle = @STX;
  case {'abf2'}, loadFuncHandle = @ABF2;
  case {'abf'}, loadFuncHandle = @ABF;
  case {'atf'}, loadFuncHandle = @ATF;
  case {'cse'}, loadFuncHandle = @CSE;
  case {'embla'}, loadFuncHandle = @EMBLA;
  case {'etg4000'}, loadFuncHandle = @ETG4000;
  case {'nakamura'}, loadFuncHandle = @nakamura;
  case {'biff'}, loadFuncHandle = @BIFF;
  case {'ascii:ibi'}, loadFuncHandle = @ASCII_IBI;
  case {'hl7aecg','xml'}, loadFuncHandle = @HL7aECG;
  case {'zip'}, loadFuncHandle = @ZIP;
  case {'image:'}, loadFuncHandle = @IMAGE;
  case {'unknown'}, loadFuncHandle = @unknown;    
  otherwise, loadFuncHandle = @FAILURE;
end

end

function [HDR, immediateReturn] = FAILURE(HDR)
% Return function for unknown filetype.
HDR.FILE.FID = -1;
immediateReturn = true;
end



