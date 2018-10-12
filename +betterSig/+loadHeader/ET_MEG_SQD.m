function [HDR, immediateReturn] = ET_MEG_SQD(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 if any(HDR.FILE.PERMISSION=='r'),
    fprintf(HDR.FILE.stderr,'Warning SOPEN: support of SQD format is experimental.\n');
    HDR.HeadLen  = 55576;
    HDR.FILE.FID = fopen(fullfile(HDR.FILE.Path,[HDR.FILE.Name,'.',HDR.FILE.Ext]),'rb',HDR.Endianity);
    HDR.H8       = fread(HDR.FILE.FID,HDR.HeadLen,'uint8');
    fseek(HDR.FILE.FID,0,-1);
    HDR.H32      = fread(HDR.FILE.FID,HDR.HeadLen/4,'uint32');
    HDR.FILE.POS = 0;
    HDR.FILE.OPEN= 1;
    HDR.GDFTYP   = 3; % int16
    tmp = HDR.H32([19,20,23,24,196,7485,7486,7489,7490,7662,7763,7931,13495,13524,13582,13640,13669,13727,13785,13814]);
    if ~all(tmp==tmp(1))
      fprintf(HDR.FILE.stderr,'Warning SOPEN(SQD): possible problem in HDR.NS');
    end;
    HDR.NS = tmp(1);
    tmp = HDR.H32([4247,4248,7733,7766,8644,8645]);
    HDR.SPR = tmp(1);
    if all(tmp==tmp(1))
      fprintf(HDR.FILE.stderr,'Warning SOPEN(SQD): possible problem in HDR.SPR');
    end;
    HDR.NRec = 1;
    
    HDR.AS.endpos= HDR.SPR*HDR.NRec;
    HDR.AS.bpb   = 2*HDR.NS;		% Bytes per Block
  end