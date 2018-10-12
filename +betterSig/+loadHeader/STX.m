function [HDR, immediateReturn] = STX(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 if any(HDR.FILE.PERMISSION=='r'),
    fid = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'t'],'ieee-le');
    FileInfo = fread(fid,20,'uint8');
    HDR.Label = {char(fread(fid,[1,50],'uint8'))};
    tmp = fread(fid,6,'int');
    HDR.NRec = tmp(1);
    HDR.SPR = 1;
    
    tmp = fread(fid,5,'long');
    HDR.HeadLen = 116;
    
    fclose(HDR.FILE.FID);
  end
  