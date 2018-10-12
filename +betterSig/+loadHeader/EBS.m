function [HDR, immediateReturn] = EBS(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-be');
  
  fprintf(HDR.FILE.stderr,'Warning SOPEN: Implementing EBS format not completed yet. Contact <Biosig-general@lists.sourceforge.net> if you are interested in this feature.\n');
  
  %%%%% (1) Fixed Header (32 bytes) %%%%%
  HDR.VERSION = fread(HDR.FILE.FID,[1,8],'uint8');	%
  if ~strcmp(char(HDR.VERSION(1:3)),'EBS')
    fprintf(HDR.FILE.stderr,'Error LOADEBS: %s not an EBS-File',HDR.FileName);
    if any(HDR.VERSION(4:8)~=hex2dec(['94';'0a';'13';'1a';'0d'])');
      fprintf(HDR.FILE.stderr,'Warning SOPEN EBS: %s may be corrupted',HDR.FileName);
    end;
  end;
  HDR.EncodingId = fread(HDR.FILE.FID,1,'int32');	%
  HDR.NS  = fread(HDR.FILE.FID,1,'uint32');	% Number of Channels
  HDR.SPR=fread(HDR.FILE.FID,1,'int64')	% Data Length
  LenData=fread(HDR.FILE.FID,1,'int64')	% Data Length
  
  %%%%% (2) LOAD Variable Header %%%%%
  tag=fread(HDR.FILE.FID,1,'int32');	% Tag field
  fid = HDR.FILE.FID;
  while (tag~=0),
    l  =fread(fid,1,'int32');	% length of value field
    [tag,l],
    %val=char(fread(HDR.FILE.FID,l,'uint16')');	% depends on Tag field
    if     tag==hex2dec('00000002'),	%IGNORE
    elseif tag==hex2dec('00000004') HDR.Patient.Name	= fread(fid,2*l,'uint16=>char');
    elseif tag==hex2dec('00000006') HDR.Patient.Id		= fread(fid,l,'uint32');
    elseif tag==hex2dec('00000008') HDR.Patient.Birthday 	= fread(fid,l,'uint32');
    elseif tag==hex2dec('0000000a') HDR.Patient.Sex		= fread(fid,l,'uint32');
    elseif tag==hex2dec('0000000c') HDR.SHORT_DESCRIPTION		= fread(fid,2*l,'uint16=>char');
    elseif tag==hex2dec('0000000e') HDR.DESCRIPTION		= fread(fid,2*l,'uint16=>char');
    elseif tag==hex2dec('00000010') HDR.SampleRate		= str2double(fread(fid,4*l,'uint8=>char'));
    elseif tag==hex2dec('00000012') HDR.INSTITUTION		= fread(fid,l,'uint32');
    elseif tag==hex2dec('00000014') HDR.PROCESSING_HISTORY		= fread(fid,2*l,'uint16=>char');
    elseif tag==hex2dec('00000016') HDR.LOCATION_DIAGRAM		= fread(fid,2*l,'uint16=>char');
      
    elseif tag==hex2dec('00000001') HDR.PREFERRED_INTEGER_RANGE	= fread(fid,2*l,'uint16=>char');; %reshape(reshape(val,HDR.NS,numel(val)/HDR.NS),2,numel(val));
    elseif tag==hex2dec('00000003')
      [val,c] = fread(fid,4*l,'uint8=>char');
      %val = char(reshape(val(1:16*(HDR.NS)),16,HDR.NS))'
      %HDR.Cal = str2double(cellstr(val(:,1:8)));
      %HDR.PhysDim = cellstr(val(:,[10,12]));
      
    elseif tag==hex2dec('00000005')
      [val,c] = fread(fid,2*l,'uint16=>char');
      val = reshape(val(1:8*floor(2*l/8)),8,floor(2*l/8))'
      HDR.Label = val;
      
    elseif tag==hex2dec('00000007') HDR.CHANNEL_GROUPS		= fread(fid,2*l,'uint16=>char')';
    elseif tag==hex2dec('00000009') HDR.EVENTS			= fread(fid,2*l,'uint16=>char')';
    elseif tag==hex2dec('0000000b')
      t = fread(fid,4*l,'uint8=>char')';
      t2 = repmat(' ',1,20);
      t2([1:4,6:7,9:10,13:14,16:17,19:20]) = t([1:8,10:15]);
      HDR.T0 = str2double(t2,' ');
      
    elseif tag==hex2dec('0000000d') HDR.CHANNEL_LOCATIONS	= fread(fid,2*l,'uint16=>char')';
    elseif tag==hex2dec('0000000f')
      t = fread(fid,4*l,'uint8=>char');
      t = reshape(t(1:28*floor(numel(t)/28)),28,floor(numel(t)/28))';
      HDR.Filter.LowPass = str2double(cellstr(t(:,5:8)));
      HDR.Filter.HighPass = str2double(cellstr(t(:,17:20)));
    else
      break;
    end;
    tag=fread(fid,1,'int32');	% Tag field
  end;
  %if ~tag, fseek(fid,-4,'cof'); end;
  
  %%%%% (3) Encoded Signal Data 4*d bytes%%%%%
  HDR.data = fread(fid,[HDR.NS,inf],'int16')';
  HDR.HeadLen = ftell(fid);
  fclose(HDR.FILE.FID);
  