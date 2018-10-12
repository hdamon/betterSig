function [HDR, immediateReturn] = DEMG(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
  if ~isempty(findstr(HDR.FILE.PERMISSION,'r')),		%%%%% READ
    % read header
    fseek(HDR.FILE.FID,4,'bof');    % skip first 4 bytes, should contain 'DEMG'
    HDR.VERSION = fread(HDR.FILE.FID,1,'uint16');
    HDR.NS  = fread(HDR.FILE.FID,1,'uint16');
    HDR.SampleRate = fread(HDR.FILE.FID,1,'uint32');
    HDR.SPR = fread(HDR.FILE.FID,1,'uint32');
    HDR.NRec = 1;
    
    HDR.Bits = fread(HDR.FILE.FID,1,'uint8');
    HDR.PhysMin = fread(HDR.FILE.FID,1,'int8');
    HDR.PhysMax = fread(HDR.FILE.FID,1,'int8');
    if HDR.VERSION==1,
      HDR.GDFTYP = 'float32';
      HDR.Cal = 1;
      HDR.Off = 0;
      HDR.AS.bpb = 4*HDR.NS;
    elseif HDR.VERSION==2,
      HDR.GDFTYP = 'uint16';
      HDR.Cal = (HDR.PhysMax-HDR.PhysMin)/(2^HDR.Bits-1);
      HDR.Off = HDR.PhysMin;
      HDR.AS.bpb = 2*HDR.NS;
    else
      fprintf(HDR.FILE.stderr,'Error SOPEN DEMG: invalid version number.\n');
      fclose(HDR.FILE.FID);
      HDR.FILE.FID=-1;
      return;
    end;
    HDR.Calib = sparse([ones(1,HDR.NS),2:HDR.NS+1],[1:HDR.NS,1:HDR.NS],ones(HDR.NS,1)*[HDR.Off,HDR.Cal],HDR.NS+1,HDR.NS);
    HDR.HeadLen = ftell(HDR.FILE.FID);
    HDR.FILE.POS = 0;
    HDR.FILE.OPEN = 1;
    %HDR.Filter.LowPass = 450;       % default values
    %HDR.Filter.HighPass = 20;       % default values
    
  else
    fprintf(HDR.FILE.stderr,'Warning SOPEN DEMG: writing not implemented, yet.\n');
  end;