function [HDR, immediateReturn] = LDR(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


HDR = openldr(HDR,[HDR.FILE.PERMISSION,'t']);