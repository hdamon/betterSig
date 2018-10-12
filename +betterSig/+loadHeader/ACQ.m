function [HDR, immediateReturn] = ACQ(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
  
  %--------    Fixed Header
  ItemHeaderLen = fread(HDR.FILE.FID,1,'uint16');
  HDR.VERSION = fread(HDR.FILE.FID,1,'uint32');
  HDR.ACQ.ExtItemHeaderLen = fread(HDR.FILE.FID,1,'uint32');
  
  HDR.NS = fread(HDR.FILE.FID,1,'int16');
  HDR.ACQ.HorizAxisType = fread(HDR.FILE.FID,1,'int16');
  HDR.ACQ.CurChannel = fread(HDR.FILE.FID,1,'int16');
  HDR.ACQ.SampleTime = fread(HDR.FILE.FID,1,'float64')/1000;
  HDR.SampleRate = 1/HDR.ACQ.SampleTime;
  HDR.TimeOffset = fread(HDR.FILE.FID,1,'float64')/1000;
  HDR.TimeScale  = fread(HDR.FILE.FID,1,'float64');
  HDR.ACQ.TimeCursor1  = fread(HDR.FILE.FID,1,'float64');
  HDR.ACQ.TimeCursor2  = fread(HDR.FILE.FID,1,'float64');
  HDR.ACQ.rcWindow  = fread(HDR.FILE.FID,1,'float64');
  HDR.ACQ.MeasurementType = fread(HDR.FILE.FID,6,'int16');
  HDR.ACQ.HiLite    = fread(HDR.FILE.FID,2,'uint8');
  HDR.FirstTimeOffset = fread(HDR.FILE.FID,1,'float64');
  
  fseek(HDR.FILE.FID,HDR.ACQ.ExtItemHeaderLen,'bof');
  
  % --------   Variable Header
  
  % --------   Per Channel data section
  HDR.Off = zeros(HDR.NS,1);
  HDR.Cal = ones(HDR.NS,1);
  HDR.ChanHeaderLen = zeros(HDR.NS,1);
  offset = ftell(HDR.FILE.FID);
  for k = 1:HDR.NS;
    fseek(HDR.FILE.FID,offset+sum(HDR.ChanHeaderLen),'bof');
    HDR.ChanHeaderLen(k) = fread(HDR.FILE.FID,1,'uint32');
    HDR.ChanSel(k) = fread(HDR.FILE.FID,1,'int16');
    HDR.Label{k} = char(fread(HDR.FILE.FID,[1,40],'uint8'));
    rgbColor = fread(HDR.FILE.FID,4,'int8');
    DispChan = fread(HDR.FILE.FID,2,'int8');
    HDR.Off(k) = fread(HDR.FILE.FID,1,'float64');
    HDR.Cal(k) = fread(HDR.FILE.FID,1,'float64');
    HDR.PhysDim{k} = char(fread(HDR.FILE.FID,[1,20],'uint8'));
    HDR.ACQ.BufLength(k) = fread(HDR.FILE.FID,1,'int32');
    HDR.AmpGain(k) = fread(HDR.FILE.FID,1,'float64');
    HDR.AmpOff(k) = fread(HDR.FILE.FID,1,'float64');
    HDR.ACQ.ChanOrder = fread(HDR.FILE.FID,1,'int16');
    HDR.ACQ.DispSize = fread(HDR.FILE.FID,1,'int16');
    
    if HDR.VERSION >= 34,
      fseek(HDR.FILE.FID,10,'cof');
    end;
    if HDR.VERSION >= 38,   % version of Acq 3.7.0-3.7.2 (Win 98, 98SE, NT, Me, 2000) and above
      HDR.Description(k,1:128) = fread(HDR.FILE.FID,[1,128],'uint8');
      HDR.ACQ.VarSampleDiv(k) = fread(HDR.FILE.FID,1,'uint16');
    else
      HDR.ACQ.VarSampleDiv(k) = 1;
    end;
    if HDR.VERSION >= 39,  % version of Acq 3.7.3 or above (Win 98, 98SE, 2000, Me, XP)
      HDR.ACQ.VertPrecision(k) = fread(HDR.FILE.FID,1,'uint16');
    end;
  end;
  HDR.Calib = [HDR.Off(:).';diag(HDR.Cal)];
  HDR.SPR = HDR.ACQ.VarSampleDiv(1);
  for k = 2:length(HDR.ACQ.VarSampleDiv);
    HDR.SPR = lcm(HDR.SPR,HDR.ACQ.VarSampleDiv(k));
  end;
  HDR.NRec =  floor(min(HDR.ACQ.BufLength.*HDR.ACQ.VarSampleDiv/HDR.SPR));
  HDR.AS.SPR = HDR.SPR./HDR.ACQ.VarSampleDiv';
  HDR.AS.spb = sum(HDR.AS.SPR);	% Samples per Block
  HDR.AS.bi = [0;cumsum(HDR.AS.SPR(:))];
  HDR.ACQ.SampleRate = 1./(HDR.AS.SPR*HDR.ACQ.SampleTime);
  HDR.SampleRate = 1/HDR.ACQ.SampleTime;
  HDR.Dur = HDR.SPR*HDR.ACQ.SampleTime;
  
  %--------   foreign data section
  ForeignDataLength = fread(HDR.FILE.FID,1,'int16');
  HDR.ACQ.ForeignDataID = fread(HDR.FILE.FID,1,'uint16');
  HDR.ACQ.ForeignData = fread(HDR.FILE.FID,[1,ForeignDataLength-4],'uint8');
  %fseek(HDR.FILE.FID,ForeignDataLength-2,'cof');
  
  %--------   per channel data type section
  offset3 = 0;
  HDR.AS.bpb = 0;
  for k = 1:HDR.NS,
    sz = fread(HDR.FILE.FID,1,'uint16');
    HDR.AS.bpb = HDR.AS.bpb + HDR.AS.SPR(k)*sz;
    offset3 = offset3 + HDR.ACQ.BufLength(k) * sz;
    % ftell(HDR.FILE.FID),
    typ = fread(HDR.FILE.FID,1,'uint16');
    if ~any(typ==[1,2])
      fprintf(HDR.FILE.stderr,'Warning SOPEN (ACQ): invalid or unknonw data type in file %s.\n',HDR.FileName);
    end;
    HDR.GDFTYP(k) = 31-typ*14;   % 1 = int16; 2 = double
  end;
  HDR.AS.BPR  = ceil(HDR.AS.SPR.*GDFTYP_BYTE(HDR.GDFTYP+1)');
  while any(HDR.AS.BPR  ~= HDR.AS.SPR.*GDFTYP_BYTE(HDR.GDFTYP+1)');
    fprintf(2,'\nError SOPEN (ACQ): block configuration in file %s not supported.\n',HDR.FileName);
  end;
  
  % prepare SREAD for different data types
  n = 0;
  typ = [-1;HDR.GDFTYP(:)];
  for k = 1:HDR.NS;
    if (typ(k) == typ(k+1)),
      HDR.AS.c(n)   = HDR.AS.c(n)  + HDR.AS.SPR(k);
      HDR.AS.c2(n)  = HDR.AS.c2(n) + HDR.AS.BPR(k);
    else
      n = n + 1;
      HDR.AS.c(n)   = HDR.AS.SPR(k);
      HDR.AS.c2(n)  = HDR.AS.BPR(k);
      HDR.AS.TYP(n) = HDR.GDFTYP(k);
    end;
  end;
  
  HDR.HeadLen = HDR.ACQ.ExtItemHeaderLen + sum(HDR.ChanHeaderLen) + ForeignDataLength + 4*HDR.NS;
  HDR.FILE.POS = 0;
  HDR.FILE.OPEN = 1;
  HDR.AS.endpos = HDR.HeadLen + offset3;
  fseek(HDR.FILE.FID,HDR.AS.endpos,'bof');
  
  %--------  Markers Header section
  len = fread(HDR.FILE.FID,1,'uint32');
  EVENT.N = fread(HDR.FILE.FID,1,'uint32');
  HDR.EVENT.POS = repmat(nan, EVENT.N ,1);
  HDR.EVENT.TYP = repmat(nan, EVENT.N ,1);
  
  for k = 1:EVENT.N,
    %HDR.Event(k).Sample = fread(HDR.FILE.FID,1,'int32');
    HDR.EVENT.POS(k) = fread(HDR.FILE.FID,1,'int32');
    tmp = fread(HDR.FILE.FID,4,'uint16');
    HDR.Event(k).selected = tmp(1);
    HDR.Event(k).TextLocked = tmp(2);
    HDR.Event(k).PositionLocked = tmp(3);
    textlen = tmp(4);
    HDR.Event(k).Text = fread(HDR.FILE.FID,textlen,'uint8');
  end;
  fseek(HDR.FILE.FID,HDR.HeadLen,'bof');
  
  