function [HDR, immediateReturn] = EGI(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-be');
  
  HDR.VERSION  = fread(HDR.FILE.FID,1,'uint32');
  
  if ~(HDR.VERSION >= 2 & HDR.VERSION <= 7),
    %   fprintf(HDR.FILE.stderr,'EGI Simple Binary Versions 2-7 supported only.\n');
  end;
  
  HDR.T0 = fread(HDR.FILE.FID,[1,6],'uint16');
  millisecond = fread(HDR.FILE.FID,1,'uint32');
  HDR.T0(6) = HDR.T0(6) + millisecond/1000;
  
  HDR.SampleRate = fread(HDR.FILE.FID,1,'uint16');
  HDR.NS   = fread(HDR.FILE.FID,1,'uint16');
  HDR.gain = fread(HDR.FILE.FID,1,'uint16');
  HDR.Bits = fread(HDR.FILE.FID,1,'uint16');
  HDR.DigMax  = 2^HDR.Bits;
  HDR.PhysMax = fread(HDR.FILE.FID,1,'uint16');
  if ( HDR.Bits ~= 0 && HDR.PhysMax ~= 0 )
    HDR.Cal = repmat(HDR.PhysMax/HDR.DigMax,1,HDR.NS);
  else
    HDR.Cal = ones(1,HDR.NS);
  end;
  HDR.Off = zeros(1,HDR.NS);
  HDR.Calib = sparse(2:HDR.NS+1,1:HDR.NS,HDR.Cal,HDR.NS+1,HDR.NS);
  HDR.PhysDim = 'uV';
  for k=1:HDR.NS,
    HDR.Label{k}=sprintf('# %3i',k);
  end;
  
  HDR.categories = 0;
  HDR.EGI.catname= {};
  
  if any(HDR.VERSION==[2,4,6]),
    HDR.NRec  = fread(HDR.FILE.FID, 1 ,'int32');
    HDR.EGI.N = fread(HDR.FILE.FID,1,'int16');
    HDR.SPR = 1;
    HDR.FLAG.TRIGGERED = logical(0);
    HDR.AS.spb = HDR.NS+HDR.EGI.N;
    HDR.AS.endpos = HDR.SPR*HDR.NRec;
    HDR.Dur = 1/HDR.SampleRate;
  elseif any(HDR.VERSION==[3,5,7]),
    HDR.EGI.categories = fread(HDR.FILE.FID,1,'uint16');
    if (HDR.EGI.categories),
      for i=1:HDR.EGI.categories,
        catname_len(i) = fread(HDR.FILE.FID,1,'uint8');
        HDR.EGI.catname{i} = char(fread(HDR.FILE.FID,catname_len(i),'uint8'))';
      end
    end
    HDR.NRec = fread(HDR.FILE.FID,1,'int16');
    HDR.SPR  = fread(HDR.FILE.FID,1,'int32');
    HDR.EGI.N = fread(HDR.FILE.FID,1,'int16');
    HDR.FLAG.TRIGGERED = logical(1);
    HDR.AS.spb = HDR.SPR*(HDR.NS+HDR.EGI.N);
    HDR.AS.endpos = HDR.NRec*HDR.SPR;
    HDR.Dur = HDR.SPR/HDR.SampleRate;
  else
    fprintf(HDR.FILE.stderr,'Invalid EGI version %i\n',HDR.VERSION);
    return;
  end
  
  % get datatype from version number
  if any(HDR.VERSION==[2,3]),
    HDR.GDFTYP = 3; % 'int16';
  elseif any(HDR.VERSION==[4,5]),
    HDR.GDFTYP = 16; % 'float32';
  elseif any(HDR.VERSION==[6,7]),
    HDR.GDFTYP = 17; % 'float64';
  else
    error('Unknown data format');
  end
  HDR.AS.bpb = HDR.AS.spb*GDFTYP_BYTE(HDR.GDFTYP+1) + 6*HDR.FLAG.TRIGGERED;
  
  tmp = fread(HDR.FILE.FID,[4,HDR.EGI.N],'uint8=>char');
  HDR.EVENT.CodeDesc = cellstr(tmp');
  
  HDR.HeadLen   = ftell(HDR.FILE.FID);
  HDR.FILE.POS  = 0;
  HDR.FILE.OPEN = 1;
  
  % extract event information
  if (HDR.EGI.N>0),
    if HDR.FLAG.TRIGGERED,
      fseek(HDR.FILE.FID,HDR.HeadLen + 6 + HDR.NS*GDFTYP_BYTE(HDR.GDFTYP+1),'bof');
      typ = [int2str(HDR.EGI.N),'*',gdfdatatype(HDR.GDFTYP),'=>',gdfdatatype(HDR.GDFTYP)]
      [s,count] = fread(HDR.FILE.FID,inf, typ, 6+HDR.NS*GDFTYP_BYTE(HDR.GDFTYP+1));
    else
      fseek(HDR.FILE.FID,HDR.HeadLen + HDR.NS*GDFTYP_BYTE(HDR.GDFTYP+1),'bof');
      typ = [int2str(HDR.EGI.N),'*',gdfdatatype(HDR.GDFTYP),'=>',gdfdatatype(HDR.GDFTYP)];
      [s,count] = fread(HDR.FILE.FID,inf, typ, HDR.NS*GDFTYP_BYTE(HDR.GDFTYP+1));
    end;
    
    s = reshape(s, HDR.EGI.N, length(s)/HDR.EGI.N)';
    POS = [];
    CHN = [];
    DUR = [];
    TYP = [];
    for k = 1:HDR.EGI.N,
      ix = find(diff(s(:,k)));
      ix = diff(double([s(:,k);s(1,k)]==s(1,k)));	% labels
      POS = [POS; find(ix>0)+1];
      TYP = [TYP; repmat(k,sum(ix>0),1)];
      CHN = [CHN; repmat(0,sum(ix>0),1)];
      DUR = [DUR; find(ix>0)-find(ix<0)];
    end
    HDR.EVENT.POS = POS;
    HDR.EVENT.TYP = TYP;
    HDR.EVENT.CHN = CHN;
    HDR.EVENT.DUR = DUR;
  end;
  fseek(HDR.FILE.FID,HDR.HeadLen,'bof');