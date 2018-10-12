function [HDR, immediateReturn] = CTF(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 if any(HDR.FILE.PERMISSION=='r'),
    HDR.FILE.FID  = fopen(fullfile(HDR.FILE.Path,[HDR.FILE.Name,'.res4']),HDR.FILE.PERMISSION,'ieee-be');
    if HDR.FILE.FID<0,
      return
    end;
    HDR.FILE.OPEN = 1;
    HDR.FILE.POS  = 0;
    fseek(HDR.FILE.FID,778,'bof');
    tmp = char(fread(HDR.FILE.FID,255,'uint8')');
    tmp(tmp==':')=' ';
    tmp = str2double(tmp);
    if length(tmp)==3,
      HDR.T0(4:6)=tmp;
    end;
    tmp = char(fread(HDR.FILE.FID,255,'uint8')');
    tmp(tmp=='/')=' ';
    tmp = str2double(tmp);
    if length(tmp)==3,
      HDR.T0(1:3) = tmp;
    end;
    
    HDR.SPR = fread(HDR.FILE.FID,1,'int32');
    HDR.NS = fread(HDR.FILE.FID,1,'int16');
    HDR.CTF.NS2 = fread(HDR.FILE.FID,1,'int16');
    HDR.SampleRate = fread(HDR.FILE.FID,1,'double');
    HDR.Dur = fread(HDR.FILE.FID,1,'double');
    HDR.NRec = fread(HDR.FILE.FID,1,'int16');
    HDR.CTF.NRec2 = fread(HDR.FILE.FID,1,'int16');
    HDR.TriggerOffset = fread(HDR.FILE.FID,1,'int32');
    
    fseek(HDR.FILE.FID,1712,'bof');
    HDR.PID = char(fread(HDR.FILE.FID,32,'uint8')');
    HDR.Operator = char(fread(HDR.FILE.FID,32,'uint8')');
    HDR.FILE.SensorFileName = char(fread(HDR.FILE.FID,60,'uint8')');
    
    %fseek(HDR.FILE.FID,1836,'bof');
    HDR.CTF.RunSize = fread(HDR.FILE.FID,1,'int32');
    HDR.CTF.RunSize2 = fread(HDR.FILE.FID,1,'int32');
    HDR.CTF.RunDescription = char(fread(HDR.FILE.FID,HDR.CTF.RunSize,'uint8')');
    HDR.CTF.NumberOfFilters = fread(HDR.FILE.FID,1,'int16');
    
    for k = 1:HDR.CTF.NumberOfFilters,
      F.Freq = fread(HDR.FILE.FID,1,'double');
      F.Class = fread(HDR.FILE.FID,1,'int32');
      F.Type = fread(HDR.FILE.FID,1,'int32');
      F.NA = fread(HDR.FILE.FID,1,'int16');
      F.A = fread(HDR.FILE.FID,[1,F.NA],'double');
      HDR.CTF.Filter(k) = F;
    end;
    
    tmp = fread(HDR.FILE.FID,[32,HDR.NS],'uint8');
    tmp(tmp<0) = 0;
    tmp(tmp>127) = 0;
    tmp(cumsum(tmp==0)>0)=0;
    HDR.Label = cellstr(char(tmp'));
    
    for k = 1:HDR.NS,
      info.index(k,:) = fread(HDR.FILE.FID,1,'int16');
      info.extra(k,:) = fread(HDR.FILE.FID,1,'int16');
      info.ix(k,:) = fread(HDR.FILE.FID,1,'int32');
      info.gain(k,:) = fread(HDR.FILE.FID,[1,4],'double');
      
      info.index2(k,:) = fread(HDR.FILE.FID,1,'int16');
      info.extra2(k,:) = fread(HDR.FILE.FID,1,'int16');
      info.ix2(k,:)    = fread(HDR.FILE.FID,1,'int32');
      
      fseek(HDR.FILE.FID,1280,'cof');
    end;
    fclose(HDR.FILE.FID);
    
    %%%%% read Markerfile %%%%%
    fid = fopen(fullfile(HDR.FILE.Path,'MarkerFile.mrk'),'rb','ieee-be');
    if fid > 0,
      while ~feof(fid),
        s = fgetl(fid);
        if ~isempty(strmatch('PATH OF DATASET:',s))
          file = fgetl(fid);
          
        elseif 0,
          
        elseif ~isempty(strmatch('TRIAL NUMBER',s))
          N = 0;
          x = fgetl(fid);
          while ~isempty(x),
            tmp = str2double(x);
            N = N+1;
            HDR.EVENT.POS(N,1) = tmp(1)*HDR.SPR+tmp(2)*HDR.SampleRate;
            HDR.EVENT.TYP(N,1) = 1;
            x = fgetl(fid);
          end
        else
          
        end
      end
      fclose(fid);
    end;
    
    HDR.CTF.info = info;
    ix = (info.index==0) | (info.index==1) | (info.index==9);
    ix0 = find(ix);
    HDR.Cal(ix0) = 1./(info.gain(ix0,1) .* info.gain(ix0,2));
    ix0 = find(~ix);
    HDR.Cal(ix0) = 1./info.gain(ix0,2);
    HDR.Calib = sparse(2:HDR.NS+1,1:HDR.NS,HDR.Cal);
    HDR.FLAG.TRIGGERED = HDR.NRec > 1;
    HDR.AS.spb = HDR.NRec * HDR.NS;
    HDR.AS.bpb = HDR.AS.spb * 4;
    
    HDR.CHANTYP = char(repmat(32,HDR.NS,1));
    HDR.CHANTYP(info.index==9) = 'E';
    HDR.CHANTYP(info.index==5) = 'M';
    HDR.CHANTYP(info.index==1) = 'R';
    HDR.CHANTYP(info.index==0) = 'R';
    
    if 0,
      
    elseif strcmpi(CHAN,'MEG'),
      CHAN = find(info.index==5);
    elseif strcmpi(CHAN,'EEG'),
      CHAN = find(info.index==9);
    elseif strcmpi(CHAN,'REF'),
      CHAN = find((info.index==0) | (info.index==1));
    elseif strcmpi(CHAN,'other'),
      CHAN = find((info.index~=0) & (info.index~=1) & (info.index~=5) & (info.index~=9));
    end;
    
    HDR.FILE.FID = fopen(fullfile(HDR.FILE.Path,[HDR.FILE.Name,'.meg4']),'rb','ieee-be');
    HDR.VERSION = char(fread(HDR.FILE.FID,[1,8],'uint8'));
    HDR.HeadLen = ftell(HDR.FILE.FID);
    fseek(HDR.FILE.FID,0,'eof');
    HDR.AS.endpos = ftell(HDR.FILE.FID);
    fseek(HDR.FILE.FID,HDR.HeadLen,'bof');
  end;