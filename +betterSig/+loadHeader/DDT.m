function [HDR, immediateReturn] = DDT(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


if any(HDR.FILE.PERMISSION=='r'),
    HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
    tmp = fread(HDR.FILE.FID,2,'int32');
    HDR.Version = tmp(1);
    HDR.HeadLen = tmp(2);
    HDR.SampleRate = fread(HDR.FILE.FID,1,'double');
    HDR.NS = fread(HDR.FILE.FID,1,'int32');
    HDR.T0 = fread(HDR.FILE.FID,[1,6],'int32');
    HDR.Gain = fread(HDR.FILE.FID,1,'int32');
    HDR.Comment = char(fread(HDR.FILE.FID,[1,128],'uint8'));
    tmp = fread(HDR.FILE.FID,[1,256],'uint8');
    if HDR.Version == 100,
      HDR.Bits = 12;
      HDR.Cal = 5/2048*HDR.Gain;
    elseif HDR.Version == 101,
      HDR.Bits = tmp(1);
      HDR.Cal = 5*2^(1-HDR.Bits)/HDR.Gain;
    elseif HDR.Version == 102,
      HDR.Bits = tmp(1);
      ChannelGain = tmp(2:65);
      HDR.Cal = 5000*2^(1-HDR.Bits)./(HDR.Gain*ChannelGain);
    elseif HDR.Version == 103,
      HDR.Bits = tmp(1);
      ChannelGain = tmp(2:65);
      HDR.PhysMax = tmp(66:67)*[1;256]
      HDR.Cal = 5000*2^(1-HDR.Bits)./(HDR.Gain*ChannelGain);
    end;
    HDR.DigMax(1:HDR.NS) = 2^(HDR.Bits-1)-1;
    HDR.DigMin(1:HDR.NS) = -(2^(HDR.Bits-1));
    HDR.PhysMax = HDR.DigMax * HDR.Cal;
    HDR.PhysMin = HDR.DigMin * HDR.Cal;
    HDR.PhysDim = 'mV';
    HDR.Calib = sparse(2:HDR.NS+1,1:HDR.NS,HDR.Cal);
    
    HDR.AS.bpb = 2*HDR.NS;
    HDR.GDFTYP = 3;
    HDR.SPR = (HDR.FILE.size-HDR.HeadLen)/HDR.AS.bpb;
    HDR.NRec = 1;
    HDR.AS.endpos = HDR.SPR;
    status = fseek(HDR.FILE.FID,HDR.HeadLen,'bof');
    HDR.FILE.POS = 0;
    HDR.FILE.OPEN = 1;
  end;