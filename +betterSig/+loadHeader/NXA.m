function [HDR, immediateReturn] = NXA(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


% Nexstim TMS-compatible EEG system called eXimia
  HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
  warning('support of NXA format not completed');
  HDR.SampleRate = 1450; % ???
  HDR.NS   = 64;
  HDR.NRec = 1;
  HDR.Cal  = ones(HDR.NS,1);
  HDR.Cal(5:64) = 0.076294; %EEG
  HDR.Cal(4) = 0.381470;    %EOG
  HDR.Calib  = sparse(2:HDR.NS+1,1:HDR.NS,HDR.Cal);
  HDR.GDFTYP = 3;
  HDR.Label  = [{'TRIG1';'TRIG2';'TRIG3';'EOG'};cellstr(repmat('EEG',60,1))];
  HDR.PhysDimCode = repmat(4275,HDR.NS,1); % uV
  [HDR.data] = fread(HDR.FILE.FID,[HDR.NS,inf],'int16')';
  HDR.SPR    = size(HDR.data,1);
  fclose(HDR.FILE.FID);
  HDR.FILE.POS = 0;
  HDR.TYPE   = 'native';