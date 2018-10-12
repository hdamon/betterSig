function [HDR, immediateReturn] = SIGIF(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


  if any(PERMISSION=='r'),
    HDR.FILE.FID  = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
    HDR.FILE.OPEN = 1;
    HDR.FILE.POS  = 0;
    
    HDR.fingerprint=fgetl(HDR.FILE.FID);   % 1
    
    if length(HDR.fingerprint)>6
      HDR.VERSION = int2str(HDR.fingerprint(7));
    else
      HDR.VERSION = 1.1;
    end;
    HDR.Comment=fgetl(HDR.FILE.FID);		% 2
    HDR.SignalName=fgetl(HDR.FILE.FID);	% 3
    HDR.Date=fgetl(HDR.FILE.FID);		% 4
    HDR.modifDate=fgetl(HDR.FILE.FID);	% 5
    
    [tmp1,tmp] = strtok(HDR.Date,'-/');
    HDR.T0     = zeros(1,6);
    HDR.T0(1)  = str2double(tmp1);
    if length(tmp1)<3, HDR.T0(1) = 1900+HDR.T0(1); end;
    [tmp1,tmp] = strtok(tmp,'-/');
    HDR.T0(2)  = str2double(tmp1);
    [tmp1,tmp] = strtok(tmp,'-/');
    HDR.T0(3)  = str2double(tmp1);
    
    HDR.SIG.Type   = fgetl(HDR.FILE.FID);		% 6 simultaneous or serial sampling
    Source = fgetl(HDR.FILE.FID);		% 7 - obsolete
    HDR.NS     = str2double(fgetl(HDR.FILE.FID));  	% 8 number of channels
    HDR.NRec   = str2double(fgetl(HDR.FILE.FID)); % 9 number of segments
    NFrames= str2double(fgetl(HDR.FILE.FID));  % 10 number of frames per segment - obsolete
    
    %HDR.SPR    = str2double(fgetl(HDR.FILE.FID));  	% 11 	number of samples per frame
    HDR.AS.spb  = str2double(fgetl(HDR.FILE.FID));  	% 11 	number of samples per frame
    H1.Bytes_per_Sample = str2double(fgetl(HDR.FILE.FID));	% 12 number of bytes per samples
    HDR.AS.bpb = HDR.AS.spb * H1.Bytes_per_Sample;
    HDR.Sampling_order    = str2double(fgetl(HDR.FILE.FID));  	% 13
    HDR.FLAG.INTEL_format = str2double(fgetl(HDR.FILE.FID));  	% 14
    HDR.FormatCode = str2double(fgetl(HDR.FILE.FID));  	% 15
    
    HDR.CompressTechnique = fgetl(HDR.FILE.FID);  		% 16
    HDR.SignalType = fgetl(HDR.FILE.FID);  			% 17
    
    for k=1:HDR.NS,
      chandata = fgetl(HDR.FILE.FID);			% 18
      [tmp,chandata] = strtok(chandata,' ,;:');
      HDR.Label{k} = tmp;
      [tmp,chandata] = strtok(chandata,' ,;:');
      HDR.Cal(k) = str2double(tmp);
      
      [tmp,chandata] = strtok(chandata,' ,;:');
      HDR.SampleRate(k) = str2double(tmp);
      
      %[tmp,chandata] = strtok(chandata);
      HDR.Variable{k} = chandata;
      
      while  ~isempty(chandata)
        [tmp,chandata] = strtok(chandata,' ,;:');
        if strcmp(tmp,'G')
          [HDR.PhysDim{k},chandata] = strtok(chandata,' ,;:');
        end;
      end;
    end;
    HDR.Calib = sparse(2:HDR.NS+1,1:HDR.NS,HDR.Cal,HDR.NS+1,HDR.NS);
    HDR.Segment_separator = fgetl(HDR.FILE.FID);  		% 19
    %HDR.Segment_separator = hex2dec(fgetl(HDR.FILE.FID));
    
    HDR.FLAG.TimeStamp = str2double(fgetl(HDR.FILE.FID));  	% 20
    
    if HDR.VERSION>=3,
      HDR.FLAG.SegmentLength = str2double(fgetl(HDR.FILE.FID));	% 21
      HDR.AppStartMark = fgetl(HDR.FILE.FID);  		% 22
      HDR.AppInfo = fgetl(HDR.FILE.FID);  			% 23
    else
      HDR.FLAG.SegmentLength = 0;
    end;
    HDR.footer = fgets(HDR.FILE.FID,6);			% 24
    
    if ~strcmp(HDR.footer,'oFSvAI')
      fprintf(HDR.FILE.stderr,'Warning LOADSIG in %s: Footer not found\n',  HDR.FileName);
    end;
    
    if HDR.VERSION<2,
      HDR.FLAG.SegmentLength = 0;
    end;
    
    switch HDR.FormatCode,
      case 0; HDR.GDFTYP = 4; %'uint16';
      case 3; HDR.GDFTYP = 3; %'int16';
        HDR.Segment_separator = hex2dec(HDR.Segment_separator([3:4,1:2]));
      case 5; HDR.GDFTYP = 16; %'float';
      otherwise;
        fprintf(HDR.FILE.stderr,'Warning LOADSIG: FormatCode %i not implemented\n',HDR.FormatCode);
    end;
    
    tmp = ftell(HDR.FILE.FID);
    if ~HDR.FLAG.INTEL_format,
      fclose(HDR.FILE.FID);
      HDR.FILE.FID = fopen(HDR.FileName,'rt','ieee-be');
      fseek(HDR.FILE.FID,tmp,'bof');
    end;
    HDR.HeadLen = tmp + HDR.FLAG.TimeStamp*9;
    
    if ~HDR.NRec, HDR.NRec = inf; end;
    k = 0;
    while (k < HDR.NRec) && ~feof(HDR.FILE.FID),
      k = k+1;
      HDR.Block.Pos(k) = ftell(HDR.FILE.FID);
      if HDR.FLAG.TimeStamp,
        HDR.Frame(k).TimeStamp = fread(HDR.FILE.FID,[1,9],'uint8');
      end;
      
      if HDR.FLAG.SegmentLength,
        HDR.Block.Length(k) = fread(HDR.FILE.FID,1,'uint16');  %#26
        fseek(HDR.FILE.FID,HDR.Block.Length(k)*H1.Bytes_per_Sample,'cof');
      else
        tmp = HDR.Segment_separator-1;
        count = 0;
        data  = [];
        dat   = [];
        while ~(any(dat==HDR.Segment_separator));
          [dat,c] = fread(HDR.FILE.FID,[HDR.NS,1024],HDR.GDFTYP);
          count   = count + c;
        end;
        tmppos = min(find(dat(:)==HDR.Segment_separator));
        HDR.Block.Length(k) = count - c + tmppos;
      end;
    end;
    HDR.SPR = HDR.Block.Length/HDR.NS;
    HDR.Dur = max(HDR.SPR./HDR.SampleRate);
    HDR.NRec = k;
    
    if HDR.FLAG.TimeStamp,
      tmp=char(HDR.Frame(1).TimeStamp);
      HDR.T0(4) = str2double(tmp(1:2));
      HDR.T0(5) = str2double(tmp(3:4));
      HDR.T0(6) = str2double([tmp(5:6),'.',tmp(7:9)]);
    end;
  end;