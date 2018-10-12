function [HDR, immediateReturn] = DICOM(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


HDR = opendicom(HDR,HDR.FILE.PERMISSION);
