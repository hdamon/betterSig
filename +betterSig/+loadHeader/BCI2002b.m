function [HDR, immediateReturn] = BCI2002b(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 % BCI competition 2002, dataset b (EEG synchronized imagined movement task) provided by Allen Osman, University of Pennsylvania).
  HDR.NS = 59;
  HDR.GDFTYP = 16; % float32
  if any(HDR.FILE.PERMISSION=='r'),
    HDR.FILE.FID = fopen(fullfile(HDR.FILE.Path, 'alldata.bin'),[HDR.FILE.PERMISSION,'b'],'ieee-be');
    HDR.data = fread(HDR.FILE.FID,[HDR.NS,inf],'float32')';
    fclose(HDR.FILE.FID);
    HDR.SPR = size(HDR.data,1);
    HDR.NRec = 1;
    HDR.SampleRate = 100; % Hz
    HDR.FILE.POS = 0;
    if ~isfield(HDR,'THRESHOLD')
      HDR.THRESHOLD = repmat([-125,124.93],HDR.NS,1)
    end;
    
    x1 = load(fullfile(HDR.FILE.Path, 'lefttrain.events'));
    x2 = load(fullfile(HDR.FILE.Path, 'righttrain.events'));
    x3 = load(fullfile(HDR.FILE.Path, 'test.events'));
    x  = [x1; x2; x3];
    HDR.EVENT.POS = x(:,1);
    HDR.EVENT.TYP = (x(:,2)==5)*hex2dec('0301') + (x(:,2)==6)*hex2dec('0302') + (x(:,2)==7)*hex2dec('030f');
    
    HDR.TYPE = 'native';
    
    tmp = HDR.FILE.Path;
    if tmp(1)~='/',
      tmp = fullfile(pwd,tmp);
    end;
    while ~isempty(tmp)
      if exist(fullfile(tmp,'sensorlocations.txt'))
        fid = fopen(fullfile(tmp,'sensorlocations.txt'));
        s = fread(fid,[1,inf],'uint8=>char');
        fclose(fid);
        [NUM, STATUS,STRARRAY] = str2double(s);
        HDR.Label = STRARRAY(:,1);
        HDR.ELEC.XYZ = NUM(:,2:4);
        tmp = '';
      end;
      tmp = fileparts(tmp);
    end;
  end;