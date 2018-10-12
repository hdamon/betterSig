function [HDR, immediateReturn] = BCI2000(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 if any(HDR.FILE.PERMISSION=='r'),
    HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
    
    [HDR.Header,count] = fread(HDR.FILE.FID,[1,256],'uint8');
    [tmp,rr] = strtok(char(HDR.Header),[10,13]);
    tmp(tmp=='=') = ' ';
    [t,status,sa] = str2double(tmp,[9,32],[10,13]);
    if (HDR.VERSION==1) && strcmp(sa{3},'SourceCh') && strcmp(sa{5},'StatevectorLen') && ~any(status([2,4,6]))
      HDR.HeadLen = t(2);
      HDR.NS = t(4);
      HDR.BCI2000.StateVectorLength = t(6);
      HDR.GDFTYP  = 3; % 'int16';
      
    elseif (HDR.VERSION==1.1) && strcmp(sa{5},'SourceCh') && strcmp(sa{7},'StatevectorLen') && strcmp(sa{9},'DataFormat') && ~any(status([2:2:8]))
      HDR.VERSION = t(2);
      HDR.HeadLen = t(4);
      HDR.NS = t(6);
      HDR.BCI2000.StateVectorLength = t(8);
      if strcmp(sa{10},'int16')
        HDR.GDFTYP = 3;
      elseif strcmp(sa{10},'int32')
        HDR.GDFTYP = 5;
      elseif strcmp(sa{10},'float32')
        HDR.GDFTYP = 16;
      elseif strcmp(sa{10},'float64')
        HDR.GDFTYP = 17;
      elseif strcmp(sa{10},'int24')
        HDR.GDFTYP = 255+24;
      elseif strcmp(sa{10},'uint16')
        HDR.GDFTYP = 4;
      elseif strcmp(sa{10},'uint32')
        HDR.GDFTYP = 6;
      elseif strcmp(sa{10},'uint24')
        HDR.GDFTYP = 511+24;
      end;
    else
      HDR.TYPE = 'unknown';
      fprintf(HDR.FILE.stderr,'Error SOPEN: file %s does not confirm with BCI2000 format\n',HDR.FileName);
      fclose(HDR.FILE.FID);
      return;
    end;
    if count<HDR.HeadLen,
      status = fseek(HDR.FILE.FID,0,'bof');
      [BCI2000.INFO,count] = fread(HDR.FILE.FID,[1,HDR.HeadLen],'uint8=>char');
    elseif count>HDR.HeadLen,
      status = fseek(HDR.FILE.FID,HDR.HeadLen,'bof');
      BCI2000.INFO = char(HDR.Header(1:HDR.HeadLen));
    end
    ORIENT = 0;
    [tline,rr] = strtok(BCI2000.INFO,[10,13]);
    HDR.Label  = cellstr([repmat('ch',HDR.NS,1),num2str([1:HDR.NS]')]);
    STATUSFLAG = 0;
    while length(rr),
      tline = tline(1:min([length(tline),strfind(tline,char([47,47]))-1]));
      
      if ~isempty(strfind(tline,'[ State Vector Definition ]'))
        STATUSFLAG = 1;
        STATECOUNT = 0;
        
      elseif ~isempty(strfind(tline,'[ Parameter Definition ]'))
        STATUSFLAG = 2;
        
      elseif strncmp(tline,'[',1)
        STATUSFLAG = 3;
        
      elseif STATUSFLAG==1,
        [t,r] = strtok(tline);
        val = str2double(r);
        %HDR.BCI2000 = setfield(HDR.BCI2000,t,val);
        STATECOUNT = STATECOUNT + 1;
        HDR.BCI2000.StateVector(STATECOUNT,:) = val;
        HDR.BCI2000.StateDef{STATECOUNT,1} = t;
        
      elseif STATUSFLAG==2,
        [tag,r] = strtok(tline,'=');
        [val,r] = strtok(r,'=');
        if ~isempty(strfind(tag,'SamplingRate'))
          [tmp,status] = str2double(val);
          HDR.SampleRate = tmp(1);
        elseif ~isempty(strfind(tag,'SourceChGain'))
          [tmp,status] = str2double(val);
          HDR.Cal = tmp(2:tmp(1)+1);
        elseif ~isempty(strfind(tag,'SourceChOffset'))
          [tmp,status] = str2double(val);
          HDR.Off = tmp(2:tmp(1)+1);
        elseif ~isempty(strfind(tag,'SourceMin'))
          [tmp,status] = str2double(val);
          HDR.DigMin = tmp(1);
        elseif ~isempty(strfind(tag,'SourceMax'))
          [tmp,status] = str2double(val);
          HDR.DigMax = tmp(1);
        elseif ~isempty(strfind(tag,'NotchFilter'))
          [tmp,status] = str2double(val);
          if tmp(1)==0, HDR.Filter.Notch = 0;
          elseif tmp(1)==1, HDR.Filter.Notch = 50;
          elseif tmp(1)==2, HDR.Filter.Notch = 60;
          end;
        elseif ~isempty(strfind(tag,'TargetOrientation'))
          [tmp,status] = str2double(val);
          ORIENT = tmp(1);
        elseif ~isempty(strfind(tag,'StorageTime'))
          ix = strfind(val,'%20');
          if length(ix)==4,
            val([ix,ix+1,ix+2])=' ';
            val(val==':') = ' ';
            [n,v,s] = str2double(val);
            n(1)=n(7);
            n(2)=strmatch(s{2},{'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'});
            HDR.T0 = n(1:6);
          end;
        elseif ~isempty(strfind(tag,'ChannelNames'))
          [tmp,status,labels] = str2double(val);
          HDR.Label(1:tmp(1))=labels(2:tmp(1)+1);
        end;
      end;
      [tline,rr] = strtok(rr,[10,13]);
    end;
    
    %HDR.PhysDim = '�V';
    HDR.PhysDimCode = repmat(4275,HDR.NS,1); % '�V';
    HDR.Calib = [HDR.Off(1)*ones(1,HDR.NS);eye(HDR.NS)]*HDR.Cal(1);
    
    % decode State Vector Definition
    X = repmat(NaN,1,HDR.BCI2000.StateVectorLength*8);
    for k = 1:STATECOUNT,
      for k1 = 1:HDR.BCI2000.StateVector(k,1),
        X(HDR.BCI2000.StateVector(k,3:4)*[8;1]+k1) = k;
      end;
    end;
    X = X(end:-1:1);
    HDR.BCI2000.X = X;
    
    % convert EVENT information
    status = fseek(HDR.FILE.FID,HDR.HeadLen+2*HDR.NS,'bof');
    tmp = fread(HDR.FILE.FID,[HDR.BCI2000.StateVectorLength,inf],[int2str(HDR.BCI2000.StateVectorLength),'*uchar'],HDR.NS*2)';
    NoS = size(tmp);
    POS = [1;1+find(any(diff(tmp,[],1),2))];
    tmp = tmp(POS,end:-1:1)';         % compress event information
    tmp = dec2bin(tmp(:),8)';
    HDR.BCI2000.BINARYSTATUS = reshape(tmp, 8*HDR.BCI2000.StateVectorLength, size(tmp,2)/HDR.BCI2000.StateVectorLength)';
    for  k = 1:max(X)
      HDR.BCI2000.STATE(:,k) = bin2dec(HDR.BCI2000.BINARYSTATUS(:,k==X));
    end;
    
    HDR.EVENT.POS = POS;
    HDR.EVENT.TYP = repmat(0,size(HDR.EVENT.POS)); 	% should be extracted from HDR.BCI2000.STATE
    fprintf(2,'Warning SOPEN (BCI2000): HDR.EVENT.TYP information need to be extracted from HDR.BCI2000.STATE\n');
    HDR.EVENT.CHN = zeros(size(HDR.EVENT.POS));
    HDR.EVENT.DUR = zeros(size(HDR.EVENT.POS));
    HDR.EVENT.SampleRate = HDR.SampleRate;
    
    k   		= strmatch('TargetCode', HDR.BCI2000.StateDef);
    ix  		= find(diff(HDR.BCI2000.STATE(:,k))>0)+1;	%% start of trial ??
    HDR.TRIG 	= POS(ix);
    HDR.Classlabel  = HDR.BCI2000.STATE(ix,k);
    
    if ORIENT == 1, %% vertical
      cl = hex2dec('030c')*(HDR.Classlabel==1) + hex2dec('0306')*(HDR.Classlabel==2) + hex2dec('0303')*(HDR.Classlabel==3);
      HDR.EVENT.TYP(ix)  = cl;
    else	%% horizontal or both
      HDR.EVENT.TYP(ix)  = HDR.Classlabel + hex2dec('0300');
    end;
    ix2  = find(diff(HDR.BCI2000.STATE(:,k))<0)+1;	%% end of trial ??
    ix   = ix(1:length(ix2));
    HDR.EVENT.DUR(ix) = POS(ix2) - POS(ix);
    
    % remove all empty events
    ix = find(HDR.EVENT.TYP>0);
    HDR.EVENT.POS=HDR.EVENT.POS(ix);
    HDR.EVENT.TYP=HDR.EVENT.TYP(ix);
    HDR.EVENT.DUR=HDR.EVENT.DUR(ix);
    HDR.EVENT.CHN=HDR.EVENT.CHN(ix);
    HDR.EVENT.N = length(ix);
    
    k= strmatch('Feedback', HDR.BCI2000.StateDef);
    ix  = find(diff(HDR.BCI2000.STATE(:,k))>0)+1;	%% start of feedback
    ix2 = find(diff(HDR.BCI2000.STATE(:,k))<0)+1;	%% end of feedback
    HDR.EVENT.POS = [HDR.EVENT.POS;POS(ix)];
    HDR.EVENT.TYP = [HDR.EVENT.TYP;repmat(hex2dec('030d'),length(ix),1)];
    HDR.EVENT.CHN = zeros(length(HDR.EVENT.POS),1);
    if length(ix2)==length(ix),
      HDR.EVENT.DUR = [HDR.EVENT.DUR;POS(ix2)-POS(ix)];
    else
      tmp = [POS(ix2);NoS(1)+1];
      HDR.EVENT.DUR = [HDR.EVENT.DUR;tmp-POS(ix)];
    end;
    HDR.EVENT.N   = length(HDR.EVENT.POS);
    
    % finalize header definition
    status = fseek(HDR.FILE.FID,HDR.HeadLen,'bof');
    HDR.AS.bpb    = 2*HDR.NS + HDR.BCI2000.StateVectorLength;
    HDR.SPR       = (HDR.FILE.size - HDR.HeadLen)/HDR.AS.bpb;
    HDR.AS.endpos = HDR.SPR;
    
    [datatyp,limits,datatypes,numbits,GDFTYP] = gdfdatatype(HDR.GDFTYP);
    HDR.BCI2000.GDFTYP = [int2str(HDR.NS),'*',datatypes{1},'=>',datatypes{1}];
    HDR.NRec      = 1;
    
    HDR.FILE.OPEN = 1;
    HDR.FILE.POS  = 0;
  end;