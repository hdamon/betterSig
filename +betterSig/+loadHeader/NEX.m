function [HDR, immediateReturn] = NEX(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 fprintf(HDR.FILE.stderr,'Warning: SOPEN (NEX) is still in testing phase.\n');
  if any(HDR.FILE.PERMISSION=='r'),
    HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
    if HDR.FILE.FID<0,
      return;
    end
    
    HDR.FILE.POS  = 0;
    HDR.NEX.magic = fread(HDR.FILE.FID,1,'int32');
    HDR.VERSION = fread(HDR.FILE.FID,1,'int32');
    HDR.NEX.comment = char(fread(HDR.FILE.FID,[1,256],'uint8'));
    HDR.NEX.SampleRate = fread(HDR.FILE.FID, 1, 'double');
    HDR.NEX.begintime = fread(HDR.FILE.FID, 1, 'int32');
    HDR.NEX.endtime = fread(HDR.FILE.FID, 1, 'int32');
    HDR.NEX.NS = fread(HDR.FILE.FID, 1, 'int32');
    status = fseek(HDR.FILE.FID, 260, 'cof');
    
    HDR.EVENT.DUR = [];
    HDR.EVENT.CHN = [];
    
    for k = 1:HDR.NEX.NS,
      HDR.NEX.pos0(k) = ftell(HDR.FILE.FID);
      HDR.NEX.type(k) = fread(HDR.FILE.FID, 1, 'int32');
      HDR.NEX.version(k) = fread(HDR.FILE.FID, 1, 'int32');
      Label(k,:) = fread(HDR.FILE.FID, [1 64], 'uint8');
      HDR.NEX.offset(k)  = fread(HDR.FILE.FID, 1, 'int32');
      HDR.NEX.nf(k)  = fread(HDR.FILE.FID, 1, 'int32');
      reserved(k,:) = char(fread(HDR.FILE.FID, [1 32], 'uint8'));
      HDR.NEX.SampleRate(k) = fread(HDR.FILE.FID, 1, 'double');
      HDR.NEX.Cal(k) = fread(HDR.FILE.FID, 1, 'double');
      HDR.NEX.SPR(k) = fread(HDR.FILE.FID, 1, 'int32');
      HDR.NEX.h2(:,k)= fread(HDR.FILE.FID,19,'uint32');
      %nm = fread(HDR.FILE.FID, 1, 'int32');
      %nl = fread(HDR.FILE.FID, 1, 'int32');
      
      HDR.NEX.pos(k) = ftell(HDR.FILE.FID);
      %                        fseek(HDR.FILE.FID, HDR.NEX.pos0(k)+208,'bof');
    end;
    HDR.HeadLen = ftell(HDR.FILE.FID);
    
    HDR.NEX.Label = char(Label);
    HDR.PhysDim   = 'mV';
    HDR.FILE.POS  = 0;
    HDR.FILE.OPEN = 1;
    HDR.NRec = 1;
    
    % select AD-channels only,
    CH = find(HDR.NEX.type==5);
    HDR.AS.chanreduce = cumsum(HDR.NEX.type==5);
    HDR.NS = length(CH);
    HDR.Calib = sparse(2:HDR.NS+1,1:HDR.NS,HDR.NEX.Cal(CH));
    HDR.Label = HDR.NEX.Label(CH,:);
    HDR.AS.SampleRate = HDR.NEX.SampleRate(CH);
    HDR.AS.SPR = HDR.NEX.SPR(CH);
    HDR.SPR = 1;
    HDR.SampleRate = 1;
    for k = 1:HDR.NS,
      HDR.SPR = lcm(HDR.SPR,HDR.AS.SPR(k));
      HDR.SampleRate = lcm(HDR.SampleRate,HDR.AS.SampleRate(k));
    end;
  end;
  