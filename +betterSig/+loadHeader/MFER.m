function [HDR, immediateReturn] = MFER(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


  HDR = mwfopen(HDR,[HDR.FILE.PERMISSION,'b']);
  if (HDR.FRAME.N ~= 1),
    fprintf(HDR.FILE.stderr,'Error SOPEN (MFER): files with more than one frame not implemented, yet.\n');
    fclose(HDR.FILE.FID);
    HDR.FILE.FID  =-1;
    HDR.FILE.OPEN = 0;
  end