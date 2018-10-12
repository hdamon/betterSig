function [HDR, immediateReturn] = SND(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],HDR.Endianity);
  if HDR.FILE.FID < 0,
    return;
  end;
  
  if ~isempty(findstr(HDR.FILE.PERMISSION,'r')),	%%%%% READ
    HDR.FILE.OPEN = 1;
    fseek(HDR.FILE.FID,4,'bof');
    HDR.HeadLen = fread(HDR.FILE.FID,1,'uint32');
    datlen = fread(HDR.FILE.FID,1,'uint32');
    HDR.FILE.TYPE = fread(HDR.FILE.FID,1,'uint32');
    HDR.SampleRate = fread(HDR.FILE.FID,1,'uint32');
    HDR.NS = fread(HDR.FILE.FID,1,'uint32');
    HDR.Label = repmat({' '},HDR.NS,1);
    [tmp,count] = fread(HDR.FILE.FID, [1,HDR.HeadLen-24],'uint8');
    HDR.INFO = char(tmp);
    
  elseif ~isempty(findstr(HDR.FILE.PERMISSION,'w')),	%%%%% WRITE
    if ~isfield(HDR,'NS'),
      HDR.NS = 0;
    end;
    if ~isfield(HDR,'SPR'),
      HDR.SPR = 0;
    end;
    if ~isfinite(HDR.NS)
      HDR.NS = 0;
    end;
    if ~isfinite(HDR.SPR)
      HDR.SPR = 0;
    end;
    if any(HDR.FILE.PERMISSION=='z') && any([HDR.SPR,HDR.NS] <= 0),
      fprintf(HDR.FILE.stderr,'ERROR SOPEN (SND) "wz": Update of HDR.SPR and HDR.NS are not possible.\n',HDR.FileName);
      fprintf(HDR.FILE.stderr,'\t Solution(s): (1) define exactly HDR.SPR and HDR.NS before calling SOPEN(HDR,"wz"); or (2) write to uncompressed file instead.\n');
      fclose(HDR.FILE.FID)
      return;
    end;
    HDR.FILE.OPEN = 2;
    if any([HDR.SPR,HDR.NS] <= 0);
      HDR.FILE.OPEN = 3;
    end;
    if ~isfield(HDR,'INFO')
      HDR.INFO = HDR.FileName;
    end;
    len = length(HDR.INFO);
    if len == 0;
      HDR.INFO = 'INFO';
    else
      HDR.INFO = [HDR.INFO,repmat(' ',1,mod(4-len,4))];
    end;
    HDR.HeadLen = 24+length(HDR.INFO);
    if ~isfield(HDR.FILE,'TYPE')
      HDR.FILE.TYPE = 6; % default float32
    end;
  end;
  
  if HDR.FILE.TYPE==1,
    HDR.GDFTYP =  'uint8';
    HDR.Bits   =  8;
  elseif HDR.FILE.TYPE==2,
    HDR.GDFTYP =  'int8';
    HDR.Bits   =  8;
  elseif HDR.FILE.TYPE==3,
    HDR.GDFTYP =  'int16';
    HDR.Bits   = 16;
  elseif HDR.FILE.TYPE==4,
    HDR.GDFTYP = 'bit24';
    HDR.Bits   = 24;
  elseif HDR.FILE.TYPE==5,
    HDR.GDFTYP = 'int32';
    HDR.Bits   = 32;
  elseif HDR.FILE.TYPE==6,
    HDR.GDFTYP = 'float32';
    HDR.Bits   = 32;
  elseif HDR.FILE.TYPE==7,
    HDR.GDFTYP = 'float64';
    HDR.Bits   = 64;
    
  elseif HDR.FILE.TYPE==11,
    HDR.GDFTYP = 'uint8';
    HDR.Bits   =  8;
  elseif HDR.FILE.TYPE==12,
    HDR.GDFTYP = 'uint16';
    HDR.Bits   = 16;
  elseif HDR.FILE.TYPE==13,
    HDR.GDFTYP = 'ubit24';
    HDR.Bits   = 24;
  elseif HDR.FILE.TYPE==14,
    HDR.GDFTYP = 'uint32';
    HDR.Bits   = 32;
    
  else
    fprintf(HDR.FILE.stderr,'Error SOPEN SND-format: datatype %i not supported\n',HDR.FILE.TYPE);
    return;
  end;
  [d,l,d1,b,HDR.GDFTYP] = gdfdatatype(HDR.GDFTYP);
  HDR.AS.bpb = HDR.NS*HDR.Bits/8;
  
  % Calibration
  if any(HDR.FILE.TYPE==[2:5]),
    HDR.Cal = 2^(1-HDR.Bits);
  else
    HDR.Cal = 1;
  end;
  HDR.Off = 0;
  HDR.Calib = sparse(2:HDR.NS+1,1:HDR.NS,HDR.Cal);
  
  %%%%% READ
  if HDR.FILE.OPEN == 1;
    % check file length
    fseek(HDR.FILE.FID,0,1);
    len = ftell(HDR.FILE.FID);
    if len ~= (datlen+HDR.HeadLen),
      fprintf(HDR.FILE.stderr,'Warning SOPEN SND-format: header information does not fit file length \n');
      datlen = len - HDR.HeadLen;
    end;
    fseek(HDR.FILE.FID,HDR.HeadLen,-1);
    HDR.SPR  = datlen/HDR.AS.bpb;
    HDR.Dur  = HDR.SPR/HDR.SampleRate;
    
    
    %%%%% WRITE
  elseif HDR.FILE.OPEN > 1;
    datlen = HDR.SPR * HDR.AS.bpb;
    fwrite(HDR.FILE.FID,[hex2dec('2e736e64'),HDR.HeadLen,datlen,HDR.FILE.TYPE,HDR.SampleRate,HDR.NS],'uint32');
    fwrite(HDR.FILE.FID,HDR.INFO,'uint8');
    
  end;
  HDR.FILE.POS = 0;
  HDR.NRec = 1;