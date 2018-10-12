function [HDR, immediateReturn] = RMF(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


  HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
  
  if HDR.FILE.FID > 0,
    fclose(HDR.FILE.FID)
    
    fprintf(HDR.FILE.stderr,'Warning SOPEN: RMF not ready for use\n');
    return;
  end;