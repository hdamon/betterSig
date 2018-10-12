function [HDR, immediateReturn] = FS3(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 if any(HDR.FILE.PERMISSION=='r'),
    HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-be');
    HDR.FILE.OPEN = 1;
    HDR.FILE.POS  = 0;
    HDR.Date = fgets(HDR.FILE.FID);
    HDR.Info = fgets(HDR.FILE.FID);
    HDR.SURF.N = fread(HDR.FILE.FID,1,'int32');
    HDR.FACE.N = fread(HDR.FILE.FID,1,'int32');
    HDR.VERTEX.COORD =   fread(HDR.FILE.FID,3*HDR.SURF.N,'float32');
    
    HDR.FACES = fread(HDR.FILE.FID,[3,HDR.FACE.N],'int32')';
    fclose(HDR.FILE.FID);
  end
  