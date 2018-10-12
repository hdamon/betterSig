function [HDR, immediateReturn] = ATES(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
  HDR.Header = fread(HDR.FILE.FID,[1,128],'uint8');
  tmp = fread(HDR.FILE.FID,1,'int16');
  HDR.FLAG.Monopolar = logical(tmp);
  HDR.SampleRate = fread(HDR.FILE.FID,1,'int16');
  HDR.Cal = fread(HDR.FILE.FID,1,'float32');
  type = fread(HDR.FILE.FID,1,'float32');
  if type==2,
    HDR.GDFTYP = 'int16';
  else
    error('ATES: unknown type');
  end;
  HDR.ATES.Mask = fread(HDR.FILE.FID,2,'uint32');
  HDR.DigMax = fread(HDR.FILE.FID,1,'uint16');
  HDR.Filter.Notch = fread(HDR.FILE.FID,1,'uint16');
  HDR.SPR = fread(HDR.FILE.FID,1,'uint32');
  HDR.ATES.MontageName = fread(HDR.FILE.FID,8,'uint8');
  HDR.ATES.MontageComment = fread(HDR.FILE.FID,31,'uint8');
  HDR.NS = fread(HDR.FILE.FID,1,'int16');
  fclose(HDR.FILE.FID);