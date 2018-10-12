function [HDR, immediateReturn] = ETG4000(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 HDR.FILE.FID = fopen(HDR.FileName,'rt');
  HDR.s = fread(HDR.FILE.FID,[1,inf],'uint8=>char');
  fclose(HDR.FILE.FID);
  
  [t,s] = strtok(HDR.s,[10,13]);
  HDR.VERSION = -1;
  ix = strfind(HDR.s,'File Version');
  dlm = HDR.s(ix(1) + 12);
  HDR.s(HDR.s==dlm)=9;
  dlm = char(9);
  [t,s] = strtok(HDR.s,[10,13]);
  while ((t(1)<'0') || (t(1)>'9'))
    [NUM, STATUS,STRARRAY] = str2double(t,dlm);
    if 0,
    elseif strncmp(t,'File Version',12)
      HDR.VERSION = NUM(2);
    elseif strncmp(t,'Name',4)
      HDR.Patient.Id  = STRARRAY{2};
    elseif strncmp(t,'Sex',3)
      HDR.Patient.Sex = strncmpi(STRARRAY{2},'M',1)+strncmpi(STRARRAY{2},'F',1)*2;
    elseif strncmp(t,'Age',3)
      if STATUS(2)
        tmp = STRARRAY{2};
        if (lower(tmp(end))=='y')
          tmp = tmp(1:end-1);
        end;
        HDR.Patient.Age = str2double(tmp);
      else
        HDR.Patient.Age = NUM(2);
      end
    elseif strncmp(t,'Date',4),
      tmp = STRARRAY{2};
      tmp((tmp==47) | (tmp==':')) = ' ';
      HDR.T0 = zeros(1,6);
      tmp = str2double(tmp);
      HDR.T0(1:length(tmp)) = tmp;
    elseif strncmp(t,'HPF[Hz]',7)
      HDR.Filter.HighPass = NUM(2);
    elseif strncmp(t,'LPF[Hz]',7)
      HDR.Filter.LowPass = NUM(2);
    elseif strncmp(t,'Analog Gain',11)
      HDR.ETG4000.aGain = NUM(2:end);
    elseif strncmp(t,'Digital Gain',12)
      HDR.ETG4000.dGain = NUM(2:end);
    elseif strncmp(t,'Sampling Period[s]',12)
      HDR.SampleRate = 1./NUM(2);
    elseif strncmp(t,'Probe',5)
      Label = STRARRAY;
      HDR.AS.TIMECHAN = strmatch('Time',Label);
    elseif strncmp(t,'StimType',8)
      FLAG = STRARRAY{2};
    end;
    [t,s] = strtok(s,[10,13]);
  end
  if ~any(HDR.VERSION==[1.06,1.09])
    fprintf(HDR.FILE.stdout,'SOPEN (ETG4000): Version %f has not been tested.\n',HDR.VERSION);
  end;
  fprintf(1,'Please wait - conversion takes some time');
  
  nc = length(Label);
  chansel = [2:nc-5,nc-3]; 	% with time channel
  chansel = [2:nc-5]; 	% without time channel
  HDR.Label = Label(chansel);
  F = ['%d',dlm];
  for k=1:length(Label)-6,
    F = [F,'%f',dlm];
  end;
  F = [F,'%d',dlm];
  F = [F,'%d:%d:%d.%d',dlm];
  F = [F,'%d',dlm];
  F = [F,'%d',dlm];
  F = [F,'%d'];
  
  [num,count] = sscanf([t,s],F,[length(Label)+3,inf]);
  NUM = num';
  T = NUM(:,end+[-6:-3])*[3600;60;1;.01];
  NUM(:,end-6) = T;
  NUM(:,end-5:end-3) = [];
  
  fprintf(1,' - FINISHED\n');
  ix = ~isnan(NUM(:,1));
  %                HDR.data = [NUM(ix,2:end-8),T];
  HDR.data = [NUM(ix,chansel)];
  
  HDR.TYPE = 'native';
  [HDR.SPR, HDR.NS] = size(HDR.data);
  HDR.NRec = 1;
  HDR.FILE.POS = 0;
  
  %HDR.Cal = aGain.*dGain;
  HDR.PhysMax = max(HDR.data,[],1);
  HDR.PhysMin = min(HDR.data,[],1);
  HDR.DigMax  = HDR.PhysMax;
  HDR.DigMin  = HDR.PhysMin;
  HDR.Calib   = sparse(2:HDR.NS+1,1:HDR.NS,1);
  HDR.Cal     = ones(1,HDR.NS);
  HDR.Off     = zeros(1,HDR.NS);
  
  HDR.GDFTYP  = 16*ones(1,HDR.NS);
  HDR.LeadIdCode = repmat(NaN,1,HDR.NS);
  HDR.FLAG.OVERFLOWDETECTION = 0;
  
  %HDR.PhysDimCode = zeros(HDR.NS,1);
  PhysDimCode = [512,repmat(65362,1,HDR.NS),512,2176,repmat(512,1,3)];
  HDR.PhysDimCode = PhysDimCode(chansel);
  %HDR.PhysDim = physicalunits(HDR.PhysDimCode);
  
  % EVENTS
  evchan = strmatch('Mark',Label);
  HDR.EVENT.POS = find(NUM(:,evchan));
  HDR.EVENT.TYP = NUM(HDR.EVENT.POS,evchan);
  if strcmp(FLAG,'STIM')
    if (rem(length(HDR.EVENT.TYP),2)),
      HDR.EVENT.TYP(end+1) = HDR.EVENT.TYP(end);
      HDR.EVENT.POS(end+1) = size(HDR.data,1);
    end;
    HDR.EVENT.TYP(2:2:end) = HDR.EVENT.TYP(2:2:end)+hex2dec('8000');
  end;
  