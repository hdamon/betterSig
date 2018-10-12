function [HDR, immediateReturn] = PLEXON(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 if any(HDR.FILE.PERMISSION=='r'),
    fprintf(HDR.FILE.stderr,'Warning:  SOPEN (PLX) is still in testing phase.\n');
    
    HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
    if HDR.FILE.FID<0,
      return;
    end
    H1 = fread(HDR.FILE.FID,2,'int32');
    HDR.magic = H1(1);
    HDR.Version = H1(2);
    HDR.PLX.comment = fread(HDR.FILE.FID,128,'uint8');
    H1 = fread(HDR.FILE.FID,14,'int32');
    HDR.PLX.ADFrequency = H1(1);
    HDR.PLX.NumDSPChannels = H1(2);
    HDR.PLX.NumEventChannels = H1(3);
    HDR.PLX.NumSlowChannels = H1(4);
    HDR.PLX.NumPointsWave = H1(5);
    HDR.PLX.NumPointsPreThr = H1(6);
    %HDR.NS = H1(2);
    HDR.EVENT.N = H1(3);
    HDR.NS = H1(4);
    HDR.PLX.wavlen = H1(5);
    HDR.TimeOffset = H1(6);
    HDR.T0 = H1(7:12)';
    HDR.PLX.fastread = H1(13);
    HDR.PLX.WaveFormFreq = H1(14);
    HDR.PLX.LastTimeStamp = fread(HDR.FILE.FID,1,'double');
    H1 = fread(HDR.FILE.FID,4,'uint8');
    H2 = fread(HDR.FILE.FID,3,'uint16');
    if HDR.Version>=103,
      HDR.PLX.Trodalness          = H1(1);
      HDR.PLX.DataTrodalness      = H1(2);
      HDR.PLX.BitsPerSpikeSample  = H1(3);
      HDR.PLX.BitsPerSlowSample   = H1(4);
      HDR.PLX.SpikeMaxMagnitudeMV = H2(1);
      HDR.PLX.SlowMaxMagnitudeMV  = H2(2);
    end;
    if HDR.Version>=105,
      HDR.PLX.SpikePreAmpGain     = H2(3);
    end;
    H1 = fread(HDR.FILE.FID,46,'uint8');
    
    HDR.PLX.tscount = fread(HDR.FILE.FID,[5,130],'int32');
    HDR.PLX.wfcount = fread(HDR.FILE.FID,[5,130],'int32');
    HDR.PLX.evcount = fread(HDR.FILE.FID,[1,300],'int32');
    HDR.PLX.adcount = fread(HDR.FILE.FID,[1,212],'int32');
    
    %HDR.PLX.dspHeader = fread(HDR.FILE.FID,[1020,HDR.NS],'uint8');
    for k = 1:HDR.PLX.NumDSPChannels,
      tmp = fread(HDR.FILE.FID,[32,2],'uint8');
      HDR.Spike.Name(k,:) 	 = tmp(:,1)';
      HDR.Spike.SIGName(k,:) 	 = tmp(:,2)';
      tmp = fread(HDR.FILE.FID,9,'int32');
      HDR.Spike.Channel(k) 	 = tmp(1);
      HDR.Spike.WFRate(k) 	 = tmp(2);
      HDR.Spike.SIG(k) 	 = tmp(3);
      HDR.Spike.Ref(k)         = tmp(4);
      HDR.Spike.Gain(k)        = tmp(5);
      HDR.Spike.Filter(k)      = tmp(6);
      HDR.Spike.Threshold(k)   = tmp(7);
      HDR.Spike.Method(k)      = tmp(8);
      HDR.Spike.NUnits(k)      = tmp(9);
      HDR.Spike.template(k,:,:) = fread(HDR.FILE.FID,[5,64],'int16');
      tmp = fread(HDR.FILE.FID,6,'int32');
      HDR.Spike.Fit(k,:)       = tmp(1:5)';
      HDR.Spike.SortWidth(k)   = tmp(6);
      HDR.Spike.Boxes(k,:,:,:) = reshape(fread(HDR.FILE.FID,[40],'int16'),[5,2,4]);
      HDR.Spike.SortBeg(k)     = fread(HDR.FILE.FID,1,'int32');
      HDR.Spike.Comment(k,:)   = fread(HDR.FILE.FID,[1,128],'uint8');
      tmp = fread(HDR.FILE.FID,11,'int32');
    end;
    HDR.Spike.Name = deblank(char(HDR.Spike.Name));
    HDR.Spike.Comment = deblank(char(HDR.Spike.Comment));
    for k = 1:HDR.PLX.NumEventChannels,
      HDR.EV.Name(k,:)         = fread(HDR.FILE.FID,[1,32],'uint8');
      HDR.EV.Channel(k)        = fread(HDR.FILE.FID,1,'int32');
      HDR.EV.Comment(k,:)      = fread(HDR.FILE.FID,[1,128],'uint8');
      tmp = fread(HDR.FILE.FID,33,'int32');
    end;
    HDR.EV.Name = deblank(char(HDR.EV.Name));
    HDR.EV.Comment = deblank(char(HDR.EV.Comment));
    for k = 1:HDR.PLX.NumSlowChannels,
      HDR.Cont.Name(k,:) = fread(HDR.FILE.FID,[1,32],'uint8');
      tmp = fread(HDR.FILE.FID,6,'int32');
      HDR.Cont.Channel(k)      = tmp(1)+1;
      HDR.Cont.ADfreq(k)       = tmp(2);
      HDR.Cont.Gain(k)         = tmp(3);
      HDR.Cont.Enabled(k)      = tmp(4);
      HDR.Cont.PreAmpGain(k)   = tmp(5);
      HDR.Cont.SpikeChannel(k) = tmp(6);
      HDR.Cont.Comment(k,:) 	 = fread(HDR.FILE.FID,[1,128],'uint8');
      tmp = fread(HDR.FILE.FID,28,'int32');
    end;
    HDR.Cont.Name = deblank(char(HDR.Cont.Name));
    HDR.Cont.Comment = deblank(char(HDR.Cont.Comment));
    
    HDR.AS.SampleRate = HDR.Cont.ADfreq;
    HDR.HeadLen = ftell(HDR.FILE.FID);
    HDR.EVENT.SampleRate = HDR.PLX.ADFrequency;
    HDR.PhysDim = 'mV';
    if HDR.Version<=102,
      HDR.Spike.Cal = 3./(2048*HDR.Spike.Gain);
    elseif HDR.Version<105
      HDR.Spike.Cal = HDR.PLX.SpikeMaxMagnitudeMV*2.^(-HDR.PLX.BitsPerSpikeSample)./(500*HDR.Spike.Gain);
    else
      HDR.Spike.Cal = HDR.PLX.SpikeMaxMagnitudeMV*2.^(1-HDR.PLX.BitsPerSpikeSample)./(HDR.Spike.Gain*HDR.PLX.SpikePreAmpGain);
    end;
    if HDR.Version<=101,
      HDR.Cal = 5./(2048*HDR.Cont.Gain);
    elseif HDR.Version<=102,
      HDR.Cal = 5000./(2048*HDR.Cont.Gain.*HDR.Cont.PreAmpGain);
    else
      HDR.Cal = HDR.PLX.SpikeMaxMagnitudeMV*2^[1-HDR.PLX.BitsPerSlowSample]./(HDR.Cont.Gain.*HDR.Cont.PreAmpGain);
    end;
    
    % transfrom into native format
    HDR.Label = HDR.Cont.Name;
    HDR.NRec = 1;
    HDR.SPR = max(HDR.PLX.adcount);
    HDR.Calib = sparse(2:HDR.NS+1,1:HDR.NS,HDR.Cal);
    HDR.SampleRate = 1;
    for k=1:HDR.NS,
      HDR.SampleRate = lcm(HDR.SampleRate,HDR.AS.SampleRate(k));
    end;
    HDR.FILE.POS = 0;
    HDR.FILE.OPEN = 1;
    
    CH = find(HDR.PLX.adcount>0);
    if isempty(ReRefMx) && any(CH) && (max(CH)<150),
      HDR.NS = max(CH);
      HDR.Label = HDR.Label(1:HDR.NS,:);
    end;
  end;