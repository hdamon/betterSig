function [HDR, immediateReturn] = CFWB(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


  CHANNEL_TITLE_LEN = 32;
  UNITS_LEN = 32;
  if any(HDR.FILE.PERMISSION=='r'),
    HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
    
    HDR.FILE.OPEN = 1;
    fseek(HDR.FILE.FID,4,'bof');
    HDR.VERSION = fread(HDR.FILE.FID,1,'int32');
    HDR.Dur = fread(HDR.FILE.FID,1,'double');
    HDR.SampleRate = 1/HDR.Dur;
    HDR.T0 = fread(HDR.FILE.FID,[1,5],'int32');
    tmp = fread(HDR.FILE.FID,2,'double');
    HDR.T0(6) = tmp(1);
    HDR.CFWB.preTrigger = tmp(2);
    HDR.NS = fread(HDR.FILE.FID,1,'int32');
    HDR.NRec = fread(HDR.FILE.FID,1,'int32');
    HDR.SPR = 1;
    HDR.FLAG.TRIGGERED = 0;
    HDR.AS.endpos = HDR.NRec*HDR.SPR;
    
    HDR.FLAG.TimeChannel = fread(HDR.FILE.FID,1,'int32');
    tmp = fread(HDR.FILE.FID,1,'int32');
    if tmp == 1,
      HDR.GDFTYP = 17; %'float64';
      HDR.AS.bpb = HDR.NS * 8;
    elseif tmp == 2,
      HDR.GDFTYP = '16'; %'float32';
      HDR.AS.bpb = HDR.NS * 4;
    elseif tmp == 3,
      HDR.GDFTYP = 3; %'int16';
      HDR.AS.bpb = HDR.NS * 2;
    end;
    for k = 1:HDR.NS,
      HDR.Label{k,1} = char(fread(HDR.FILE.FID,[1, CHANNEL_TITLE_LEN],'uint8'));
      HDR.PhysDim{k,1} = char(fread(HDR.FILE.FID,[1, UNITS_LEN],'uint8'));
      HDR.Cal(k,1) = fread(HDR.FILE.FID,1,'double');
      HDR.Off(k,1) = fread(HDR.FILE.FID,1,'double');
      HDR.PhysMax(1,k) = fread(HDR.FILE.FID,1,'double');
      HDR.PhysMin(1,k) = fread(HDR.FILE.FID,1,'double');
    end;
    
    
  elseif any(HDR.FILE.PERMISSION=='w'),
    HDR.VERSION   = 1;
    if ~isfield(HDR,'NS'),
      HDR.NS = 0; 	% unknown channel number ...
      fprintf(HDR.FILE.stderr,'Error SOPEN-W CFWB: number of channels HDR.NS undefined.\n');
      return;
    end;
    if ~isfield(HDR,'NRec'),
      HDR.NRec = -1; 	% Unknown - Value will be fixed when file is closed.
    end;
    HDR.SPR = 1;
    if ~isfield(HDR,'SampleRate'),
      HDR.SampleRate = 1; 	% Unknown - Value will be fixed when file is closed.
      if isfield(HDR,'Dur')
        HDR.SampleRate = 1/HDR.Dur;
      else
        fprintf(HDR.FILE.stderr,'Warning SOPEN-W CFWB: samplerate undefined.\n');
      end;
    else
      HDR.Dur = 1/HDR.SampleRate;
    end;
    
    if (any(HDR.NRec<0) && any(HDR.FILE.PERMISSION=='z')),
      %% due to a limitation zlib
      fprintf(HDR.FILE.stderr,'ERROR SOPEN (CFWB) "wz": Update of HDR.SPR not possible.\n',HDR.FileName);
      fprintf(HDR.FILE.stderr,'\t Solution(s): (1) define exactly HDR.SPR before calling SOPEN(HDR,"wz"); or (2) write to uncompressed file instead.\n');
      return;
    end;
    if any([HDR.NRec<=0]), 	% if any unknown, ...
      HDR.FILE.OPEN = 3;			%	... fix header when file is closed.
    end;
    if ~isfield(HDR,'CFWB'),
      HDR.CFWB.preTrigger = 0; 	% Unknown - Value will be fixed when file is closed.
    end;
    if ~isfield(HDR.CFWB,'preTrigger'),
      HDR.CFWB.preTrigger = 0; 	% Unknown - Value will be fixed when file is closed.
    end;
    if ~isfield(HDR,'FLAG'),
      HDR.FLAG.TimeChannel = 0;
    else
      if ~isfield(HDR.FLAG,'TimeChannel'),
        HDR.Flag.TimeChannel = 0;
      end;
    end;
    if strcmp(gdfdatatype(HDR.GDFTYP),'float64');
      tmp = 1;
      HDR.AS.bpb = HDR.NS * 8;
      HDR.Cal = ones(HDR.NS,1);
      HDR.Off = zeros(HDR.NS,1);
    elseif strcmp(gdfdatatype(HDR.GDFTYP),'float32');
      tmp = 2;
      HDR.AS.bpb = HDR.NS * 4;
      HDR.Cal = ones(HDR.NS,1);
      HDR.Off = zeros(HDR.NS,1);
    elseif strcmp(gdfdatatype(HDR.GDFTYP),'int16');
      tmp = 3;
      HDR.AS.bpb = HDR.NS * 2;
    end;
    HDR.PhysMax = repmat(NaN,HDR.NS,1);
    HDR.PhysMin = repmat(NaN,HDR.NS,1);
    if ~isfield(HDR,'Cal'),
      fprintf(HDR.FILE.stderr,'Warning SOPEN-W CFWB: undefined scaling factor - assume HDR.Cal=1.\n');
      HDR.Cal = ones(HDR.NS,1);
    end;
    if ~isfield(HDR,'Off'),
      fprintf(HDR.FILE.stderr,'Warning SOPEN-W CFWB: undefined offset - assume HDR.Off=0.\n');
      HDR.Off = zeros(HDR.NS,1);
    end;
    if ~isfield(HDR,'Label'),
      for k = 1:HDR.NS,
        Label{k} = sprintf('channel %i',k);
      end;
    end;
    Label = char(HDR.Label);  % local copy of Label
    Label = [Label, char(repmat(32,size(Label,1),max(0,CHANNEL_TITLE_LEN-size(Label,2))))];
    Label = [Label; char(repmat(32,max(0,HDR.NS-size(Label,1)),size(Label,2)))];
    
    if ~isfield(HDR,'PhysDim'),
      HDR.PhysDim = repmat({''},HDR.NS,1);
    end;
    
    if size(HDR.PhysDim,1)==1,
      HDR.PhysDim = HDR.PhysDim(ones(HDR.NS,1),:);
    end;
    if iscell(HDR.PhysDim)
      for k = 1:length(HDR.PhysDim),
        HDR.PhysDim{k} = [HDR.PhysDim{k},' '];
      end;
    end
    PhysDim = char(HDR.PhysDim);     %local copy
    PhysDim = [PhysDim, char(repmat(32,size(PhysDim,1),max(0,UNITS_LEN-size(PhysDim,2))))];
    PhysDim = [PhysDim; char(repmat(32,max(0,HDR.NS-size(PhysDim,1)),size(PhysDim,2)))];
    
    %%%%% write fixed header
    HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
    if HDR.FILE.FID<0,
      fprintf(HDR.FILE.stderr,'Error SOPEN-W CFWB: could not open file %s .\n',HDR.FileName);
      return;
    else
      HDR.FILE.OPEN = 2;
    end;
    fwrite(HDR.FILE.FID,'CFWB','uint8');
    fwrite(HDR.FILE.FID,HDR.VERSION,'int32');
    fwrite(HDR.FILE.FID,HDR.Dur,'double');
    fwrite(HDR.FILE.FID,HDR.T0(1:5),'int32');
    fwrite(HDR.FILE.FID,HDR.T0(6),'double');
    fwrite(HDR.FILE.FID,HDR.CFWB.preTrigger,'double');
    fwrite(HDR.FILE.FID,[HDR.NS,HDR.NRec,HDR.Flag.TimeChannel],'int32');
    fwrite(HDR.FILE.FID,tmp,'int32');
    HDR.HeadLen = ftell(HDR.FILE.FID);
    if (HDR.HeadLen~=68),
      fprintf(HDR.FILE.stderr,'Error SOPEN CFWB: size of header1 does not fit in file %s\n',HDR.FileName);
    end;
    
    %%%%% write channel header
    for k = 1:HDR.NS,
      fwrite(HDR.FILE.FID,Label(k,1:32),'uint8');
      fwrite(HDR.FILE.FID,PhysDim(k,1:32),'uint8');
      fwrite(HDR.FILE.FID,[HDR.Cal(k),HDR.Off(k)],'double');
      fwrite(HDR.FILE.FID,[HDR.PhysMax(k),HDR.PhysMin(k)],'double');
    end;
    %HDR.HeadLen = (68+HDR.NS*96); %
    HDR.HeadLen = ftell(HDR.FILE.FID);
    if (HDR.HeadLen~=(68+HDR.NS*96))
      fprintf(HDR.FILE.stderr,'Error SOPEN CFWB: size of header2 does not fit in file %s\n',HDR.FileName);
    end;
  end;
  HDR.Calib = [HDR.Off';speye(HDR.NS)]*sparse(1:HDR.NS,1:HDR.NS,HDR.Cal);
  
  HDR.HeadLen = ftell(HDR.FILE.FID);
  HDR.FILE.POS = 0;
  HDR.AS.endpos = HDR.NRec*HDR.SPR;
  