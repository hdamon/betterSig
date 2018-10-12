function [HDR, immediateReturn] = DAQ(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


HDR = daqopen(HDR,[HDR.FILE.PERMISSION,'b']);