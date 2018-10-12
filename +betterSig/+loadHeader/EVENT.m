function [HDR, immediateReturn] = EVENT(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


  %%% Save event file in GDF-format
  HDR.TYPE = 'GDF';
  HDR.NS   = 0;
  HDR.NRec = 0;
  if any(isnan(HDR.T0))
    HDR.T0 = clock;
  end;
  HDR = sopen(HDR,'w');
  HDR = sclose(HDR,CHAN,MODE,ReRefMx);
  HDR.TYPE = 'EVENT';