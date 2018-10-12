function [HDR, immediateReturn] = FS4(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 if any(HDR.FILE.PERMISSION=='r'),
    HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-be');
    HDR.FILE.OPEN = 1;
    HDR.FILE.POS  = 0;
    
    tmp = fread(HDR.FILE.FID,[1,3],'uint8');
    HDR.SURF.N = tmp*(2.^[16;8;1]);
    tmp = fread(HDR.FILE.FID,[1,3],'uint8');
    HDR.FACE.N = tmp*(2.^[16;8;1]);
    HDR.VERTEX.COORD = fread(HDR.FILE.FID,3*HDR.SURF.N,'int16')./100;
    tmp = fread(HDR.FILE.FID,[4*HDR.FACE.N,3],'uint8')*(2.^[16;8;1]);
    HDR.FACES = reshape(tmp,4,HDR.FACE.N)';
    fclose(HDR.FILE.FID);
  end;
  