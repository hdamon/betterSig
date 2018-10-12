function [HDR, immediateReturn] = BKR(HDR,CHAN,MODE,ReRefMx)

  HDR = bkropen(HDR,CHAN,MODE,ReRefMx);
  HDR.GDFTYP = repmat(3,1,HDR.NS);
  %%% Get trigger information from BKR data
  immediateReturn = false;
end;

