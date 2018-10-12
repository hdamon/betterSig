function [HDR, immediateReturn] = TMS32(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 if any(HDR.FILE.PERMISSION=='r'),
    HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
    HDR.ID = fread(HDR.FILE.FID,31,'uint8');
    HDR.VERSION = fread(HDR.FILE.FID,1,'int16');	% 31
    [tmp,c] = fread(HDR.FILE.FID,81,'uint8');	% 33
    HDR.SampleRate = fread(HDR.FILE.FID,1,'int16');	% 114
    HDR.TMS32.StorageRate = fread(HDR.FILE.FID,1,'int16');	% 116
    HDR.TMS32.StorageType = fread(HDR.FILE.FID,1,'uint8');	% 118
    HDR.NS = fread(HDR.FILE.FID,1,'int16');		% 119
    HDR.AS.endpos = fread(HDR.FILE.FID,1,'int32');	% 121
    tmp = fread(HDR.FILE.FID,1,'int32');		% 125
    tmp = fread(HDR.FILE.FID,[1,7],'int16');	% 129
    HDR.T0   = tmp([1:3,5:7]);
    HDR.NRec = fread(HDR.FILE.FID,1,'int32');	% 143
    HDR.SPR  = fread(HDR.FILE.FID,1,'uint16');	% 147
    HDR.AS.bpb = fread(HDR.FILE.FID,1,'uint16')+86;	% 149
    HDR.FLAG.DeltaCompression = fread(HDR.FILE.FID,1,'int16');	% 151
    tmp = fread(HDR.FILE.FID,64,'uint8');		% 153
    HDR.HeadLen = 217 + HDR.NS*136;
    HDR.FILE.OPEN = 1;
    HDR.FILE.POS = 0;
    
    aux = 0;
    for k=1:HDR.NS,
      c   = fread(HDR.FILE.FID,[1,1],'uint8');
      tmp = fread(HDR.FILE.FID,[1,40],'uint8=>char');
      if strncmp(tmp,'(Lo)',4);
        %Label(k-aux,1:c-5) = tmp(6:c);
        HDR.Label{k-aux} = deblank(tmp(6:c));
        HDR.GDFTYP(k-aux)  = 16;
      elseif strncmp(tmp,'(Hi) ',5) ;
        aux = aux + 1;
      else
        HDR.Label{k-aux}  = deblank(tmp(1:c));
        HDR.GDFTYP(k-aux) = 3;
      end;
      
      tmp = fread(HDR.FILE.FID,[1,4],'uint8');
      c   = fread(HDR.FILE.FID,[1,1],'uint8');
      tmp = fread(HDR.FILE.FID,[1,10],'uint8=>char');
      HDR.PhysDim{k-aux} = deblank(tmp(1:c));
      
      HDR.PhysMin(k-aux,1) = fread(HDR.FILE.FID,1,'float32');
      HDR.PhysMax(k-aux,1) = fread(HDR.FILE.FID,1,'float32');
      HDR.DigMin(k-aux,1)  = fread(HDR.FILE.FID,1,'float32');
      HDR.DigMax(k-aux,1)  = fread(HDR.FILE.FID,1,'float32');
      HDR.TMS32.SI(k) = fread(HDR.FILE.FID,1,'int16');
      tmp = fread(HDR.FILE.FID,62,'uint8');
    end;
    HDR.NS  = HDR.NS-aux;
    HDR.Cal = (HDR.PhysMax-HDR.PhysMin)./(HDR.DigMax-HDR.DigMin);
    HDR.Off = HDR.PhysMin - HDR.Cal .* HDR.DigMin;
    HDR.Calib = sparse([HDR.Off';(diag(HDR.Cal))]);
  end;
  