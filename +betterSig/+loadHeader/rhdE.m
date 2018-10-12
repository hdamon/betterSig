function [HDR, immediateReturn] = rhdE(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
  
  %fseek(HDR.FILE.FID,4,'bof');		% skip 4 bytes ID
  %HDR.HeadLen = fread(HDR.FILE.FID,1,'int32');	% Length of Header ?
  %HDR.H2 = fread(HDR.FILE.FID,5,'int32');
  %HDR.NS = fread(HDR.FILE.FID,1,'int32');		% ? number of channels
  %HDR.H3 = fread(HDR.FILE.FID,5,'int32');
  tmp = fread(HDR.FILE.FID,10,'int32');
  HDR.HeadLen = tmp(2);		% Length of Header ?
  HDR.H2 = tmp;
  HDR.NS = tmp(8);		% ? number of channels
  HDR.NRec = (HDR.FILE.size-HDR.HeadLen)/1024;
  
  fprintf(1,'Warning SOPEN HolterExcel2: is under construction.\n');
  
  if (nargout>1),	% just for testing
    H1 = fread(HDR.FILE.FID,[1,inf],'uint8')';
  end;
  fclose(HDR.FILE.FID);