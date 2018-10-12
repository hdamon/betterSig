function [HDR, immediateReturn] = LABVIEW(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-be');
  
  tmp = fread(HDR.FILE.FID,8,'uint8');
  HDR.VERSION = char(fread(HDR.FILE.FID,[1,8],'uint8'));
  HDR.AS.endpos = fread(HDR.FILE.FID,1,'int32'); % 4 first bytes = total header length
  
  HDR.HeadLen  = fread(HDR.FILE.FID,1,'int32'); % 4 first bytes = total header length
  HDR.NS       = fread(HDR.FILE.FID,1,'int32');  % 4 next bytes = channel list string length
  HDR.AS.endpos2 = fread(HDR.FILE.FID,1,'int32'); % 4 first bytes = total header length
  
  HDR.ChanList = fread(HDR.FILE.FID,HDR.NS,'uint8'); % channel string
  
  fclose(HDR.FILE.FID);
  %HDR.FILE.OPEN = 1;
  HDR.FILE.FID = -1;
  
  return;
  
  %%%%% READ HEADER from Labview 5.1 supplied VI "create binary header"
  
  HDR.HeadLen  = fread(HDR.FILE.FID,1,'int32'); % 4 first bytes = total header length
  HDR.NS     = fread(HDR.FILE.FID,1,'int32');  % 4 next bytes = channel list string length
  HDR.ChanList = fread(HDR.FILE.FID,HDR.NS,'uint8'); % channel string
  
  % Number of channels = 1 + ord(lastChann) - ord(firstChann):
  HDR.LenN     = fread(HDR.FILE.FID,1,'int32'); % Hardware config length
  HDR.HWconfig = fread(HDR.FILE.FID,HDR.LenN,'uint8'); % its value
  HDR.SampleRate = fread(HDR.FILE.FID,1,'float32');
  HDR.InterChannelDelay = fread(HDR.FILE.FID,1,'float32');
  tmp=fread(HDR.FILE.FID,[1,HDR.HeadLen - ftell(HDR.FILE.FID)],'uint8'); % read rest of header
  [HDR.Date,tmp]= strtok(tmp,9) ; % date is the first 10 elements of this tmp array (strip out tab)
  [HDR.Time,tmp]= strtok(tmp,9); % and time is the next 8 ones
  % HDR.T0 = [yyyy mm dd hh MM ss];   %should be Matlab date/time format like in clock()
  HDR.Description= char(tmp); % description is the rest of elements.
  
  % Empirically determine the number of bytes per multichannel point:
  HDR.HeadLen = ftell(HDR.FILE.FID) ;
  dummy10 = fread(HDR.FILE.FID,[HDR.NS,1],'int32');
  HDR.AS.bpb = (ftell(HDR.FILE.FID) - HDR.HeadLen); % hope it's an int !
  
  tmp = fseek(HDR.FILE.FID,0,'eof');
  HDR.AS.endpos = (ftell(HDR.FILE.FID) - HDR.HeadLen)/HDR.AS.bpb;
  fseek(HDR.FILE.FID,HDR.HeadLen,'bof');
  
  HDR.Cal = 1;
  