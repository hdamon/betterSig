function [HDR, immediateReturn] = UFF5b(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


if ~isempty(findstr(HDR.FILE.PERMISSION,'r')),		%%%%% READ
    HDR.FILE.FID = fopen(HDR.FileName,'rt');
    fclose(HDR.FILE.FID);
  end;
  
  