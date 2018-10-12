function [HDR, immediateReturn] = EPL(HDR,CHAN,MODE,ReRefMx) 
   immediateReturn = false; % Default Value


HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
  fprintf(HDR.FILE.stderr,'Warning SOPEN: Implementing EPL format not well tested, yet.\n');
  HDR.EPL.H1 = fread(HDR.FILE.FID,[1,64],'uint16');
  HDR.NS     = HDR.EPL.H1(3);
  HDR.Label  = char(fread(HDR.FILE.FID,[4,32],'uint8')');
  HDR.EPL.H2 = char(fread(HDR.FILE.FID,[1,256],'uint8'));
  ix = strfind(HDR.EPL.H2,' ');
  %HDR.Patient.Name = HDR.EPL.H2(1:ix(2)); % do not support clear text name
  tmp = str2double(HDR.EPL.H2(ix(2)+1:ix(3)-1),'/'); % dd/mm/yy format
  HDR.T0(1:3)= tmp([3,2,1]) + [2000,0,0];
  HDR.HeadLen= ftell(HDR.FILE.FID);
  HDR.SPR    = 256;
  HDR.AS.bpb = HDR.NS*2*(HDR.SPR+8);
  HDR.NRec   = (HDR.FILE.size-HDR.HeadLen)/HDR.AS.bpb;
  HDR.SampleRate = 1e5/HDR.EPL.H1(10);
  HDR.Cal    = HDR.EPL.H1(6)*HDR.EPL.H1(7)*10;
  HDR.PhysDim= repmat({'uV'},HDR.NS,1);
  if (HDR.Cal==0)
    HDR.Cal = 1/50000;
    HDR.FLAG.OVERFLOWDETECTION = 0;
    fprintf(HDR.FILE.stderr,'Warning SOPEN (EPL): calibration information in file %s is missing. Assume Gain=50000.\n',HDR.FileName);
  end;
  HDR.Calib  = sparse(2:HDR.NS+1,1:HDR.NS,HDR.Cal);
  HDR.delay  = HDR.EPL.H1(8)*1e-3;
  HDR.EPL.cprecis = HDR.EPL.H1(19); 	%channel precision*256.pts
  HDR.Filter.HighPass = 0.01;
  HDR.Filter.LowPass  = 100;
  HDR.Dur    = HDR.SPR/HDR.SampleRate;
  HDR.FILE.POS  = 0;
  HDR.FILE.OPEN = 1;
  
  fid = fopen(fullfile(HDR.FILE.Path,[HDR.FILE.Name,'.log']),[HDR.FILE.PERMISSION,'b'],'ieee-le');
  if (fid>0),
    % read log file
    ev1 = fread(fid,[4,inf],'uint16')';
    fclose(fid);
    ev1(:,2) = ev1(:,2:3)*[2^16;1];
    ev1(:,3) = floor(ev1(:,4)/256);
    ev1(:,4) = rem(ev1(:,4),256);
    HDR.EPL.ev1   = ev1;
    HDR.EVENT.POS = ev1(ev1(:,1)<2^15,2);
    HDR.EVENT.TYP = ev1(ev1(:,1)<2^15,1);
  else
    fprintf(HDR.FILE.stderr,'Warning SOPEN (EPL): log-file not found, use the mark track for reading the event information - some Event positions might be off by 1 sample.\n');
    % read mark track
    fseek(HDR.FILE.FID,HDR.HeadLen,'bof');
    [ev2, count] = fread(HDR.FILE.FID,inf,'256*uint16=>uint16',HDR.NS*HDR.SPR*2);
    fseek(HDR.FILE.FID,HDR.HeadLen,'bof');
    
    ev2(1:256:end)= 0;     % remove the "record number" (1st word of each segment) from the "mark track"
    HDR.EVENT.POS = find((ev2>0) & (ev2<2^15));      % identify all events, remove deleted events (i.e. high bit ='1')
    HDR.EVENT.TYP = ev2(HDR.EVENT.POS);
  end;
  