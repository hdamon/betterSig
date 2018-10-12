function [HDR, immediateReturn] = GEO_STL_BIN(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 % http://en.wikipedia.org/wiki/STL_%28file_format%29
  % http://www.fastscan3d.com/download/samples/engineering.html
  if any(HDR.FILE.PERMISSION=='r'),
    HDR.FILE.FID = fopen(HDR.FileName,HDR.FILE.PERMISSION,HDR.Endianity);
    HDR.H1 = char(fread(HDR.FILE.FID,[1,80],'uint8'));
    tmp = HDR.H1(53:72); tmp(tmp==':')=' ';
    HDR.T0(2) = strmatch(tmp(1:3),['Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul';'Aug';'Sep';'Oct';'Nov';'Dec']);
    HDR.T0([3:6,1]) = str2double(tmp(5:end));
    N = fread(HDR.FILE.FID,1,'int32');
    HDR.HeadLen = ftell(HDR.FILE.FID);
    if HDR.FILE.size~=HDR.HeadLen+N*50;
      fprintf(HDR.FILE.stderr,'WARNING SOPEN(STL): size of file %s does not fit to header information\n',HDR.FILE.Name);
    end;
    HDR.STL.DAT = fread(HDR.FILE.FID,[12,inf],'12*float32',2)';
    fseek(HDR.FILE.FID,80+4+12*4,-1);
    HDR.STL.ATT = fread(HDR.FILE.FID,[1,inf],'uint16',12*4)';
    fclose(HDR.FILE.FID);
    if N~=size(HDR.STL.DAT,1)
      fprintf(HDR.FILE.stderr,'WARNING SOPEN(STL): number of elements do not fit. Maybe file %s is corrupted!',HDR.FILE.Name);
    end;
  end;