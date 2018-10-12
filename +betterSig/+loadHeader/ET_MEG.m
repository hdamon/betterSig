function [HDR, immediateReturn] = ET_MEG(HDR,CHAN,MODE,ReRefMx)
HDR = fltopen(HDR,CHAN,MODE,ReRefMx);
immediateReturn = false;
