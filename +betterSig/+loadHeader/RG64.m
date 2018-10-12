function [HDR, immediateReturn] = RG64(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 fid = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
  
  HDR.IDCODE=char(fread(fid,[1,4],'uint8'));	%
  if ~strcmp(HDR.IDCODE,'RG64')
    fprintf(HDR.FILE.stderr,'\nError LOADRG64: %s not a valid RG64 - header file\n',HDR.FileName);
    HDR.TYPE = 'unknown';
    fclose(fid);
    return;
  end; %end;
  
  tmp = fread(fid,2,'int32');
  HDR.VERSION = tmp(1)+tmp(2)/100;
  HDR.NS = fread(fid,1,'int32');
  HDR.SampleRate = fread(fid,1,'int32');
  HDR.SPR = fread(fid,1,'int32')/HDR.NS;
  AMPF = fread(fid,64,'int32');
  fclose(fid);
  
  HDR.HeadLen = 0;
  HDR.PhysDim = 'uV';
  HDR.Cal = (5E6/2048)./AMPF;
  HDR.AS.endpos = HDR.SPR;
  HDR.AS.bpb    = HDR.NS*2;
  HDR.GDFTYP    = 'int16';
  
  EXT = HDR.FILE.Ext;
  if upper(EXT(2))~='D',
    EXT(2) = EXT(2) - 'H' + 'D';
  end;
  FILENAME=fullfile(HDR.FILE.Path,[HDR.FILE.Name,'.',EXT]);
  
  HDR.FILE.FID=fopen(FILENAME,[HDR.FILE.PERMISSION,'b'],'ieee-le');
  if HDR.FILE.FID<0,
    fprintf(HDR.FILE.stderr,'\nError LOADRG64: data file %s not found\n',FILENAME);
    return;
  end;
  
  HDR.Calib = sparse(2:HDR.NS+1,1:HDR.NS,HDR.Cal(1:HDR.NS),HDR.NS+1,HDR.NS);
  HDR.FILE.POS = 0;
  HDR.FILE.OPEN= 1;
  