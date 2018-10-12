function [HDR, immediateReturn] = Sigma(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 fprintf(HDR.FILE.stdout,'Warning SOPEN: SigmaPLpro format is experimental only.\n')
  fprintf(HDR.FILE.stdout,'\t Assuming Samplerate and scaling factors are fixed to 128 Hz and 1, respectively.\n')
  
  HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
  if any(HDR.FILE.PERMISSION=='r'),		%%%%% READ
    fseek(HDR.FILE.FID,16,'bof');
    HDR.XXX.S1 = fread(HDR.FILE.FID,[1,4],'uint32');
    for k = 1:5,
      line = fgets(HDR.FILE.FID);
      [tag,r]=strtok(line,['=',10,13]);
      [val]=strtok(r,['=',10,13]);
      if strcmp(tag,'Name'),
      elseif strcmp(tag,'Vorname'),
      elseif strcmp(tag,'GebDat'),
        val(val=='.')=' ';
        tmp = str2double(val);
        HDR.Patient.Birthday = [tmp([3,2,1]),12,0,0];
      elseif strcmp(tag,'ID'),
        HDR.Patient.ID = val;
      end;
    end;
    HDR.SampleRate = 128;
    HDR.NS = fread(HDR.FILE.FID,1,'uint16');
    len = fread(HDR.FILE.FID,1,'uint8');
    val = fread(HDR.FILE.FID,[1,len],'uint8=>char');
    fseek(HDR.FILE.FID,148,'bof');
    for k1=1:HDR.NS
      ch = fread(HDR.FILE.FID,1,'uint16');
      HDR.Filter.Notch(k1) = fread(HDR.FILE.FID,1,'int16') ~= 0;
      for k2=1:4
        len = fread(HDR.FILE.FID,1,'uint8');
        val = fread(HDR.FILE.FID,[1,len],'uint8=>char');
        XXX.Val(k1,k2)=str2double(val);
      end;
      HDR.Off(k1) = fread(HDR.FILE.FID,1,'int16');
      for k2=5:8
        len = fread(HDR.FILE.FID,1,'uint8');
        val = fread(HDR.FILE.FID,[1,len],'uint8=>char');
        XXX.Val(k1,k2)=str2double(val);
      end;
      val = fread(HDR.FILE.FID,4,'int16');
      HDR.ELEC.XYZ(k1,1:2)=val(1:2);
      refxy(k1,:) = val(3:4);
      len = fread(HDR.FILE.FID,1,'uint8');
      val = fread(HDR.FILE.FID,[1,19],'uint8=>char');
      HDR.Label{k1}=val(1:len);
      len = fread(HDR.FILE.FID,1,'uint8');
      val = fread(HDR.FILE.FID,[1,7],'uint8=>char');
      HDR.PhysDim{k1}=val(1:len);
      len = fread(HDR.FILE.FID,1,'uint8');
      val = fread(HDR.FILE.FID,[1,8],'uint8=>char');
    end;
    HDR.XXX.Val = XXX.Val;
    HDR.AS.SampleRate = XXX.Val(:,1);
    HDR.Filter.LowPass = XXX.Val(:,2);
    HDR.Filter.HighPass = XXX.Val(:,3);
    HDR.Filter.HighPass = XXX.Val(:,3);
    HDR.Impedance = XXX.Val(:,7);
    HDR.Cal = XXX.Val(:,8);
    HDR.Off = HDR.Off(:)'.*HDR.Cal(:)';
    if all(refxy(:,1)==refxy(1,1)) && all(refxy(:,2)==refxy(1,2))
      HDR.ELEC.REF = refxy(1,1:2);
    end;
    
    HDR.GDFTYP = repmat(3,1,HDR.NS);
    HDR.FILE.POS = 0;
    HDR.FILE.OPEN= 1;
    HDR.SPR  = 1;
    HDR.NRec = (HDR.FILE.size-HDR.HeadLen)/(2*HDR.NS);
  end;
  