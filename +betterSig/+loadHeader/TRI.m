function [HDR, immediateReturn] = TRI(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


if any(HDR.FILE.PERMISSION=='r'),
    HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
    HDR.FILE.POS  = 0;
    
    HDR.ID = fread(HDR.FILE.FID,1,'int32');
    HDR.type = fread(HDR.FILE.FID,1,'int16');
    HDR.VERSION = fread(HDR.FILE.FID,1,'int16');
    HDR.ELEC.Thickness = fread(HDR.FILE.FID,1,'float');
    HDR.ELEC.Diameter = fread(HDR.FILE.FID,1,'float');
    HDR.reserved = fread(HDR.FILE.FID,4080,'uint8');
    
    HDR.FACE.N = fread(HDR.FILE.FID,1,'int16');
    HDR.SURF.N = fread(HDR.FILE.FID,1,'int16');
    
    HDR.centroid = fread(HDR.FILE.FID,[4,HDR.FACE.N],'float')';
    HDR.VERTICES = fread(HDR.FILE.FID,[4,HDR.SURF.N],'float')';
    HDR.FACES = fread(HDR.FILE.FID,[3,HDR.FACE.N],'int16')';
    
    HDR.ELEC.N = fread(HDR.FILE.FID,1,'uint16');
    for k = 1:HDR.ELEC.N,
      tmp = fread(HDR.FILE.FID,[1,10],'uint8');
      Label{k,1} = [strtok(tmp,0), ' '];
      HDR.ELEC.Key(k,1)  = fread(HDR.FILE.FID,1,'int16');
      tmp = fread(HDR.FILE.FID,[1,3],'float');
      % HDR.elec(k).POS  = tmp(:);
      HDR.ELEC.XYZ(k,:)  = tmp;
      HDR.ELEC.CHAN(k,1) = fread(HDR.FILE.FID,1,'uint16');
    end;
    fclose(HDR.FILE.FID);
    HDR.Label = Label;
    HDR.TYPE = 'ELPOS';
  end