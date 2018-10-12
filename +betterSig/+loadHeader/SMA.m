function [HDR, immediateReturn] = SMA(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 try     % MatLAB default is binary, force Mode='rt';
    HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'t'],'ieee-le');
  catch 	% Octave 2.1.50 default is text, but does not support Mode='rt',
    HDR.FILE.FID = fopen(HDR.FileName,HDR.FILE.PERMISSION,'ieee-le');
  end
  numbegin=0;
  HDR.H1 = '';
  delim = char([abs('"='),10,13]);
  while ~numbegin,
    line = fgetl(HDR.FILE.FID);
    HDR.H1 = [HDR.H1, line];
    if strncmp('"NCHAN%"',line,8)
      [tmp,line] = strtok(line,'=');
      [tmp,line] = strtok(line,delim);
      HDR.NS = str2double(char(tmp));
    end
    if strncmp('"NUM.POINTS"',line,12)
      [tmp,line] = strtok(line,'=');
      [tmp,line] = strtok(line,delim);
      HDR.SPR = str2double(tmp);
    end
    if strncmp('"ACT.FREQ"',line,10)
      [tmp,line] = strtok(line,'=');
      [tmp,line] = strtok(line,delim);
      HDR.SampleRate= str2double(tmp);
    end
    if strncmp('"DATE$"',line,7)
      [tmp,line] = strtok(line,'=');
      [date,line] = strtok(line,delim);
      [tmp,date]=strtok(date,'-');
      HDR.T0(3) = str2double(tmp);
      [tmp,date]=strtok(date,'-');
      HDR.T0(2) = str2double(tmp);
      [tmp,date]=strtok(date,'-');
      HDR.T0(1) = str2double(tmp);
    end
    if strncmp('"TIME$"',line,7)
      [tmp,line] = strtok(line,'=');
      [time,line] = strtok(line,delim);
      [tmp,date]=strtok(time,':');
      HDR.T0(4) = str2double(tmp);
      [tmp,date]=strtok(date,':');
      HDR.T0(5) = str2double(tmp);
      [tmp,date]=strtok(date,':');
      HDR.T0(6) = str2double(tmp);
    end;
    if strncmp('"UNITS$[]"',line,10)
      [tmp,line] = strtok(char(line),'=');
      for k=1:HDR.NS,
        [tmp,line] = strtok(line,[' ,',delim]);
        HDR.PhysDim(k,1:length(tmp)) = tmp;
      end;
    end
    if strncmp('"CHANNEL.RANGES[]"',line,18)
      [tmp,line] = strtok(line,'= ');
      [tmp,line] = strtok(line,'= ');
      for k=1:HDR.NS,
        [tmp,line] = strtok(line,[' ',delim]);
        [tmp1, tmp]=strtok(tmp,'(),');
        HDR.PhysMin(k,1)=str2double(tmp1);
        [tmp2, tmp]=strtok(tmp,'(),');
        HDR.PhysMax(k,1)=str2double(tmp2);
      end;
    end
    if strncmp('"CHAN$[]"',line,9)
      [tmp,line] = strtok(line,'=');
      for k=1:HDR.NS,
        [tmp,line] = strtok(line,[' ,',delim]);
        HDR.Label{k,1} = char(tmp);
      end;
    end
    if 0,strncmp('"CHANNEL.LABEL$[]"',line,18)
      [tmp,line] = strtok(line,'=');
      for k=1:HDR.NS,
        [HDR.Label{k,1},line] = strtok(line,delim);
      end;
    end
    if strncmp(line,'"TR"',4)
      HDR.H1 = HDR.H1(1:length(HDR.H1)-length(line));
      line = fgetl(HDR.FILE.FID); % get the time and date stamp line
      tmp=fread(HDR.FILE.FID,1,'uint8'); % read sync byte hex-AA char
      if tmp~=hex2dec('AA');
        fprintf(HDR.FILE.stderr,'Error SOPEN type=SMA: Sync byte is not "AA"\n');
      end;
      numbegin=1;
    end
  end
  
  %%%%%%%%%%%%%%%%%%% check file length %%%%%%%%%%%%%%%%%%%%
  
  HDR.FILE.POS= 0;
  HDR.HeadLen = ftell(HDR.FILE.FID);  % Length of Header
  
  fclose(HDR.FILE.FID);
  %% PERMISSION = PERMISSION(PERMISSION~='t');       % open in binary mode
  HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
  
  fseek(HDR.FILE.FID,HDR.HeadLen,'bof');
  %[HDR.AS.endpos,HDR.HeadLen,HDR.NS,HDR.SPR,HDR.NS*HDR.SPR*4,HDR.AS.endpos-HDR.HeadLen - HDR.NS*HDR.SPR*4]
  HDR.AS.endpos = HDR.NS*HDR.SPR*4 - HDR.HeadLen;
  if HDR.FILE.size-HDR.HeadLen ~= HDR.NS*HDR.SPR*4;
    fprintf(HDR.FILE.stderr,'Warning SOPEN TYPE=SMA: Header information does not fit size of file\n');
    fprintf(HDR.FILE.stderr,'\tProbably more than one data segment - this is not supported in the current version of SOPEN\n');
  end
  HDR.AS.bpb    = HDR.NS*4;
  HDR.AS.endpos = (HDR.AS.endpos-HDR.HeadLen)/HDR.AS.bpb;
  HDR.Dur = 1/HDR.SampleRate;
  HDR.NRec = 1;
  
  if ~isfield(HDR,'SMA')
    HDR.SMA.EVENT_CHANNEL= 1;
    HDR.SMA.EVENT_THRESH = 2.3;
  end;
  HDR.Filter.T0 = zeros(1,length(HDR.SMA.EVENT_CHANNEL));
  