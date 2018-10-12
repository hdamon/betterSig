function [HDR, immediateReturn] = alpha(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


HDR.FILE.FID = -1;      % make sure SLOAD does not call SREAD;
  
  %%%
  
  % The header files are text files (not binary).
  try
    PERMISSION = 'rt';	% MatLAB default is binary, force Mode='rt';
    fid = fopen(fullfile(HDR.FILE.Path,'head'),PERMISSION);
  catch
    PERMISSION = 'r';	% Octave 2.1.50 default is text, but does not support Mode='rt',
    fid = fopen(fullfile(HDR.FILE.Path,'head'),PERMISSION);
  end;
  
  cfiles = {'alpha.alp','eog','mkdef','r_info','rawhead','imp_res','sleep','../s_info'};
  %%,'marker','digin','montage','measure','cal_res'
  
  HDR.alpha = [];
  for k = 1:length(cfiles),
    [cf,tmp]=strtok(cfiles{k},'./');
    fid = fopen(fullfile(HDR.FILE.Path,cfiles{k}),PERMISSION);
    if fid>0,
      S = {};
      state = 0;
      flag.rawhead = strcmp(cf,'rawhead');
      flag.sleep = strcmp(cf,'sleep');
      [s] = fgetl(fid);
      while ischar(s), %~feof(fid),
        [tag,s] = strtok(s,'= ');
        s(find(s=='='))=' ';
        [VAL,s1] = strtok(s,' ');
        [val,status] = str2double(VAL);
        if (state==0),
          try;
            if any(status),
              S=setfield(S,tag,VAL);
            else
              S=setfield(S,tag,val);
            end;
          end;
          
          if (flag.rawhead && strncmp(tag,'DispFlags',9) && (S.Version < 411.89))
            state = 1;
            k1 = 0;
          elseif (flag.rawhead && strncmp(tag,'Sec2Marker',9) && (S.Version > 411.89))
            state = 1;
            k1 = 0;
          elseif (flag.sleep && strncmp(tag,'SleepType',9))
            state = 3;
            k1 = 0;
          end;
        elseif (state==1)	% rawhead: channel info
          k1 = k1+1;
          HDR.Label{k1} = [tag,' '];
          [num,status,sa] = str2double(s);
          XY(k1,1:2) = num(4:5);
          CHANTYPE{k1}  = sa{3};
          HDR.alpha.chanidx(k1)   = num(2);
          if (k1==S.ChanCount);
            [tmp,HDR.alpha.chanorder]  = sort(HDR.alpha.chanidx);
            HDR.Label = HDR.Label(HDR.alpha.chanorder);
            XY = XY(HDR.alpha.chanorder,:);
            tmp = sum(XY.^2,2);
            HDR.ELEC.XYZ = [XY,sqrt(max(tmp)-tmp)];
            CHANTYPE  = CHANTYPE(HDR.alpha.chanorder);
            state = 2;
            k1 = 0;
            HDR.alpha.chantyp.num = [];
          end;
        elseif (state==2)	% rawhead: info on channel type
          k1 = k1+1;
          [num,status,sa] = str2double(s,',');
          chantyp.s{k1}   = s;
          chantyp.tag{k1} = tag;
        elseif (state==3)	% sleep: scoreing
          k1 = k1+1;
          scoring(k1) = val;
        end
        [s] = fgetl(fid);
      end;
      fclose(fid);
      HDR.alpha=setfield(HDR.alpha,cf,S);
    end;
  end;
  HDR.VERSION = HDR.alpha.rawhead.Version;
  if isfield(HDR.alpha,'rawhead')
    HDR.Bits = HDR.alpha.rawhead.BitsPerValue;
    HDR.NS   = HDR.alpha.rawhead.ChanCount;
    HDR.SampleRate = HDR.alpha.rawhead.SampleFreq;
    HDR.SPR  = HDR.alpha.rawhead.SampleCount;
    HDR.Filter.Notch = HDR.alpha.rawhead.NotchFreq;
    if     HDR.Bits == 12; HDR.GDFTYP = HDR.Bits+255;
    elseif HDR.Bits == 16; HDR.GDFTYP = 3;
    elseif HDR.Bits == 32; HDR.GDFTYP = 5;
    else   fprintf(HDR.FILE.stderr,'Error SOPEN(alpha): invalid header information.\n'); return;
    end;
    [datatyp, limits, datatypes] = gdfdatatype(HDR.GDFTYP);
    % THRESHOLD for Overflow detection
    if ~isfield(HDR,'THRESHOLD')
      HDR.THRESHOLD = repmat(limits, HDR.NS, 1);
    end;
    HDR.NRec = 1;
    
    % channel-specific settings
    ix = zeros(1,HDR.NS);
    for k = 1:HDR.NS,
      ix(k) = strmatch(CHANTYPE{k},chantyp.tag,'exact');
    end;
    
    chantyp.s = chantyp.s(ix);
    for k = 1:HDR.NS,
      HDR.Filter.HighPass(k) = num(1);
      HDR.Filter.LowPass(k) = num(2);
      [num,status,sa] = str2double(chantyp.s{k},',');
      if strcmp(sa{5},'%%');
        sa{5}='%';
      end;
      HDR.PhysDim{k}=[deblank(sa{5}),' '];
    end;
    HDR.PhysDim = char(HDR.PhysDim);
  else
    fprintf(HDR.FILE.stderr,'Error SOPEN (alpha): couldnot open RAWHEAD\n');
  end;
  if isfield(HDR.alpha,'sleep')
    HDR.alpha.sleep.scoring = scoring;
  end;
  if isfield(HDR.alpha,'r_info')
    HDR.REC.Recording = HDR.alpha.r_info.RecId;
    HDR.REC.Hospital = HDR.alpha.r_info.Laboratory;
    tmp = [HDR.alpha.r_info.RecDate,' ',HDR.alpha.r_info.RecTime];
    tmp(tmp=='.') = ' ';
    [tmp,status]=str2double(tmp);
    if ~any(status)
      HDR.T0 = tmp([3,2,1,4:6]);
    end;
  end;
  if isfield(HDR.alpha,'s_info')
    %       HDR.Patient.Name = [HDR.alpha.s_info.LastName,', ',HDR.alpha.s_info.FirstName];
    HDR.Patient.Sex  = HDR.alpha.s_info.Gender;
    HDR.Patient.Handedness  = HDR.alpha.s_info.Handedness;
    tmp = HDR.alpha.s_info.BirthDay;
    tmp(tmp=='.')=' ';
    t0 = str2double(tmp);
    age = [HDR.T0(1:3)-t0([3,2,1])]*[365.25;30;1]; % days
    if (age<100)
      HDR.Patient.Age = sprintf('%i day',age);
    elseif (age<1000)
      HDR.Patient.Age = sprintf('%4.1f month',age/30);
    else
      HDR.Patient.Age = sprintf('%4.1f year(s)',age/365.25);
    end;
  end;
  
  fid = fopen(fullfile(HDR.FILE.Path,'cal_res'),PERMISSION);
  if fid < 0,
    fprintf(HDR.FILE.stderr,'Warning SOPEN alpha-trace: could not open CAL_RES. Data is uncalibrated.\n');
    HDR.FLAG.UCAL = 1;
  else
    k = 0;
    while (k<2)		%% skip first 2 lines
      [s] = fgetl(fid);
      if ~strncmp(s,'#',1), %% comment lines do not count
        k=k+1;
      end;
    end;
    [s] = fread(fid,[1,inf],'uint8');
    fclose(fid);
    
    HDR.Cal = ones(HDR.NS,1);
    HDR.Off = ones(HDR.NS,1);
    s(s=='=') = ',';
    [val,status,strarray]=str2double(s);
    if 0, %try,
      HDR.Cal = val(HDR.alpha.chanorder,3);
      HDR.Off = val(HDR.alpha.chanorder,4);
    else %catch
      %%%% FIXME:
      for k = 1:size(val,1),
        if val(k,1)>0,
          ch = val(k,1);
        else
          ch = k; %strmatch(strarray{k,1},HDR.Label);
        end;
        HDR.Cal(ch,1) = val(k, 3);
        HDR.Off(ch,1) = val(k, 4);
      end;
    end;
    %                HDR.Label2 = char(strarray(HDR.alpha.chanorder,1));
    OK = strmatch('no',strarray(:,2));
    
    HDR.FLAG.UCAL = ~isempty(OK);
    if ~isempty(OK),
      fprintf(HDR.FILE.stderr,'Warning SOPEN (alpha): calibration not valid for some channels\n');
    end;
    %                HDR.Cal(OK) = NaN;
    HDR.Calib = sparse([-HDR.Off';eye(HDR.NS*[1,1])])*sparse(1:HDR.NS,1:HDR.NS,HDR.Cal);
  end;
  
  fid = fopen(fullfile(HDR.FILE.Path,'marker'),PERMISSION);
  if fid > 0,
    k = 0;
    while (k<1)		%% skip first 2 lines
      [s] = fgetl(fid);
      if ~strncmp(s,'#',1), %% comment lins do not count
        k=k+1;
      end;
    end;
    [s] = fread(fid,[1,inf],'uint8');
    fclose(fid);
    
    s(s=='=') = ',';
    [val,status,strarray]=str2double(s,', ');
    HDR.EVENT.POS = val(:,3);
    [HDR.EVENT.CodeDesc,tmp,HDR.EVENT.TYP] = unique(strarray(:,1));
    ix = strmatch('off',strarray(:,2));
    HDR.EVENT.TYP(ix) = HDR.EVENT.TYP(ix)+hex2dec('8000');
  end;
  
  fid = fopen(fullfile(HDR.FILE.Path,'montage'),PERMISSION);
  if fid > 0,
    K = 0;
    while ~feof(fid),
      s = fgetl(fid);
      [tag,s]   = strtok(s,' =');
      [val1,r]  = strtok(s,' =,');
      if strncmp(tag,'Version',7),
      elseif strncmp(tag,'Montage',7),
        K = K+1;
        Montage{K,1} = s(4:end);
        k = 0;
      elseif strncmp(tag,'Trace',5),
        k = k+1;
        trace{k,K} = s(4:end);
        [num,status,str] = str2double(s(4:end),[32,34,44]);
        if strcmpi(str{3},'xxx')
          Label{k,K} = str{2};
        else
          Label{k,K} = [str{2},'-',str{3}];
        end;
      elseif strncmp(tag,'RefType',7),
      end;
    end;
    fclose(fid);
    HDR.alpha.montage.Montage = Montage;
    HDR.alpha.montage.Label   = Label;
    HDR.alpha.montage.trace   = trace;
  end;
  
  fid = fopen(fullfile(HDR.FILE.Path,'digin'),PERMISSION);
  if 1,
  elseif fid < 0,
    fprintf(HDR.FILE.stderr,'Warning SOPEN alpha-trace: couldnot open DIGIN - no event information included\n');
  else
    [s] = fgetl(fid);       % read version
    
    k = 0; POS = []; DUR = []; TYP = []; IO = [];
    while ~feof(fid),
      [s] = fgetl(fid);
      if ~isnumeric(s),
        [timestamp,s] = strtok(s,'=');
        [type,io] = strtok(s,'=,');
        timestamp = str2double(timestamp);
        if ~isnan(timestamp),
          k = k + 1;
          POS(k) = timestamp;
          TYP(k) = hex2dec(type);
          DUR(k) = 0;
          if (k>1) && (TYP(k)==0),
            DUR(k-1) = POS(k)-POS(k-1);
          end;
        else
          fprintf(HDR.FILE.stderr,'Warning SOPEN: alpha: invalid Event type\n');
        end;
        if length(io)>1,
          IO(k) = io(2);
        end;
      end;
    end;
    fclose(fid);
    HDR.EVENT.N   = k;
    HDR.EVENT.POS = POS(:);
    HDR.EVENT.DUR = DUR(:);
    HDR.EVENT.TYP = TYP(:);
    HDR.EVENT.IO  = IO(:);
    HDR.EVENT.CHN = zeros(HDR.EVENT.N,1);
  end;
  if all(abs(HDR.alpha.rawhead.Version - [407.1, 407.11, 409.5, 413.2]) > 1e-6);
    fprintf(HDR.FILE.stderr,'Warning SLOAD: Format ALPHA Version %6.2f not tested yet.\n',HDR.VERSION);
  end;
  
  HDR.FILE.FID = fopen(fullfile(HDR.FILE.Path,'rawdata'),'rb');
  if HDR.FILE.FID > 0,
    HDR.VERSION2  = fread(HDR.FILE.FID,1,'int16');
    HDR.NS   = fread(HDR.FILE.FID,1,'int16');
    HDR.Bits = fread(HDR.FILE.FID,1,'int16');
    HDR.AS.bpb = HDR.NS*HDR.Bits/8;
    HDR.SPR = 1;
    if rem(HDR.AS.bpb,1),
      HDR.AS.bpb = HDR.AS.bpb*2; %HDR.NS*HDR.Bits/8;
      HDR.SPR = 2;
    end;
    HDR.FILE.OPEN = 1;
    HDR.FILE.POS  = 0;
    HDR.HeadLen = ftell(HDR.FILE.FID);
    fseek(HDR.FILE.FID,0,'eof');
    HDR.NRec = (ftell(HDR.FILE.FID)-HDR.HeadLen)/HDR.AS.bpb;
    HDR.AS.endpos = HDR.NRec;
    fseek(HDR.FILE.FID,HDR.HeadLen,'bof');
  end;
  