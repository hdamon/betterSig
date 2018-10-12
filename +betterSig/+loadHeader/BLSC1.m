function [HDR, immediateReturn] = BLSC1(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
  HDR.Header = fread(HDR.FILE.FID,[1,3720],'uint8');       % ???
  HDR.data   = fread(HDR.FILE.FID,[32,inf],'ubit8');      % ???
  %HDR.NS = 32;
  %HDR.SPR = 24063;
  fclose(HDR.FILE.FID);
  fprintf(2,'Error SOPEN: Format BLSC not supported (yet).\n');
  return;
  
  H1 = HDR.Header;
  fclose(HDR.FILE.FID);