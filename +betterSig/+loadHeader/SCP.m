function HDF = SCP(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


  HDR = scpopen(HDR,CHAN,MODE,ReRefMx);
  HDR.GDFTYP = repmat(5,1,HDR.NS);
  if HDR.ErrNum,
    fclose(HDR.FILE.FID);
    HDR.FILE.OPEN = 0;
    return;
  end;
  