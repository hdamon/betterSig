function [HDR, immediateReturn] = RigSys(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
  [thdr,count] = fread(HDR.FILE.FID,[1,1024],'uint8');
  thdr = char(thdr);
  HDR.RigSys.H1 = thdr;
  empty_char = NaN;
  STOPFLAG = 1;
  while (STOPFLAG && ~isempty(thdr));
    [tline, thdr] = strtok(thdr,[13,10,0]);
    [tag, value]  = strtok(tline,'=');
    value = strtok(value,'=');
    if strcmp(tag,'FORMAT ISSUE'),
      HDR.VERSION = value;
    elseif strcmp(tag,'EMPTY HEADER CHARACTER'),
      [t,v]=strtok(value);
      if strcmp(t,'ASCII')
        empty_char = str2double(v);
        STOPFLAG = 0;
      else
        fprintf(HDR.FILE.stderr,'Warning SOPEN (RigSys): Couldnot identify empty character');;
      end;
    end;
  end
  if ~isfield(HDR,'VERSION')
    fprintf(HDR.FILE.stderr,'Error SOPEN (RigSys): could not open file %s. Specification not known.\n',HDR.FileName);
    HDR.TYPE = 'unknown';
    fclose(HDR.FILE.FID);
    return;
  end;
  [thdr,H1] = strtok(thdr,empty_char);
  while ~isempty(thdr);
    [tline, thdr] = strtok(thdr,[13,10,0]);
    [tag, value]  = strtok(tline,'=');
    value = strtok(value,'=');
    if 0,
    elseif strcmp(tag,'HEADER SIZE'),
      HDR.RigSys.H1size = str2double(value);
      if    count == HDR.RigSys.H1size,
      elseif count < HDR.RigSys.H1size,
        tmp = fread(HDR.FILE.FID,[1,HDR.RigSys.H1size-count],'uint8');
        thdr = [thdr,char(tmp)];
      elseif count > HDR.RigSys.H1size,
        status = fseek(HDR.FILE.FID,HDR.RigSys.H1size);
      end;
    elseif strcmp(tag,'CHANNEL HEADER SIZE'),
      HDR.RigSys.H2size = str2double(value);
    elseif strcmp(tag,'FRAME HEADER SIZE'),
      HDR.RigSys.H3size = str2double(value);
    elseif strcmp(tag,'NCHANNELS'),
      HDR.NS = str2double(value);
    elseif strcmp(tag,'SAMPLE INTERVAL'),
      HDR.SampleRate = 1/str2double(value);
    elseif strcmp(tag,'HISTORY LENGTH'),
      HDR.AS.endpos = str2double(value);
    elseif strcmp(tag,'REFERENCE TIME'),
      HDR.RigSys.TO=value;
      HDR.T0(1:6) = round(datevec(value)*1e4)*1e-4;
    end
  end;
  HDR.HeadLen = HDR.RigSys.H1size+HDR.RigSys.H1size*HDR.NS;
  
  [H1,c] = fread(HDR.FILE.FID,[HDR.RigSys.H2size,HDR.NS],'uint8');
  for chan=1:HDR.NS,
    [thdr] = strtok(char(H1(:,chan)'),empty_char);
    while ~isempty(thdr);
      [tline, thdr] = strtok(thdr,[13,10,0]);
      [tag, value]  = strtok(tline,'=');
      value = strtok(value,'=');
      if strcmp(tag,'FULL SCALE'),
        HDR.Gain(chan,1) = str2double(value);
      elseif strcmp(tag,'UNITS'),
        HDR.PhysDim{chan} = [value,' '];
      elseif strcmp(tag,'OFFSET'),
        HDR.Off(chan) = str2double(value);
      elseif 0, strcmp(tag,'CHANNEL DESCRIPTION'),
        HDR.Label{chan} = [value,' '];
      elseif strcmp(tag,'CHANNEL NAME'),
        HDR.Label{chan} = [value,' '];
      elseif strcmp(tag,'SAMPLES PER BLOCK'),
        HDR.AS.SPR(chan) = str2double(value);
      elseif strcmp(tag,'BYTES PER SAMPLE'),
        HDR.Bits(chan) = str2double(value)*8;
      end;
    end;
  end;
  fhsz = HDR.RigSys.H3size*8/HDR.Bits(1);
  s = fread(HDR.FILE.FID,[1024*HDR.NS+fhsz,inf],'int16');
  fclose(HDR.FILE.FID);
  HDR.RigSys.FrameHeaders=s(1:12,:);
  
  for k=1:HDR.NS,
    if k==1, HDR.SPR = HDR.AS.SPR(1);
    else HDR.SPR = lcm(HDR.SPR, HDR.AS.SPR(1));
    end;
  end;
  HDR.AS.bi = [0;cumsum(HDR.AS.SPR(:))];
  HDR.NRec = size(s,2);
  HDR.FLAG.TRIGGERED = 0;
  HDR.data = zeros(HDR.MAXSPR*HDR.NRec,HDR.NS);
  for k = 1:HDR.NS,
    tmp = s(fhsz+[HDR.AS.bi(k)+1:HDR.AS.bi(k+1)],:);
    HDR.data(:,k) = rs(tmp(:),1,HDR.MAXSPR/HDR.AS.SPR(k));
  end;
  HDR.data  = HDR.data(1:HDR.AS.endpos,:);
  HDR.Calib = sparse(2:HDR.NS+1,1:HDR.NS,HDR.Gain(:)./16384);
  
  HDR.FILE.POS = 0;
  HDR.TYPE     = 'native';