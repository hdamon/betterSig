function [HDR, immediateReturn] = ABF2(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value

 fprintf(HDR.FILE.stderr,'Warning: SOPEN (ABF2) is very experimental.\n');
  if any(HDR.FILE.PERMISSION=='r'),
    HDR.FILE.FID = fopen(HDR.FileName,HDR.FILE.PERMISSION,'ieee-le');
    HDR.ABF.ID = char(fread(HDR.FILE.FID,[1,4],'uint8'));
    HDR.Version = fread(HDR.FILE.FID,1,'uint32');
    HDR.HeadLen = fread(HDR.FILE.FID,1,'uint32');
    HDR.ABF.StartDate = fread(HDR.FILE.FID,1,'uint32');
    HDR.ABF.StartTimeMS = fread(HDR.FILE.FID,1,'uint32');
    HDR.ABF.StopWatchTime = fread(HDR.FILE.FID,1,'uint32');
    HDR.ABF.FLAGS = fread(HDR.FILE.FID,4,'uint16');
    HDR.ABF.FileCRC = fread(HDR.FILE.FID,1,'uint32');
    HDR.ABF.FileGUID= fread(HDR.FILE.FID,16,'uint8');
    HDR.ABF.VersionIndex = fread(HDR.FILE.FID,5,'uint32');
    NSections1 = 8;
    NSections2= 0;
    if strcmp(HDR.TYPE,'ABF2'),
      NSections2 = 10;
    end;
    for k=1:NSections1+NSections2;,
      HDR.Section{k}.BlockIndex = fread(HDR.FILE.FID,1,'int32');
      HDR.Section{k}.Bytes      = fread(HDR.FILE.FID,1,'int32');
      HDR.Section{k}.NumEntries = fread(HDR.FILE.FID,1,'int32');
    end;
    
    %% read various sections
    for k=1:NSections1+NSections2,
      if (HDR.Section{k}.BlockIndex)
        fseek(HDR.FILE.FID,HDR.Section{k}.BlockIndex * 512,'bof');
        
        if (NSections2>0) && (k==1), % StringsSection
          
        elseif (NSections2>0) && (k==10), % StringsSection
          HDR.ABF.StringSection = char(fread(HDR.FILE.FID,[1,HDR.Section{k}.NumEntries*HDR.Section{k}.Bytes],'uint8'));
        end;
      end;
    end;
    fseek(HDR.FILE.FID,HDR.HeadLen,'bof');
  end
