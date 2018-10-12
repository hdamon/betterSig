function [HDR, immediateReturn] = BrainVision(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 % get the header information from the VHDR ascii file
  fid = fopen(HDR.FileName,'rt');
  if fid<0,
    disp('WTF');
    fprintf('Error SOPEN: could not open file %s\n',HDR.FileName);
    return;
  end;
  tline = fgetl(fid);
  HDR.BV.SkipLines = 0;
  HDR.BV.SkipColumns = 0;
  UCAL = 0;
  flag = 1;
  while ~feof(fid),
    tline = fgetl(fid);
    if isempty(tline),
    elseif tline(1)==';',
    elseif tline(1)==10,
    elseif tline(1)==13,    % needed for Octave
    elseif strncmp(tline,'[Common Infos]',14)
      flag = 2;
    elseif strncmp(tline,'[Binary Infos]',14)
      flag = 3;
    elseif strncmp(tline,'[ASCII Infos]',13)
      flag = 3;
    elseif strncmp(tline,'[Channel Infos]',14)
      flag = 4;
    elseif strncmp(tline,'[Coordinates]',12)
      flag = 5;
    elseif strncmp(tline,'[Marker Infos]',12)
      flag = 6;
    elseif strncmp(tline,'[Comment]',9)
      flag = 7;
    elseif strncmp(tline,'[',1)     % any other segment
      flag = 8;
      
    elseif any(flag==[2,3]),
      [t1,r] = strtok(tline,'=');
      [t2,r] = strtok(r,['=',char([10,13])]);
      [n2,v2,s2] = str2double(t2);
      if isempty(n2),
      elseif isnan(n2)
        HDR.BV = setfield(HDR.BV,t1,t2);
      else
        HDR.BV = setfield(HDR.BV,t1,n2);
      end;
      if strcmp(t1,'NumberOfChannels')
        HDR.NS = n2;
      elseif strcmpi(t1,'SamplingInterval')
        HDR.BV.SamplingInterval = n2;
      end;
    elseif flag==4,
      [t1,r] = strtok(tline,'=');
      [t2,r] = strtok(r, ['=',char([10,13])]);
      [chan, stat1] = str2double(t1(3:end));
      ix = [find(t2==','),length(t2)+1];
      tmp = [t2(1:ix(1)-1),' '];
      ix2 = strfind(tmp,'\1');
      for k=length(ix2):-1:1,  % replace '\1' with comma
        tmp = [tmp(1:ix2(k)-1),',',tmp(ix2(k)+2:end)];
      end;
      HDR.Label{chan,1} = tmp;
      HDR.BV.reference{chan,1} = t2(ix(1)+1:ix(2)-1);
      [v, stat] = str2double(t2(ix(2)+1:ix(3)-1));          % in microvolt
      if (prod(size(v))==1) && ~any(stat)
        HDR.Cal(chan) = v;
      else
        UCAL = 1;
        HDR.Cal(chan) = 1;
      end;
      tmp = t2(ix(3)+1:end);
      if isequal(tmp,char([194,'�V'])),
        tmp = tmp(2:3);
      elseif isempty(tmp),
        tmp = '�V';
      end;
      HDR.PhysDim{chan,1} = tmp;
      
    elseif flag==5,
      % Coordinates: <R>,<theta>,<phi>
      tline(tline=='=')=',';
      v = str2double(tline(3:end));
      chan = v(1); R=v(2); Theta = v(3)*pi/180; Phi = v(4)*pi/180;
      HDR.ELEC.XYZ(chan,:) = R*[sin(Theta).*cos(Phi),sin(Theta).*sin(Phi),cos(Theta)];
      
    elseif (flag>=7) && (flag<8),
      if flag==7,
        if tline(1)=='#',
          flag = 7.1;
        end;
      elseif flag==7.1,
        if (tline(1)<'0') || (tline(1)>'9'),
          if ~isempty(strfind(tline,'Impedance'));
            ix1 = find(tline=='[');
            ix2 = find(tline==']');
            Zunit = tline(ix1+1:ix2-1);
            [Zcode,Zscale] = physicalunits(Zunit);
            flag = 7.2; % stop
          end;
        else
          %[n,v,s] = str2double(tline(19:end));
          [n,v,s] = str2double(tline);
          ch = n(1);
          if ch>0,
            HDR.Label{ch} = tline(7:18);
            HDR.Cal(ch) = n(4);
            if v(3),
              HDR.PhysDim{ch} = s{5}(strncmp(s{5},char(194),1)+1:end);
            end;
            HDR.Filter.HighPass(ch)= 1/(2*pi*n(5+(v(3)~=0))); % Low Cut Off [s]: f = 1/(2.pi.tau)
            HDR.Filter.LowPass(ch) = n(6+(v(3)~=0)); % High Cut Off [Hz]
            HDR.Filter.Notch(ch)   = strcmpi(s{7+(v(3)~=0)},'on');
          end;
          if ch==HDR.NS,
            flag=7.3;
          end;
        end;
      elseif flag==7.2,
        [n,v,s]=str2double(tline,[': ',9]);
        ch = strmatch(s{1},HDR.Label);
        if ~isempty(strfind(tline,'Out of Range!'))
          n(2) = Inf;
        end;
        if any(ch),
          HDR.Impedance(ch,1) = n(2)*Zscale;
        end;
      end;
    end;
  end;
  fclose(fid);
  
  % convert the header information to BIOSIG standards
  HDR.SampleRate = 1e6/HDR.BV.SamplingInterval;      % sampling rate in Hz
  HDR.NRec  = 1;		% it is a continuous datafile, therefore one record
  HDR.Calib = [zeros(1,HDR.NS) ; diag(HDR.Cal)];  % is this correct?
  HDR.FLAG.TRIGGERED = 0;
  
  if ~isfield(HDR.BV,'BinaryFormat')
    % default
    HDR.GDFTYP = 3; % 'int16';
    HDR.AS.bpb = HDR.NS * 2;
    if ~isfield(HDR,'THRESHOLD'),
      HDR.THRESHOLD = repmat([-2^15,2^15-1],HDR.NS,1);
    end;
  elseif strncmpi(HDR.BV.BinaryFormat, 'int_16',6)
    HDR.GDFTYP  = 3; % 'int16';
    HDR.DigMin  = -32768*ones(HDR.NS,1);
    HDR.DigMax  = 32767*ones(HDR.NS,1);
    HDR.PhysMax = HDR.DigMax(:).*HDR.Cal(:);
    HDR.PhysMin = HDR.DigMin(:).*HDR.Cal(:);
    HDR.AS.bpb = HDR.NS * 2;
    if ~isfield(HDR,'THRESHOLD'),
      HDR.THRESHOLD = repmat([-2^15,2^15-1],HDR.NS,1);
    end;
  elseif strncmpi(HDR.BV.BinaryFormat, 'uint_16',7)
    HDR.GDFTYP = 4; % 'uint16';
    HDR.AS.bpb = HDR.NS * 2;
    HDR.DigMin = 0*ones(HDR.NS,1);
    HDR.DigMax = 65535*ones(HDR.NS,1);
    HDR.PhysMax = HDR.DigMax(:).*HDR.Cal(:);
    HDR.PhysMin = HDR.DigMin(:).*HDR.Cal(:);
    if ~isfield(HDR,'THRESHOLD'),
      HDR.THRESHOLD = repmat([0,2^16-1],HDR.NS,1);
    end;
  elseif strncmpi(HDR.BV.BinaryFormat, 'ieee_float_32',13)
    HDR.GDFTYP = 16; % 'float32';
    HDR.AS.bpb = HDR.NS * 4;
  elseif strncmpi(HDR.BV.BinaryFormat, 'ieee_float_64',13)
    HDR.GDFTYP = 17; % 'float64';
    HDR.AS.bpb = HDR.NS * 8;
  end
  if (strcmp(HDR.TYPE,'BrainVisionVAmp'))
    HDR.AS.bpb = HDR.AS.bpb+4;
  end;
  
  % read event file
  tmp = fullfile(HDR.FILE.Path, HDR.BV.MarkerFile);
  if ~exist(tmp,'file')
    tmp = fullfile(HDR.FILE.Path, [HDR.FILE.Name,'.vmrk']);
  end;
  if exist(tmp,'file')
    H = sopen(tmp,'rt');
    if strcmp(H.TYPE,'EVENT');
      HDR.EVENT = H.EVENT;
      HDR.T0    = H.T0;
      
      tmp = which('sopen'); %%% used for BBCI
      if exist(fullfile(fileparts(tmp),'bv2biosig_events.m'),'file');
        try
          HDR = bv2biosig_events(HDR,CHAN,MODE,ReRefMx);
        catch
          warning('bv2biosig_events not executed');
        end;
      end;
    end;
  end;
  
  %open data file
  if strncmpi(HDR.BV.DataFormat, 'binary',5)
    PERMISSION='rb';
  elseif strncmpi(HDR.BV.DataFormat, 'ascii',5)
    PERMISSION='rt';
  end;
  
  HDR.FILE.FID = fopen(fullfile(HDR.FILE.Path,HDR.BV.DataFile),PERMISSION,'ieee-le');
  try % Octave: catch if native2unicode and unicode2native are not supported
    if HDR.FILE.FID < 0,
      DataFile = native2unicode(HDR.BV.DataFile);
      HDR.FILE.FID    = fopen(fullfile(HDR.FILE.Path,DataFile),PERMISSION,'ieee-le');
    end;
    if HDR.FILE.FID < 0,
      DataFile = unicode2native(HDR.BV.DataFile);
      HDR.FILE.FID    = fopen(fullfile(HDR.FILE.Path,DataFile),PERMISSION,'ieee-le');
    end;
  catch
    warning('native2unicode/unicode2native failed');
  end;
  if HDR.FILE.FID < 0,
    fprintf(HDR.FILE.stderr,'ERROR SOPEN BV: could not open file %s\n',fullfile(HDR.FILE.Path,HDR.BV.DataFile));
    HDR.BV.DataFile = [HDR.FILE.Name,'.dat'];
    HDR.FILE.FID    = fopen(fullfile(HDR.FILE.Path,HDR.BV.DataFile),PERMISSION,'ieee-le');
  end;
  if HDR.FILE.FID < 0,
    fprintf(HDR.FILE.stderr,'ERROR SOPEN BV: could not open file %s\n',fullfile(HDR.FILE.Path,HDR.BV.DataFile));
    HDR.BV.DataFile = [HDR.FILE.Name,'.eeg'];
    HDR.FILE.FID    = fopen(fullfile(HDR.FILE.Path,HDR.BV.DataFile),PERMISSION,'ieee-le');
  end;
  if HDR.FILE.FID < 0,
    fprintf(HDR.FILE.stderr,'ERROR SOPEN BV: could not open file %s\n',fullfile(HDR.FILE.Path,HDR.BV.DataFile));
    return;
  end;
  
  HDR.FILE.OPEN= 1;
  HDR.FILE.POS = 0;
  HDR.HeadLen  = 0;
  if strncmpi(HDR.BV.DataFormat, 'binary',5)
    fseek(HDR.FILE.FID,0,'eof');
    HDR.AS.endpos = ftell(HDR.FILE.FID);
    fseek(HDR.FILE.FID,0,'bof');
    HDR.AS.endpos = HDR.AS.endpos/HDR.AS.bpb;
    
  elseif strncmpi(HDR.BV.DataFormat, 'ASCII',5)
    while (HDR.BV.SkipLines>0),
      fgetl(HDR.FILE.FID);
      HDR.BV.SkipLines = HDR.BV.SkipLines-1;
    end;
    s = char(fread(HDR.FILE.FID,inf,'uint8')');
    fclose(HDR.FILE.FID);
    if isfield(HDR.BV,'DecimalSymbol')
      s(s==HDR.BV.DecimalSymbol)='.';
    end;
    [tmp,status] = str2double(s);
    if (HDR.BV.SkipColumns>0),
      tmp = tmp(:,HDR.BV.SkipColumns+1:end);
    end;
    if strncmpi(HDR.BV.DataOrientation, 'multiplexed',6),
      HDR.data = tmp;
    elseif strncmpi(HDR.BV.DataOrientation, 'vectorized',6),
      HDR.data = tmp';
    end
    HDR.TYPE = 'native';
    HDR.AS.endpos = size(HDR.data,1);
    if ~any(HDR.NS ~= size(tmp));
      fprintf(HDR.FILE.stderr,'ERROR SOPEN BV-ascii: number of channels inconsistency\n');
    end;
  end
  HDR.SPR = HDR.AS.endpos;
  
  
  %elseif strncmp(HDR.TYPE,'EEProbe',7),
  %	HDR = openeep(HDR,CHAN,MODE,ReRefMx);