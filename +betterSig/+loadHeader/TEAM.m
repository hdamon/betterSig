function [HDR, immediateReturn] = TEAM(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 % implementation of this format is not finished yet.
  
  HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
  %%%%% X-Header %%%%%
  HDR.VERSION = fread(HDR.FILE.FID,1,'int16');
  HDR.NS = fread(HDR.FILE.FID,1,'int16');
  HDR.NRec = fread(HDR.FILE.FID,1,'int16');
  HDR.TEAM.Length = fread(HDR.FILE.FID,1,'int32');
  HDR.TEAM.NSKIP = fread(HDR.FILE.FID,1,'int32');
  HDR.SPR = fread(HDR.FILE.FID,1,'int32');
  HDR.Samptype = fread(HDR.FILE.FID,1,'int16');
  if   	HDR.Samptype==2, HDR.GDFTYP = 'int16';
  elseif 	HDR.Samptype==4, HDR.GDFTYP = 'float32';
  else
    fprintf(HDR.FILE.stderr,'Error SOPEN TEAM-format: invalid file\n');
    fclose(HDR.FILE.FID);
    return;
  end;
  HDR.XLabel = fread(HDR.FILE.FID,[1,8],'uint8');
  HDR.X0 = fread(HDR.FILE.FID,1,'float');
  HDR.TEAM.Xstep = fread(HDR.FILE.FID,1,'float');
  HDR.SampleRate = 1/HDR.TEAM.Xstep;
  tmp = fread(HDR.FILE.FID,[1,6],'uint8');
  tmp(1) = tmp(1) + 1980;
  HDR.T0 = tmp([4,5,6,1,2,3]);
  
  HDR.EVENT.N   = fread(HDR.FILE.FID,1,'int16');
  HDR.TEAM.Nsegments = fread(HDR.FILE.FID,1,'int16');
  HDR.TEAM.SegmentOffset = fread(HDR.FILE.FID,1,'int32');
  HDR.XPhysDim = fread(HDR.FILE.FID,[1,8],'uint8');
  HDR.TEAM.RecInfoOffset = fread(HDR.FILE.FID,1,'int32');
  status = fseek(HDR.FILE.FID,256,'bof');
  %%%%% Y-Header %%%%%
  for k = 1:HDR.NS,
    HDR.Label{k} = char(fread(HDR.FILE.FID,[1,7],'uint8'));
    HDR.PhysDim{k} = char(fread(HDR.FILE.FID,[1,7],'uint8'));
    HDR.Off(1,k) = fread(HDR.FILE.FID,1,'float');
    HDR.Cal(1,k) = fread(HDR.FILE.FID,1,'float');
    HDR.PhysMax(1,k) = fread(HDR.FILE.FID,1,'float');
    HDR.PhysMin(1,k) = fread(HDR.FILE.FID,1,'float');
    status = fseek(HDR.FILE.FID,2,'cof');
  end;
  HDR.HeadLen = 256+HDR.NS*32;
  
  % Digital (event) information
  HDR.TEAM.DigitalOffset = 256 + 32*HDR.NS + HDR.NS*HDR.NRec*HDR.SPR*HDR.Samptype;
  status = fseek(HDR.FILE.FID,HDR.TEAM.DigitalOffset,'bof');
  if HDR.TEAM.DigitalOffset < HDR.TEAM.SegmentOffset,
    HDR.EventLabels = char(fread(HDR.FILE.FID,[16,HDR.EVENT.N],'uint8')');
    
    % Events could be detected in this way
    % HDR.Events = zeros(HDR.SPR*HDR.NRec,1);
    % for k = 1:ceil(HDR.EVENT.N/16)
    %	HDR.Events = HDR.Events + 2^(16*k-16)*fread(HDR.FILE.FID,HDR.SPR*HDR.NRec,'uint16');
    % end;
  end;
  
  % Segment information block entries
  if HDR.TEAM.Nsegments,
    fseek(HDR.FILE.FID,HDR.TEAM.SegmentOffset,'bof');
    for k = 1:HDR.TEAM.Nsegments,
      HDR.TEAM.NSKIP(k) = fread(HDR.FILE.FID,1,'int32');
      HDR.SPR(k)  = fread(HDR.FILE.FID,1,'int32');
      HDR.X0(k) = fread(HDR.FILE.FID,1,'float');
      HDR.Xstep(k) = fread(HDR.FILE.FID,1,'float');
      status = fseek(HDR.FILE.FID,8,'cof');
    end;
  end;
  
  % Recording information block entries
  if HDR.TEAM.RecInfoOffset,
    status = fseek(HDR.FILE.FID,HDR.TEAM.RecInfoOffset,'bof');
    blockinformation = fread(HDR.FILE.FID,[1,32],'uint8');
    for k = 1:HDR.NRec,
      HDR.TRIGGER.Time(k) = fread(HDR.FILE.FID,1,'double');
      HDR.TRIGGER.Date(k,1:3) = fread(HDR.FILE.FID,[1,3],'uint8');
      fseek(HDR.FILE.FID,20,'cof');
    end;
    HDR.TRIGGER.Date(k,1) = HDR.TRIGGER.Date(k,1) + 1900;
  end;
  fprintf(HDR.FILE.stderr,'Warning SOPEN: Implementing Nicolet TEAM file format not completed yet. Contact <Biosig-general@lists.sourceforge.net> if you are interested in this feature.\n');
  fclose(HDR.FILE.FID);