function [HDR, immediateReturn] = CSE(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


  if any(HDR.FILE.PERMISSION=='r'),
    HDR.FILE.FID = fopen(HDR.FileName,HDR.FILE.PERMISSION,'ieee-le');
    HDR.HeadLen = 3000;
    HDR.H1   = fread(HDR.FILE.FID,HDR.HeadLen,'uint8');
    HDR.data = fread(HDR.FILE.FID,[3,inf],'int16')';
    [HDR.SPR, HDR.NS] = size(HDR.data);
    HDR.NRec = 1;
    
    %		% reconstruction of transitions not fixed.
    %		d = diff([zeros(1,HDR.NS);HDR.data],[],1);
    %		e = -sign(d)*2^16;
    %		e(abs(d) <= 2^15) = 0;
    %		%HDR.data = HDR.data + cumsum(e);
    
    fclose(HDR.FILE.FID);
    HDR.TYPE = 'native';
    HDR.LeadIdCode = repmat(0,HDR.NS,1);
    HDR.FILE.POS = 0;
  end;