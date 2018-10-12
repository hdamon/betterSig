function [HDR, immediateReturn] = LEXICORE(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


warning('LOADLEXI is experimental and not well tested. ')
  %% The solution is based on a single data file, with the comment:
  %% "It was used to create a QEEG. It might have been collected
  %% on an older Lexicore - I don't know.   That was 4 years ago [in 2005]."
  
  fid = fopen(HDR.FileName,'rb','ieee-le');
  HDR.H1   = fread(fid,[1,128],'uint8')';
  HDR.data = fread(fid,[24,inf],'int16')';
  fclose(fid);
  
  [HDR.NRec]=size(HDR.data,1);
  HDR.NS = 20;
  HDR.SPR = 1;
  HDR.LEXICORE.status = HDR.data(:,21:24);
  s = HDR.data(:,1:20);
  
  HDR.data = s;
  HDR.TYPE = 'native';
  
  %% unkwown parameters
  HDR.SampleRate = NaN;
  HDR.FLAG.UCAL = 1;	% data is not scaled
  HDR.PhysDimCode = zeros(1,HDR.NS);
  HDR.Cal = ones(1,HDR.NS);
  HDR.Off = zeros(1,HDR.NS);
  HDR.Calib = sparse([HDR.Off;diag(HDR.Cal)]);
  HDR.Label = repmat({' '},HDR.NS,1);
  HDR.EVENT.TYP = [];
  HDR.EVENT.POS = [];