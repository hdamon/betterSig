function [HDR, immediateReturn] = AKO(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


  HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
  HDR.Header = fread(HDR.FILE.FID,[1,46],'uint8');
  warning('support of AKO format not completed');
  HDR.Patient.Id = char(HDR.Header(17:24));
  HDR.SampleRate = 128; % ???
  HDR.NS = 1;
  HDR.NRec = 1;
  HDR.Calib = [-127;1];
  [HDR.data,HDR.SPR] = fread(HDR.FILE.FID,inf,'uint8');
  fclose(HDR.FILE.FID);
  HDR.FILE.POS = 0;
  HDR.TYPE = 'native';