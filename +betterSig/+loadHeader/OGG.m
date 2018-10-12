function [HDR, immediateReturn] = OGG(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
  
  if HDR.FILE.FID > 0,
    % chunk header
    tmp = fread(HDR.FILE.FID,1,'uint8');
    QualityIndex = mod(tmp(1),64);
    if (tmp(1)<128), % golden frame
      tmp = fread(HDR.FILE.FID,2,'uint8');
      HDR.VERSION = tmp(1);
      HDR.VP3.Version = floor(tmp(2)/8);
      HDR.OGG.KeyFrameCodingMethod = floor(mod(tmp(2),8)/4);
    end;
    
    % block coding information
    % coding mode info
    % motion vectors
    % DC coefficients
    % DC coefficients
    % 1st AC coefficients
    % 2nd AC coefficients
    % ...
    % 63rd AC coefficient
    
    fclose(HDR.FILE.FID);
    fprintf(HDR.FILE.stderr,'Warning SOPEN: OGG not ready for use\n');
    return;
  end;