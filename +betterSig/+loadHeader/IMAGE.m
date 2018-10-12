function [HDR, immediateReturn] = IMAGE(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = true; % Default Value


HDR = iopen(HDR,CHAN,MODE,ReRefMx);

immediateReturn = true;

end