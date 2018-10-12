function [HDR, immediateReturn] = MicroMedTDC(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


  % MicroMed Srl, *.TRC format
  HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
  HDR.dat = fread(HDR.FILE.FID,[1,inf],'*uint8');
  HDR.Patient.Name = char(HDR.dat(192+[1:42]));
  fclose(HDR.FILE.FID);