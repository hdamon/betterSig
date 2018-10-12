function [HDR, immediateReturn] = FAMOS(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = true; % Default Value
   HDR = famosopen(HDR,CHAN,MODE,ReRefMx);
