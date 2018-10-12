function [HDR, immediateReturn] = DDF(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = true; % Default Value



  % implementation of this format is not finished yet.
  fprintf(HDR.FILE.stderr,'Warning SOPEN: Implementing DASYLAB format not completed yet. Contact <Biosig-general@lists.sourceforge.net> if you are interested in this feature.\n');
  %HDR.FILE.FID = -1;
  %return;
  
  if any(HDR.FILE.PERMISSION=='r'),
    HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
    HDR.FILE.OPEN = 1;
    HDR.FILE.POS = 0;
    %HDR.ID = fread(HDR.FILE.FID,5,'uint8');
    ds=fread(HDR.FILE.FID,[1,128],'uint8');
    HDR.ID = char(ds(1:5));
    DataSource = ds;
    k = 0;
    while ~(any(ds==26)),
      ds = fread(HDR.FILE.FID,[1,128],'uint8');
      DataSource = [DataSource,ds];
      k = k+1;
    end;
    pos = find(ds==26)+k*128;
    DataSource = char(DataSource(6:pos));
    HDR.DDF.Source = DataSource;
    while ~isempty(DataSource),
      [ds,DataSource] = strtok(char(DataSource),[10,13]);
      [field,value] = strtok(ds,'=');
      if strfind(field,'SAMPLE RATE');
        [tmp1,tmp2] = strtok(value,'=');
        HDR.SampleRate = str2double(tmp1);
      elseif strfind(field,'DATA CHANNELS');
        HDR.NS = str2double(value);
      elseif strfind(field,'START TIME');
        Time = value;
      elseif strfind(field,'DATA FILE');
        HDR.FILE.DATA = value;
      end;
    end;
    fseek(HDR.FILE.FID,pos,'bof'); 	% position file identifier
    if 0;%DataSource(length(DataSource))~=26,
      fprintf(1,'Warning: DDF header seems to be incorrenct. Contact <alois.schloegl@ist.ac.at> Subject: BIOSIG/DATAFORMAT/DDF  \n');
    end;
    HDR.DDF.CPUidentifier  = fread(HDR.FILE.FID,[1,2],'uint8=>char');
    HDR.HeadLen(1) = fread(HDR.FILE.FID,1,'uint16');
    tmp = fread(HDR.FILE.FID,1,'uint16');
    if tmp == 0, HDR.GDFTYP = 'uint16'; 		% streamer format (data are raw data in WORD=UINT16)
    elseif tmp == 1, HDR.GDFTYP = 'float32'; 	% Universal Format 1 (FLOAT)
    elseif tmp == 2, HDR.GDFTYP = 'float64'; 	% Universal Format 2 (DOUBLE)
    elseif tmp <= 1000, % reserved
    else		% unused
    end;
    HDR.FILE.Type  = tmp;
    HDR.VERSION    = fread(HDR.FILE.FID,1,'uint16');
    HDR.HeadLen(2) = fread(HDR.FILE.FID,1,'uint16');	% second global Header
    HDR.HeadLen(3) = fread(HDR.FILE.FID,1,'uint16');	% size of channel Header
    fread(HDR.FILE.FID,1,'uint16');	% size of a block Header
    tmp = fread(HDR.FILE.FID,1,'uint16');
    if tmp ~= isfield(HDR.FILE,'DATA')
      fprintf(1,'Warning: DDF header seems to be incorrenct. Contact <alois.schloegl@ist.ac.at> Subject: BIOSIG/DATAFORMAT/DDF  \n');
    end;
    HDR.NS = fread(HDR.FILE.FID,1,'uint16');
    HDR.Delay = fread(HDR.FILE.FID,1,'double');
    HDR.StartTime = fread(HDR.FILE.FID,1,'uint32');  % might be incorrect
    
    % it looks good so far.
    % fseek(HDR.FILE.FID,HDR.HeadLen(1),'bof');
    if HDR.FILE.Type==0,
      % second global header
      fread(HDR.FILE.FID,1,'uint16')	% overall number of bytes in this header
      fread(HDR.FILE.FID,1,'uint16')	% number of analog channels
      fread(HDR.FILE.FID,1,'uint16')	% number of counter channels
      fread(HDR.FILE.FID,1,'uint16')	% number of digital ports
      fread(HDR.FILE.FID,1,'uint16')	% number of bits in each digital port
      fread(HDR.FILE.FID,1,'uint16')	% original blocksize when data was stored
      fread(HDR.FILE.FID,1,'uint32')	% sample number of the first sample (when cyclic buffer not activated, always zero
      fread(HDR.FILE.FID,1,'uint32')	% number of samples per channel
      
      % channel header
      for k = 1:HDR.NS,
        fread(HDR.FILE.FID,1,'uint16')	% number of bytes in this hedader
        fread(HDR.FILE.FID,1,'uint16')	% channel type 0: analog, 1: digital, 2: counter
        HDR.Label = char(fread(HDR.FILE.FID,[24,16],'uint8')');	%
        tmp = fread(HDR.FILE.FID,1,'uint16')	% dataformat 0 UINT, 1: INT
        HDR.GDFTYP(k) = 3 + (~tmp);
        HDR.Cal(k) = fread(HDR.FILE.FID,1,'double');	%
        HDR.Off(k) = fread(HDR.FILE.FID,1,'double');	%
      end;
      
    elseif HDR.FILE.Type==1,
      % second global header
      HDR.pos1 = ftell(HDR.FILE.FID);
      tmp = fread(HDR.FILE.FID,1,'uint16');	% size of this header
      if (tmp~=HDR.HeadLen(2)),
        fprintf(HDR.FILE.stderr,'Error SOPEN DDF: error in header of file %s\n',HDR.FileName);
      end;
      HDR.U1G.NS = fread(HDR.FILE.FID,1,'uint16');	% number of channels
      HDR.FLAG.multiplexed = fread(HDR.FILE.FID,1,'uint16');	% multiplexed: 0=no, 1=yes
      HDR.DDF.array = fread(HDR.FILE.FID,[1,16],'uint16');	% array of channels collected on each input channel
      
      % channel header
      for k = 1:HDR.NS,
        filepos = ftell(HDR.FILE.FID);
        taglen = fread(HDR.FILE.FID,1,'uint16');	% size of this header
        ch = fread(HDR.FILE.FID,1,'uint16');	% channel number
        HDR.DDF.MAXSPR(ch+1)= fread(HDR.FILE.FID,1,'uint16');	% maximum size of block in samples
        HDR.DDF.delay(ch+1) = fread(HDR.FILE.FID,1,'double');	% time delay between two samples
        HDR.DDF.ChanType(ch+1) = fread(HDR.FILE.FID,1,'uint16');	% channel type
        HDR.DDF.ChanFlag(ch+1) = fread(HDR.FILE.FID,1,'uint16');	% channel flag
        unused = fread(HDR.FILE.FID,2,'double');	% must be 0.0 for future extension
        tmp = fgets(HDR.FILE.FID);	% channel unit
        HDR.PhysDim{k} = [tmp,' '];	% channel unit
        tmp = fgets(HDR.FILE.FID);		% channel name
        HDR.Label{k} = [tmp,' '];		% channel name
        fseek(HDR.FILE.FID,filepos+taglen,'bof');
      end;
      
      % channel header
      for k = 1:HDR.NS,
        fread(HDR.FILE.FID,[1,4],'uint8');
        fread(HDR.FILE.FID,1,'uint16');	% overall number of bytes in this header
        HDR.BlockStartTime = fread(HDR.FILE.FID,1,'uint32');  % might be incorrect
        unused = fread(HDR.FILE.FID,2,'double');	% must be 0.0 for future extension
        ch = fread(HDR.FILE.FID,1,'uint32');  % channel number
      end;
      fseek(HDR.FILE.FID,HDR.pos1+sum(HDR.HeadLen(2:3)),'bof');
      
    elseif HDR.FILE.Type==2,
      % second global header
      pos = ftell(HDR.FILE.FID);
      HeadLen = fread(HDR.FILE.FID,1,'uint16');	% size of this header
      fread(HDR.FILE.FID,1,'uint16');	% number of channels
      fseek(HDR.FILE.FID, pos+HeadLen ,'bof');
      
      % channel header
      for k = 1:HDR.NS,
        pos = ftell(HDR.FILE.FID);
        HeadLen = fread(HDR.FILE.FID,1,'uint16');	% size of this header
        HDR.DDF.Blocksize(k) = fread(HDR.FILE.FID,1,'uint16');	%
        HDR.DDF.Delay(k) = fread(HDR.FILE.FID,1,'double');	%
        HDR.DDF.chantyp(k) = fread(HDR.FILE.FID,1,'uint16');	%
        HDR.FLAG.TRIGGER(k) = ~~fread(HDR.FILE.FID,1,'uint16');
        fread(HDR.FILE.FID,1,'uint16');
        HDR.Cal(k) = fread(HDR.FILE.FID,1,'double');
      end;
    else
      
    end;
    %ftell(HDR.FILE.FID),
    tag=fread(HDR.FILE.FID,[1,4],'uint8');
  end;