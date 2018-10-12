function [HDR, immediateReturn] = EMBLA(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 fn = dir(fullfile(HDR.FILE.Path,'*.ebm'));
  HDR.NS = 0;
  k = 0;
  HDR.SPR = 1;
  HDR.NRec = 1;
  for k1 = 1:length(fn),
    [p,f,e]= fileparts(fn(k1).name);
    fid = fopen(fullfile(HDR.FILE.Path,fn(k1).name),'rb','ieee-le');
    [ss,c] = fread(fid,[1,48],'uint8=>char');
    if strncmp(ss,'Embla data file',15) && (c==48),
      tag = fread(fid,[1],'uint32');
      Embla=[];
      k = k+1;
      while ~feof(fid),
        siz = fread(fid,[1],'uint32');
        switch tag,
          case 32
            Embla.Data = fread(fid,[siz/2,1],'int16');
            HDR.AS.SPR(1,k)=length(Embla.Data);
            HDR.SPR = lcm(HDR.SPR,HDR.AS.SPR(1,k));
          case 48
            Embla.DateGuid = fread(fid,[1,siz],'uint8');
          case 64
            Embla.DateRecGuid = fread(fid,[1,siz],'uint8');
          case 128
            EmblaVersion = fread(fid,[1,siz/2],'uint16');
          case 129
            Embla.Header = fread(fid,[1,siz],'uint8');
          case 132
            t0 = fread(fid,[1,siz],'uint8');
            Embla.Time = t0;
            T0 = t0(2:7);
            T0(1) = t0(1)+t0(2)*256;
            T0(6) = t0(7)+t0(8)/100;
            T0 = datenum(T0);
            Embla.T0 = T0; %datevec(T0);
            if (k==1)
              HDR.T0 = T0;
            elseif abs(HDR.T0-T0) > 2/(24*3600),
              fprintf(HDR.FILE.stderr,'Warning SOPEN(EMBLA): start time differ between channels\n');
            end;
          case 133
            Embla.Channel = fread(fid,[1,siz],'uint8');
          case 134
            %Embla.SamplingRate = fread(fid,[1,siz/4],'uint32');
            HDR.AS.SampleRate(1,k) = fread(fid,[1,siz/4],'uint32')/1000;
          case 135
            u = fread(fid,[1,siz/4],'uint32');
            if (u~=1) u=u*1e-9; end;
            HDR.Cal(k) = u;
          case 136
            Embla.SessionCount = fread(fid,[1,siz],'uint8');
          case 137
            %Embla.DoubleSampleingRate = fread(fid,[1,siz/8],'double');
            HDR.AS.SampleRate(1,k) = fread(fid,[1,siz/8],'double');
          case 138
            Embla.RateCorrection = fread(fid,[1,siz/8],'double');
          case 139
            Embla.RawRange = fread(fid,[1,siz/2],'int16');
          case 140
            Embla.TransformRange = fread(fid,[1,siz/2],'int16');
          case 141
            Embla.Channel32 = fread(fid,[1,siz],'uint8');
          case 144
            %Embla.ChannelName = fread(fid,[1,siz],'uint8=>char');
            HDR.Label{k} = deblank(fread(fid,[1,siz],'uint8=>char'));
          case 149
            Embla.DataMask16bit = fread(fid,[1,siz/2],'int16');
          case 150
            Embla.SignedData = fread(fid,[1,siz],'uint8');
          case 152
            Embla.CalibrationFunction = fread(fid,[1,siz],'uint8=>char');
          case 153
            %Embla.CalibrationUnit = fread(fid,[1,siz],'uint8=>char');
            HDR.PhysDim{k} = deblank(fread(fid,[1,siz],'uint8=>char'));
            %HDR.PhysDimCode(k) = physicalunits(fread(fid,[1,siz],'uint8=>char'));
          case 154
            Embla.CalibrationPoint = fread(fid,[1,siz],'uint8');
          case 160
            Embla.CalibrationEvent = fread(fid,[1,siz],'uint8');
          case 192
            Embla.DeviceSerialNumber = fread(fid,[1,siz],'uint8=>char');
          case 193
            Embla.DeviceType = fread(fid,[1,siz],'uint8=>char');
          case 208
            Embla.SubjectName = fread(fid,[1,siz],'uint8=>char');
          case 209
            Embla.SubjectID = fread(fid,[1,siz],'uint8=>char');
          case 210
            Embla.SubjectGroup = fread(fid,[1,siz],'uint8=>char');
          case 211
            Embla.SubjectAttendant = fread(fid,[1,siz],'uint8=>char');
          case 224
            Embla.FilterSettings = fread(fid,[1,siz],'uint8');
          case hex2dec('020000A0')
            Embla.SensorSignalType = fread(fid,[1,siz],'uint8=>char');
          case hex2dec('03000070')
            Embla.InputReference = fread(fid,[1,siz],'uint8=>char');
          case hex2dec('03000072')
            Embla.InputMainType = fread(fid,[1,siz],'uint8=>char');
          case hex2dec('03000074')
            Embla.InputSubType = fread(fid,[1,siz],'uint8=>char');
          case hex2dec('03000080')
            Embla.InputComment = fread(fid,[1,siz],'uint8=>char');
          case hex2dec('04000020')
            Embla.WhatComment = fread(fid,[1,siz],'uint8=>char');
          otherwise
            fread(fid,[1,siz],'uint8=>char');
        end;
        tag = fread(fid,[1],'uint32');
      end;
      fclose(fid);
      HDR.Embla{k}=Embla;
    end;
  end;
  HDR.NS=k;
  HDR.Calib = sparse(2:HDR.NS+1,1:HDR.NS,HDR.Cal,HDR.NS+1,HDR.NS);
  HDR.Filter.Notch = repmat(NaN,1,HDR.NS);
  HDR.Filter.HighPass = repmat(NaN,1,HDR.NS);
  HDR.Filter.LowPass = repmat(NaN,1,HDR.NS);
  HDR.GDFTYP = repmat(3,1,HDR.NS);
  HDR.DigMax = repmat(2^15-1,1,HDR.NS);
  HDR.DigMin = repmat(-2^15,1,HDR.NS);
  HDR.PhysMax = HDR.DigMax.*HDR.Cal(:)';
  HDR.PhysMin = HDR.DigMin.*HDR.Cal(:)';
  HDR.THRESHOLD = [HDR.DigMin(:),HDR.DigMax(:)];
  Duration = mean(HDR.AS.SPR./HDR.AS.SampleRate);
  HDR.SampleRate = HDR.SPR/Duration;
  
  % compute time intervals for each channel, and LeastCommonMultiple SampleRate
  t = repmat(NaN,HDR.NS,2);
  Fs = 1;
  for k = 1:HDR.NS,
    t(k,1:2) = (datenum(HDR.Embla{k}.T0)-HDR.T0)*24*3600+[1,length(HDR.Embla{k}.Data)]/HDR.AS.SampleRate(k);
    Fs = lcm(Fs,HDR.AS.SampleRate(k));
  end;
  T = [min(t(:,1)),max(t(:,2))];
  HDR.data = repmat(NaN,floor(diff(T)/Fs+1),HDR.NS);
  HDR.T0 = HDR.T0+T(1);
  HDR.SampleRate = Fs;
  t = t-T(1);
  for k = 1:HDR.NS,
    d = rs(HDR.Embla{k}.Data,HDR.AS.SampleRate(k),Fs);
    HDR.data(floor(t(k,1)*Fs)+[1:length(d)],k)=d;
  end;
  HDR.Embla = [];
  HDR.TYPE = 'native';
  HDR.FILE.POS = 0;