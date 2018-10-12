function [HDR, immediateReturn] = BCI2003_III(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value



 % BCI competition 2003, dataset III (Graz)
  tmp = load(HDR.FileName);
  HDR.data = [tmp*50;repmat(NaN,100,size(tmp,2))];
  if strcmp(HDR.FILE.Name,'x_train'),
    tmp = fullfile(HDR.FILE.Path,'y_train');
    if exist(tmp,'file')
      HDR.Classlabel = load(tmp);
    end;
  elseif strcmp(HDR.FILE.Name,'x_test'),
    HDR.Classlabel = repmat(NaN,140,1);
  end;
  
  %elseif isfield(tmp,'x_train') && isfield(tmp,'y_train') && isfield(tmp,'x_test');
  HDR.INFO  = 'BCI competition 2003, dataset 3 (Graz)';
  HDR.Label = {'C3a-C3p'; 'Cza-Czp'; 'C4a-C4p'};
  HDR.SampleRate = 128;
  HDR.NRec = length(HDR.Classlabel);
  HDR.FLAG.TRIGGERED = 1;
  HDR.Dur = 9;
  HDR.NS  = 3;
  HDR.SPR = size(HDR.data,1);
  
  sz = [HDR.NS, HDR.SPR, HDR.NRec];
  HDR.data = reshape(permute(reshape(HDR.data,sz([2,1,3])),[2,1,3]),sz(1),sz(2)*sz(3))';
  HDR.TYPE = 'native';
  HDR.FILE.POS = 0;
  
  
elseif strncmp(HDR.TYPE,'MAT',3),
  status = warning;
  warning('off');
  tmp = whos('-file',HDR.FileName);
  tmp = load('-mat',HDR.FileName);
  warning(status);
  
  HDR.FILE.FID = 0;
  flag.bci2002a = isfield(tmp,'x') && isfield(tmp,'y') && isfield(tmp,'z') && isfield(tmp,'fs') && isfield(tmp,'elab');
  if flag.bci2002a,
    flag.bci2002a = all(size(tmp.y) == [1501,27,516]);
  end;
  flag.tfm = isfield(tmp,'HRV') || isfield(tmp,'BPV') || isfield(tmp,'BPVsBP');    % TFM BeatToBeat Matlab export
  if flag.tfm && isfield(tmp,'HRV'),
    flag.tfm = (isfield(tmp.HRV,'HF_RRI') && isfield(tmp.HRV,'LF_RRI') && isfield(tmp.HRV,'PSD_RRI') && isfield(tmp.HRV,'VLF_RRI'));
  end
  if flag.tfm && isfield(tmp,'BPV'),
    flag.tfm = flag.tfm + 2*((isfield(tmp.BPV,'HF_dBP') && isfield(tmp.BPV,'LF_dBP') && isfield(tmp.BPV,'PSD_dBP') && isfield(tmp.BPV,'VLF_dBP')));
  end
  if flag.tfm && isfield(tmp,'BPVsBP'),
    flag.tfm = flag.tfm + 4*((isfield(tmp.BPVsBP,'HF_sBP') && isfield(tmp.BPVsBP,'LF_sBP') && isfield(tmp.BPVsBP,'PSD_sBP') && isfield(tmp.BPVsBP,'VLF_sBP')));
  end;
  flag.bbci = isfield(tmp,'bbci') && isfield(tmp,'nfo');
  flag.bcic2008_1 = isfield(tmp,'cnt') && isfield(tmp,'nfo') && isfield(tmp,'mrk');
  flag.bcic2008_3 = isfield(tmp,'test_data') && isfield(tmp,'training_data') && isfield(tmp,'Info');
  flag.bcic2008_4 = isfield(tmp,'test_data') && isfield(tmp,'train_data') && isfield(tmp,'train_dg');
  if flag.bbci
    flag.bbci = isfield(tmp,'mnt') && isfield(tmp,'mrk') && isfield(tmp,'dat') && isfield(tmp,'fs_orig') && isfield(tmp,'mrk_orig');
    if ~(flag.bbci),
      warning('identification of bbci data may be not correct');
    end;
  end;
  flag.fieldtrip = isfield(tmp,'data');
  if flag.fieldtrip,
    flag.fieldtrip = isfield(tmp.data,'cfg') && isfield(tmp.data,'hdr') && isfield(tmp.data,'label') && isfield(tmp.data,'fsample');
  end;
  flag.brainvision = isfield(tmp,'Channels') && isfield(tmp,'ChannelCount') && isfield(tmp,'Markers') && isfield(tmp,'MarkerCount') && isfield(tmp,'SampleRate') && isfield(tmp,'SegmentCount') && isfield(tmp,'t');
  
  if isfield(tmp,'HDR'),
    H = HDR;
    HDR = tmp.HDR;
    HDR.FILE = H.FILE;
    HDR.FileName = H.FileName;
    if isfield(HDR,'data');
      HDR.TYPE = 'native';
    end;
    if ~isfield(HDR,'FLAG')
      HDR.FLAG.OVERFLOWDETECTION=0;
    end;
    if ~isfield(HDR.FLAG,'UCAL')
      HDR.FLAG.UCAL = 0;
    end;
    if ~isfield(HDR.FLAG,'TRIGGERED')
      HDR.FLAG.TRIGGERED=0;
    end;
    if ~isfield(HDR,'SampleRate')
      HDR.SampleRate = NaN;
    end;
    if ~isfield(HDR,'EVENT')
      HDR.EVENT.POS = [];
      HDR.EVENT.TYP = [];
      HDR.EVENT.CHN = [];
      HDR.EVENT.DUR = [];
    end;
    if ~isfield(HDR,'PhysDim') && ~isfield(HDR,'PhysDimCode')
      HDR.PhysDimCode = zeros(HDR.NS,1);
    end;
    
  elseif flag.brainvision,
    %% BrainVision Matlab export
    HDR.SPR = length(tmp.t);
    HDR.NS  = tmp.ChannelCount;
    HDR.SampleRate = tmp.SampleRate;
    HDR.NRec= tmp.SegmentCount;
    HDR.Label = {tmp.Channels.Name}';
    HDR.data  = zeros(HDR.SPR,HDR.NS);
    R=[tmp.Channels.Radius]'; Theta = [tmp.Channels.Theta]'*pi/180; Phi = [tmp.Channels.Phi]'*pi/180;
    HDR.ELEC.XYZ = R(:,ones(1,3)).*[sin(Theta).*cos(Phi),sin(Theta).*sin(Phi),cos(Theta)];
    HDR.PhysDimCode = repmat(4275,1,HDR.NS); % uV
    HDR.Calib = sparse(2:HDR.NS+1,1:HDR.NS,1);
    HDR.GDFTYP = repmat(17,1,HDR.NS);
    for k = 1:HDR.NS,
      HDR.data(:,k) = getfield(tmp,tmp.Channels(k).Name);
    end;
    
    ch = strmatch('Status',HDR.Label);
    if 0,ch,
      HDR.BDF.ANNONS = round(2^24 + HDR.data(:,ch));
      HDR = bdf2biosig_events(HDR, FLAG.BDF.status2event);
    else
      % HDR.EVENT.N = tmp.MarkerCount;
      HDR.EVENT.POS = [tmp.Markers(:).Position]';
      HDR.EVENT.DUR = [tmp.Markers(:).Points]';
      HDR.EVENT.CHN = [tmp.Markers(:).ChannelNumber]';
      HDR.EVENT.TYP = zeros(size(HDR.EVENT.POS));
      ix = strmatch('New Segment',{tmp.Markers.Type}');
      HDR.EVENT.TYP(ix) = hex2dec('7ffe');
      ix = HDR.EVENT.TYP==0;
      [HDR.EVENT.CodeDesc, CodeIndex, HDR.EVENT.TYP(ix)] = unique({tmp.Markers(ix).Description});
    end;
    HDR.TYPE = 'native';
    clear tmp;
    
  elseif flag.bcic2008_1,	%isfield(tmp,'cnt') && isfield(tmp,'mrk') && isfield(tmp,'nfo')
    HDR.SampleRate = tmp.nfo.fs;
    HDR.NRec = 1;
    HDR.Label = tmp.nfo.clab';
    HDR.EVENT.POS = tmp.mrk.pos';
    if isfield(tmp.nfo,'className')
      HDR.EVENT.CodeDesc = tmp.nfo.className;
    end;
    if isfield(tmp.mrk,'y')
      [u,i,HDR.Classlabel] = unique(tmp.mrk.y);
      HDR.EVENT.TYP = HDR.Classlabel(:);
      HDR.TRIG = tmp.mrk.pos';
    elseif isfield(tmp.mrk,'toe')
      HDR.EVENT.TYP = tmp.mrk.toe';
      HDR.Classlabel = tmp.mrk.toe;
    else
      HDR.EVENT.TYP = zeros(size(HDR.EVENT.POS));
    end;
    
    HDR.data  = tmp.cnt;
    [HDR.SPR,HDR.NS] = size(HDR.data);
    HDR.Calib = sparse(2:HDR.NS+1, 1:HDR.NS, 0.1);
    HDR.PhysDimCode = repmat(4275,HDR.NS,1);	% uV
    
    if (CHAN==0), CHAN=1:HDR.NS; end;
    [tmp0,HDR.THRESHOLD,tmp1,HDR.bits,HDR.GDFTYP] = gdfdatatype(class(HDR.data));
    HDR.THRESHOLD = repmat(HDR.THRESHOLD,HDR.NS,1);
    HDR.TYPE  = 'native';
    
    
  elseif flag.bcic2008_3,
    HDR.NS = 10;
    HDR.Label = tmp.Info.MEGChannelPosition;
    HDR.Filter.LowPass = 100;
    HDR.Filter.HighPass = 0.3;
    HDR.SampleRate = 400;
    HDR.data = cat(1,cat(1,tmp.training_data{:}),tmp.test_data);
    [N,HDR.SPR,HDR.NS]=size(HDR.data);
    HDR.Classlabel = [ceil((1:160)'/40);repmat(NaN,size(tmp.test_data,1),1)];
    HDR.TRIG = [0:N-1]*HDR.SPR+1;
    %HDR.data = reshape(permute(HDR.data,[2,1,3]),
    return;
    
    
  elseif flag.bcic2008_4,
    HDR.SampleRate = 1000;
    HDR.NRec = 1;
    HDR.NS   = 62+5;
    HDR.data = [tmp.train_data,tmp.train_dg;repmat(NaN,1000,HDR.NS);tmp.test_data,repmat(NaN,size(tmp.test_data,1),5)];
    [HDR.SPR,HDR.NS] = size(HDR.data);
    HDR.Label = cellstr(num2str([1:HDR.NS]'));
    
    HDR.Calib = sparse(2:HDR.NS+1, 1:HDR.NS, 1);
    HDR.PhysDimCode = repmat(0,HDR.NS,1);	% unknown
    HDR.TYPE  = 'native';
    
    
  elseif isfield(tmp,'mnt') && isfield(tmp,'mrk') && isfield(tmp,'cnt')
    HDR.SampleRate = tmp.cnt.fs;
    HDR.NRec = 1;
    HDR.Label = tmp.cnt.clab';
    HDR.EVENT.POS = tmp.mrk.pos';
    if isfield(tmp.mrk,'className')
      HDR.EVENT.CodeDesc = tmp.mrk.className;
    end;
    if isfield(tmp.mrk,'y')
      [t,HDR.Classlabel] = max(tmp.mrk.y,[],1);
      HDR.EVENT.TYP = HDR.Classlabel(:);
      HDR.TRIG = tmp.mrk.pos';
    elseif isfield(tmp.mrk,'toe')
      HDR.EVENT.TYP = tmp.mrk.toe';
      HDR.Classlabel = tmp.mrk.toe;
    else
      HDR.EVENT.TYP = zeros(size(HDR.EVENT.POS));
    end;
    HDR.data  = tmp.cnt.x;
    [HDR.SPR,HDR.NS] = size(HDR.data);
    if (CHAN==0), CHAN=1:HDR.NS; end;
    [tmp0,HDR.THRESHOLD,tmp1,HDR.bits,HDR.GDFTYP] = gdfdatatype(class(HDR.data));
    HDR.THRESHOLD = repmat(HDR.THRESHOLD,HDR.NS,1);
    HDR.TYPE  = 'native';
    HDR.PhysDimCode = repmat(4275,HDR.NS,1);
    HDR.PhysDim = repmat('uV',HDR.NS,1);
    
    if isfield(tmp.cnt,'hdr')
      % BNI header
      HDR.H1 = tmp.cnt.hdr;
      HDR = bni2hdr(HDR,CHAN,MODE,ReRefMx);
    end;
    
    
  elseif flag.bbci,
    HDR.SampleRate = tmp.nfo.fs;
    HDR.NRec = tmp.nfo.nEpochs;
    HDR.SPR = tmp.nfo.T;
    HDR.Label = tmp.dat.clab';
    if isfield(tmp,'mrk_orig'),
      HDR.EVENT.POS = round([tmp.mrk_orig.pos]./[tmp.mrk_orig.fs]*tmp.mrk.fs)';
      % HDR.EVENT.Desc = {tmp.mrk_orig.desc};
      % HDR.EVENT.TYP = zeros(size(HDR.EVENT.POS));
      [HDR.EVENT.CodeDesc, CodeIndex, HDR.EVENT.TYP] = unique({tmp.mrk_orig.desc});
      HDR.EVENT.CHN = zeros(size(HDR.EVENT.POS));
      HDR.EVENT.DUR = ones(size(HDR.EVENT.POS));
      HDR = bv2biosig_events(HDR,CHAN,MODE,ReRefMx);
    elseif isfield(tmp,'mrk');
      HDR.EVENT.POS = tmp.mrk.pos';
      HDR.EVENT.TYP = tmp.mrk.toe';
      if isfield(tmp.mrk,'toe')
        HDR.EVENT.TYP = tmp.mrk.toe';
        HDR.Classlabel = tmp.mrk.toe;
      else
        HDR.EVENT.TYP = zeros(size(HDR.EVENT.POS));
      end;
    end;
    HDR.NS = length(HDR.Label);
    HDR.Cal = tmp.dat.resolution;
    if (CHAN==0), CHAN=1:HDR.NS; end;
    %        	HDR.data = repmat(NaN,HDR.SPR*HDR.NRec,HDR.NS);
    for k = 1:length(CHAN),
      HDR.data(:,CHAN(k)) = getfield(tmp,['ch',int2str(CHAN(k))]);
    end
    [tmp0,HDR.THRESHOLD,tmp1,HDR.bits,HDR.GDFTYP]=gdfdatatype(class(tmp.ch1));
    HDR.THRESHOLD = repmat(HDR.THRESHOLD,HDR.NS,1);
    
    HDR.TYPE = 'native';
    HDR.Calib = sparse(2:HDR.NS+1,1:HDR.NS,HDR.Cal);
    HDR.PhysDimCode = repmat(4275,HDR.NS,1);
    HDR.PhysDim = repmat('uV',HDR.NS,1);
    
    
  elseif flag.bci2002a,
    [HDR.SPR, HDR.NS, HDR.NRec] = size(tmp.y);
    HDR.Label = tmp.elab;
    HDR.SampleRate = tmp.fs;
    HDR.data  = reshape(permute(tmp.y,[1,3,2]),[HDR.SPR*HDR.NRec,HDR.NS]);
    HDR.Transducer = repmat({'Ag/AgCl electrodes'},3,1);
    HDR.Filter.Lowpass = 200;
    HDR.Filter.HighPass = 0.05;
    HDR.TYPE  = 'native';
    
    HDR.FLAG.TRIGGERED = logical(1);
    HDR.EVENT.POS  = [0:HDR.NRec-1]'*HDR.SPR;
    HDR.EVENT.TYP  = [(tmp.z==-1)*hex2dec('0301') + (tmp.z==1)*hex2dec('0302') + (tmp.z==0)*hex2dec('030f')]';
    HDR.EVENT.POS(isnan(tmp.z)) = [];
    HDR.EVENT.TYP(isnan(tmp.z)) = [];
    HDR.Classlabel = mod(HDR.EVENT.TYP,256);
    HDR.Classlabel(HDR.Classlabel==15) = NaN; % unknown/undefined cue
    HDR.TRIG = HDR.EVENT.POS;
    
    
  elseif isfield(tmp,'y'),		% Guger, Mueller, Scherer
    HDR.NS = size(tmp.y,2);
    HDR.NRec = 1;
    if ~isfield(tmp,'SampleRate')
      %fprintf(HDR.FILE.stderr,['Samplerate not known in ',HDR.FileName,'. 125Hz is chosen']);
      HDR.SampleRate=125;
    else
      HDR.SampleRate=tmp.SampleRate;
    end;
    fprintf(HDR.FILE.stderr,'Sensitivity not known in %s.\n',HDR.FileName);
    HDR.data = tmp.y;
    HDR.TYPE = 'native';
    
    
  elseif ( isfield(tmp,'cnt') || isfield(tmp,'X') ) && isfield(tmp,'nfo')
    if isfield(tmp,'cnt')
      HDR.data = tmp.cnt;
      [HDR.SPR,HDR.NS] = size(tmp.cnt);
      HDR.INFO='BCI competition 2005, dataset IV (Berlin)';
      HDR.Filter.LowPass = 0.05;
      HDR.Filter.HighPass = 200;
      HDR.Cal   = 0.1;
      HDR.Calib = sparse(2:HDR.NS+1,1:HDR.NS,.1);
    elseif isfield(tmp,'X'),
      HDR.data = tmp.X;
      [HDR.SPR,HDR.NS] = size(tmp.X);
      HDR.INFO='BCI competition 2005, dataset V (IDIAP)';
      HDR.Filter.LowPass = 0;
      HDR.Filter.HighPass = 256;
      if isfield(tmp,'Y'),
        HDR.Classlabel = tmp.Y(:);
      else
        HDR.Classlabel = repmat(NaN,size(tmp.X,1),1);
      end;
      HDR.Cal   = 1;
    else
      
    end;
    
    HDR.PhysDim = 'uV';
    HDR.SampleRate = tmp.nfo.fs;
    %HDR.Dur = HDR.SPR/HDR.SampleRate;
    if isfield(tmp,'mrk')
      HDR.TRIG  = tmp.mrk.pos;
      HDR.EVENT.POS = tmp.mrk.pos(:);
      HDR.EVENT.TYP = zeros(size(HDR.EVENT.POS));
      HDR.EVENT.CHN = zeros(size(HDR.EVENT.POS));
      if ~isempty(strfind(HDR.INFO,'Berlin')),cuelen=3.5;
      elseif ~isempty(strfind(HDR.INFO,'IDIAP')),cuelen=20;
      end;
      HDR.EVENT.DUR = repmat(cuelen*HDR.SampleRate,size(HDR.EVENT.POS));
      if isfield(tmp.mrk,'y'),
        HDR.Classlabel = tmp.mrk.y;
      else
        HDR.Classlabel = repmat(NaN,size(HDR.TRIG));
      end;
      if isfield(tmp.mrk,'className'),
        HDR.EVENT.TeegType = tmp.mrk.className;
        HDR.EVENT.TYP(isnan(HDR.Classlabel)) = hex2dec('030f');  % unknown/undefined
        ix = strmatch('left',tmp.mrk.className);
        if ~isempty(ix),
          HDR.EVENT.TYP(HDR.Classlabel==ix) = hex2dec('0301');  % left
        end;
        ix = strmatch('right',tmp.mrk.className);
        if ~isempty(ix),
          HDR.EVENT.TYP(HDR.Classlabel==ix) = hex2dec('0302');  % right
        end;
        ix = strmatch('foot',tmp.mrk.className);
        if ~isempty(ix),
          HDR.EVENT.TYP(HDR.Classlabel==ix) = hex2dec('0303');  % foot
        end;
        ix = strmatch('tongue',tmp.mrk.className);
        if ~isempty(ix),
          HDR.EVENT.TYP(HDR.Classlabel==ix) = hex2dec('0304');  % tongue
        end;
      end;
    end;
    HDR.Label = tmp.nfo.clab';
    z2=sum([tmp.nfo.xpos,tmp.nfo.ypos].^2,2);
    HDR.ELEC.XYZ = [tmp.nfo.xpos,tmp.nfo.ypos,sqrt(max(z2)-z2)];
    HDR.NRec = 1;
    HDR.FILE.POS = 0;
    HDR.TYPE = 'native';
    clear tmp;
    
    
  elseif isfield(tmp,'Signal') && isfield(tmp,'Flashing') && isfield(tmp,'StimulusCode')
    HDR.INFO = 'BCI competition 2005, dataset II (Albany)';
    HDR.SampleRate = 240;
    HDR.Filter.LowPass   = 60;
    HDR.Filter.HighPass  = 0.1;
    [HDR.NRec,HDR.SPR,HDR.NS] = size(tmp.Signal);
    HDR.BCI2000.Flashing = tmp.Flashing;
    HDR.BCI2000.StimulusCode = tmp.StimulusCode;
    if isfield(tmp,'TargetChar')
      HDR.BCI2000.TargetChar = tmp.TargetChar;
    end;
    if isfield(tmp,'StimulusType')
      HDR.BCI2000.StimulusType = tmp.StimulusType;
    end;
    
    HDR.FILE.POS = 0;
    HDR.TYPE = 'native';
    HDR.data = reshape(tmp.Signal,[HDR.NRec*HDR.SPR, HDR.NS]);
    clear tmp;
    
    
  elseif isfield(tmp,'run') && isfield(tmp,'trial') && isfield(tmp,'sample') && isfield(tmp,'signal') && isfield(tmp,'TargetCode');
    HDR.INFO = 'BCI competition 2002/2003, dataset 2a (Albany)';
    HDR.SampleRate = 160;
    HDR.NRec = 1;
    [HDR.SPR,HDR.NS]=size(tmp.signal);
    HDR.data = tmp.signal;
    HDR.EVENT.POS = [0;find(diff(tmp.trial)>0)-1];
    HDR.EVENT.TYP = ones(length(HDR.EVENT.POS),1)*hex2dec('0300'); % trial onset;
    
    if 0,
      EVENT.POS = [find(diff(tmp.trial)>0);length(tmp.trial)];
      EVENT.TYP = ones(length(EVENT.POS),1)*hex2dec('8300'); % trial offset;
      HDR.EVENT.POS = [HDR.EVENT.POS; EVENT.POS];
      HDR.EVENT.TYP = [HDR.EVENT.TYP; EVENT.TYP];
      [HDR.EVENT.POS,ix]=sort(HDR.EVENT.POS);
      HDR.EVENT.TYP = HDR.EVENT.TYP(ix);
    end;
    
    HDR.EVENT.N = length(HDR.EVENT.POS);
    ix = find((tmp.TargetCode(1:end-1)==0) & (tmp.TargetCode(2:end)>0));
    HDR.Classlabel = tmp.TargetCode(ix+1);
    HDR.TYPE = 'native';
    
    
  elseif isfield(tmp,'runnr') && isfield(tmp,'trialnr') && isfield(tmp,'samplenr') && isfield(tmp,'signal') && isfield(tmp,'StimulusCode');
    HDR.INFO = 'BCI competition 2003, dataset 2b (Albany)';
    HDR.SampleRate = 240;
    HDR.NRec = 1;
    [HDR.SPR,HDR.NS]=size(tmp.signal);
    HDR.data = tmp.signal;
    HDR.EVENT.POS = [0;find(diff(tmp.trialnr)>0)-1];
    HDR.EVENT.TYP = ones(length(HDR.EVENT.POS),1)*hex2dec('0300'); % trial onset;
    
    if 0,
      EVENT.POS = [find(diff(tmp.trial)>0);length(tmp.trial)];
      EVENT.TYP = ones(length(EVENT.POS),1)*hex2dec('8300'); % trial offset;
      HDR.EVENT.POS = [HDR.EVENT.POS; EVENT.POS];
      HDR.EVENT.TYP = [HDR.EVENT.TYP; EVENT.TYP];
      [HDR.EVENT.POS,ix]=sort(HDR.EVENT.POS);
      HDR.EVENT.TYP = HDR.EVENT.TYP(ix);
    end;
    
    HDR.EVENT.N = length(HDR.EVENT.POS);
    ix = find((tmp.StimulusCode(1:end-1)==0) && (tmp.StimulusCode(2:end)>0));
    HDR.Classlabel = tmp.StimulusCode(ix+1);
    HDR.TYPE = 'native';
    
    
  elseif isfield(tmp,'clab') && isfield(tmp,'x_train') && isfield(tmp,'y_train') && isfield(tmp,'x_test');
    HDR.INFO  = 'BCI competition 2003, dataset 4 (Berlin)';
    HDR.Label = tmp.clab;
    HDR.Classlabel = [repmat(nan,size(tmp.x_test,3),1);tmp.y_train';repmat(nan,size(tmp.x_test,3),1)];
    HDR.NRec  = length(HDR.Classlabel);
    
    HDR.SampleRate = 1000;
    HDR.Dur = 0.5;
    HDR.NS  = size(tmp.x_test,2);
    HDR.SPR = HDR.SampleRate*HDR.Dur;
    HDR.FLAG.TRIGGERED = 1;
    sz = [HDR.NS,HDR.SPR,HDR.NRec];
    
    HDR.data = reshape(permute(cat(3,tmp.x_test,tmp.x_train,tmp.x_test),[2,1,3]),sz(1),sz(2)*sz(3))';
    HDR.TYPE = 'native';
    
  elseif isfield(tmp,'x_train') && isfield(tmp,'y_train') && isfield(tmp,'x_test');
    HDR.INFO  = 'BCI competition 2003, dataset 3 (Graz)';
    HDR.Label = {'C3a-C3p'; 'Cza-Czp'; 'C4a-C4p'};
    HDR.SampleRate = 128;
    HDR.Classlabel = [tmp.y_train-1; repmat(nan,size(tmp.x_test,3),1)];
    HDR.data = cat(3, tmp.x_test, tmp.x_train)*50;
    
    HDR.NRec = length(HDR.Classlabel);
    HDR.FLAG.TRIGGERED = 1;
    HDR.SampleRate = 128;
    HDR.Dur = 9;
    HDR.NS  = 3;
    HDR.SPR = HDR.SampleRate*HDR.Dur;
    
    sz = [HDR.NS, HDR.SPR, HDR.NRec];
    HDR.data = reshape(permute(HDR.data,[2,1,3]),sz(1),sz(2)*sz(3))';
    HDR.TYPE = 'native';
    
    
  elseif isfield(tmp,'RAW_SIGNALS')    % TFM RAW Matlab export
    HDR.Label = fieldnames(tmp.RAW_SIGNALS);
    HDR.NS = length(HDR.Label);
    HDR.SampleRate = 1000;
    ix  = repmat(NaN,1,HDR.NS);
    for k1 = 1:HDR.NS;
      s = getfield(tmp.RAW_SIGNALS,HDR.Label{k1});
      for k2 = 1:length(s);
        ix(k2,k1) = length(s{k2});
      end;
    end;
    DIV = sum(ix,1);
    HDR.TFM.DIV = round(max(DIV)./DIV);
    HDR.TFM.ix  = ix;
    
    HDR.data = repmat(NaN, max(HDR.TFM.DIV.*DIV), HDR.NS);
    for k1 = 1:HDR.NS;
      s = getfield(tmp.RAW_SIGNALS,HDR.Label{k1});
      s2= rs(cat(2,s{:})',1,HDR.TFM.DIV(k1));
      HDR.data(1:size(s2,1),k1) = s2;
    end;
    clear tmp s s2;
    HDR.EVENT.POS = cumsum(ix(:,min(find(HDR.TFM.DIV==1))));
    HDR.EVENT.TYP = repmat(1,size(HDR.EVENT.POS));
    HDR.TFM.SampleRate = HDR.SampleRate./HDR.TFM.DIV;
    HDR.TYPE  = 'native';
    HDR.NRec  = 1;
    
    
  elseif isfield(tmp,'BeatToBeat')    % TFM BeatToBeat Matlab export
    HDR.Label = fieldnames(tmp.BeatToBeat);
    HDR.NS = length(HDR.Label);
    HDR.SampleRate = NaN;
    ix = [];
    for k1 = 1:HDR.NS,
      tmp2 = getfield(tmp.BeatToBeat,HDR.Label{k1});
      HDR.data(:,k1)=cat(2,tmp2{:})';
      for k2 = 1:length(tmp2);
        if (k1==1),
          ix(k2) = length(tmp2{k2});
        elseif ix(k2) ~= length(tmp2{k2}),
          fprintf(2,'Warning TFM BeatToBeat Import: length (%i!=%i) of segment %i:%i does not fit \n',length(tmp2{k2}),ix(k2),k1,k2);
        end;
      end;
      if length(ix)~=length(tmp2)
        fprintf(2,'Warning TFM BeatToBeat Import: number of segments (%i!=%1) in channel %i do not fit \n',length(tmp2),length(ix),k1);
      end;
    end;
    HDR.EVENT.POS = [1;cumsum(ix(:))];
    HDR.EVENT.TYP = repmat(1,size(HDR.EVENT.POS));
    HDR.PhysDim = repmat({''},HDR.NS,1);
    HDR.NRec = 1;
    HDR.TYPE = 'native';
    
    
  elseif flag.tfm,   % other TFM BeatToBeat Matlab export
    HDR.NS = 0;
    HDR.Label = {};
    if bitand(flag.tfm,1)
      f = fieldnames(tmp.HRV);
      for k1 = 1:length(f),
        tmp2 = getfield(tmp.HRV,f{k1});
        HDR.data(:,HDR.NS + k1)=cat(2,tmp2{:})';
      end;
      HDR.Label = [HDR.Label;f];
      HDR.NS = HDR.NS + length(f);
    end;
    if bitand(flag.tfm,2)
      f = fieldnames(tmp.BPV);
      for k1 = 1:length(f),
        tmp2 = getfield(tmp.BPV,f{k1});
        HDR.data(:,HDR.NS + k1)=cat(2,tmp2{:})';
      end;
      HDR.Label = [HDR.Label;f];
      HDR.NS = HDR.NS + length(f);
    end;
    if bitand(flag.tfm,3)
      f = fieldnames(tmp.BPVsBP);
      for k1 = 1:length(f),
        tmp2 = getfield(tmp.BPVsBP,f{k1});
        HDR.data(:,HDR.NS + k1)=cat(2,tmp2{:})';
      end;
      HDR.Label = [HDR.Label;f];
      HDR.NS = HDR.NS + length(f);
    end;
    HDR.PhysDim = repmat({''},HDR.NS,1);
    HDR.NRec = 1;
    HDR.TYPE = 'native';
    
    
  elseif flag.fieldtrip,
    HDR.Label = tmp.data.label;
    if isfield(tmp.data,'fsample');
      HDR.SampleRate = tmp.data.fsample;
    else
      HDR.SampleRate = tmp.data.hdr.Fs;
    end;
    HDR.data = cat(2,tmp.data.trial{:})';
    [HDR.NRec,HDR.NS] = size(HDR.data);
    HDR.SPR = 1;
    HDR.DigMax = double(max(HDR.data));
    HDR.DigMin = double(min(HDR.data));
    HDR.PhysMax = HDR.DigMax;
    HDR.PhysMin = HDR.DigMin;
    HDR.Calib = sparse(2:HDR.NS+1,1:HDR.NS,1);
    HDR.PhysDimCode = zeros(HDR.NS,1);
    numtrials = length(tmp.data.trial);
    tlen = zeros(numtrials,1);
    for k=1:numtrials,
      tlen(k) = size(tmp.data.trial{k},2);
    end;
    HDR.EVENT.TYP = repmat(hex2dec('7ffe'),length(tmp.data.trial),1);
    HDR.EVENT.POS = 1+cumsum(tlen);
    HDR.EVENT.DUR = tlen;
    HDR.EVENT.CHN = zeros(numtrials,1);
    HDR.TYPE = 'native';
    HDR.FILE.POS = 0;
    
    fid = -1; % fopen(fullfile(HDR.FILE.Path,[HDR.FILE.Name,'.rej']),'r');
    if fid>0,
      %% FIXME: *.rej info not used.
      t = fread(fid,[1,inf],'uint8');
      fclose(fid);
      t = char(t);
      t(t=='-') = ' ';
      [n,v,t]=str2double(t);
    end;
    
    
  elseif isfield(tmp,'EEG');	% EEGLAB file format
    HDR.T0		= 0;
    HDR.SPR         = tmp.EEG.pnts;
    HDR.NS          = tmp.EEG.nbchan;
    HDR.NRec        = tmp.EEG.trials;
    HDR.SampleRate  = tmp.EEG.srate;
    if isfield(tmp.EEG.chanlocs,'X')
      HDR.ELEC.XYZ    = [[tmp.EEG.chanlocs.X]',[tmp.EEG.chanlocs.Y]',[tmp.EEG.chanlocs.Z]'];
    end;
    
    if isfield(tmp.EEG.chanlocs,'labels')
      HDR.Label       = {tmp.EEG.chanlocs.labels};
    else
      HDR.Label = cellstr([repmat('#',HDR.NS,1),int2str([1:HDR.NS]')]);
    end
    HDR.PhysDimCode = repmat(4275,HDR.NS,1); 	% uV
    
    if ischar(tmp.EEG.data) && exist(tmp.EEG.data,'file')
      fid = fopen(tmp.EEG.data,'r','ieee-le');
      HDR.data = fread(fid,[HDR.NS,HDR.SPR*HDR.NRec],'float32')';
      fclose(fid);
      HDR.GDFTYP = 16;
    elseif isnumeric(tmp.EEG.data)
      HDR.data = tmp.EEG.data';
      HDR.GDFTYP = 17;
    end;
    
    if isfield(HDR,'data'),
      HDR.data = reshape(permute(reshape(HDR.data,[HDR.SPR,HDR.NS,HDR.NRec]),[1,3,2]),[HDR.SPR*HDR.NRec,HDR.NS]);
      if isfield(HDR,'Label') && ~isempty(HDR.Label)
        HDR.BDF.Status.Channel = strmatch('Status',HDR.Label,'exact');
        if length(HDR.BDF.Status.Channel),
          HDR.BDF.ANNONS = uint32(HDR.data(:,HDR.BDF.Status.Channel));
        end;
      end;
    end;
    
    if isfield(tmp.EEG,'event'),
      HDR.EVENT.SampleRate = HDR.SampleRate;
      HDR.EVENT.POS = round([tmp.EEG.event.latency]');
      [HDR.EVENT.CodeDesc, tmp, HDR.EVENT.TYP] = unique({tmp.EEG.event.type}');
    elseif isfield(HDR,'BDF') && isfield(HDR.BDF,'ANNONS'),
      HDR = bdf2biosig_events(HDR,FLAG.BDF.status2event);
    else
      % trial onset and offset event
      HDR.EVENT.POS = [ [0:HDR.NRec-1]'*HDR.SPR+1; [1:HDR.NRec]'*HDR.SPR ];
      HDR.EVENT.TYP = [repmat(hex2dec('0300'),HDR.NRec,1);repmat(hex2dec('8300'),HDR.NRec,1)];
      
      % cue event
      if isfield(tmp.EEG,'xmin')
        offset = tmp.EEG.xmin*HDR.SampleRate;
        HDR.EVENT.POS = [HDR.EVENT.POS; [0:HDR.NRec-1]'*HDR.SPR - offset];      % timing of cue
        HDR.EVENT.TYP = [HDR.EVENT.TYP; repmat(hex2dec('0301'), HDR.NRec,1)]; % this is a hack because info on true classlabels is not available
      end;
    end;
    HDR.Calib = sparse(2:HDR.NS+1,1:HDR.NS,1);
    % HDR.debugging_info = tmp.EEG;
    HDR.TYPE = 'native';
    
  elseif isfield(tmp,'eeg');	% Scherer
    fprintf(HDR.FILE.stderr,'Warning SLOAD: Sensitivity not known in %s,\n',HDR.FileName);
    HDR.NS=size(tmp.eeg,2);
    HDR.NRec = 1;
    if ~isfield(tmp,'SampleRate')
      % fprintf(HDR.FILE.stderr,['Samplerate not known in ',HDR.FileName,'. 125Hz is chosen']);
      HDR.SampleRate=125;
    else
      HDR.SampleRate=tmp.SampleRate;
    end;
    HDR.data = tmp.eeg;
    if isfield(tmp,'classlabel'),
      HDR.Classlabel = tmp.classlabel;
    end;
    HDR.TYPE = 'native';
    
    
  elseif isfield(tmp,'data');
    if isfield(tmp,'readme') && iscell(tmp.data) ;	%Zachary A. Keirn, Purdue University, 1988.
      HDR.Label = {'C3'; 'C4'; 'P3'; 'P4'; 'O1'; 'O2'; 'EOG'};
      HDR.SampleRate = 250;
      HDR.FLAG.TRIGGERED  = 1;
      HDR.Dur = 10;
      HDR.SPR = 2500;
      HDR.FILTER.LowPass  = 0.1;
      HDR.FILTER.HighPass = 100;
      HDR.NRec = length(tmp.data);
      
      x = cat(1,tmp.data{:});
      [b,i,CL] = unique({x{:,1}}');
      [HDR.EVENT.CodeDesc,i,CL(:,2)] = unique({x{:,2}}');
      HDR.Classlabel = CL;
      HDR.data = [x{:,4}]';
      HDR.NS   = size(HDR.data,2);
      HDR.Calib= sparse(2:8,1:7,1);
      HDR.Cal  = ones(HDR.NS,1);
      HDR.Off  = zeros(HDR.NS,1);
      HDR.PhysDimCode = zeros(HDR.NS,1);
      HDR.TYPE = 'native';
      HDR.THRESHOLD = [-31.4802   28.8094;  -29.1794   31.8082;  -25.9697   31.4411;  -44.8894   29.2010;  -31.6907   35.1667;  -29.9277   32.6030; -336.5146  261.8502];
      if HDR.FLAG.OVERFLOWDETECTION
        for k=1:HDR.NS,
          HDR.data((HDR.data(:,k)<=HDR.THRESHOLD(k,1)) | (HDR.data(:,k)>=HDR.THRESHOLD(k,2)),k)=NaN;
        end;
      end;
      
    else        	% Mueller, Scherer ?
      HDR.NS = size(tmp.data,2);
      HDR.NRec = 1;
      fprintf(HDR.FILE.stderr,'Warning SLOAD: Sensitivity not known in %s,\n',HDR.FileName);
      if ~isfield(tmp,'SampleRate')
        fprintf(HDR.FILE.stderr,'Warning SLOAD: Samplerate not known in %s. 125Hz is chosen\n',HDR.FileName);
        HDR.SampleRate=125;
      else
        HDR.SampleRate=tmp.SampleRate;
      end;
      HDR.data = tmp.data;
      if isfield(tmp,'classlabel'),
        HDR.Classlabel = tmp.classlabel;
      end;
      if isfield(tmp,'artifact'),
        HDR.ArtifactSelection = zeros(size(tmp.classlabel));
        HDR.ArtifactSelection(tmp.artifact)=1;
      end;
      HDR.TYPE = 'native';
    end;
    
    
  elseif isfield(tmp,'EEGdata') && isfield(tmp,'classlabel');  % Telemonitoring Daten (Reinhold Scherer)
    HDR.NS = size(tmp.EEGdata,2);
    HDR.NRec = 1;
    HDR.Classlabel = tmp.classlabel;
    if ~isfield(tmp,'SampleRate')
      fprintf(HDR.FILE.stderr,'Warning SLOAD: Samplerate not known in %s. 125Hz is chosen\n',HDR.FileName);
      HDR.SampleRate=125;
    else
      HDR.SampleRate=tmp.SampleRate;
    end;
    HDR.PhysDim = '�V';
    fprintf(HDR.FILE.stderr,'Sensitivity not known in %s. 50�V is chosen\n',HDR.FileName);
    HDR.data = tmp.EEGdata*50;
    HDR.TYPE = 'native';
    
    
  elseif isfield(tmp,'EEGdata') && isfield(tmp,'EEGdatalabel') && isfield(tmp,'configuration_channel');
    %% some gtec data
    HDR.NS = size(tmp.EEGdata,1);
    HDR.SPR = size(tmp.EEGdata,2);
    HDR.NRec = size(tmp.EEGdata,3);
    HDR.Classlabel = tmp.EEGdatalabel;
    HDR.TRIG = [0:HDR.NRec-1]'*HDR.SPR+1;
    fprintf(HDR.FILE.stderr,'Warning SLOAD: Samplerate not known in %s. Samplingrate is normalized to 1.\n',HDR.FileName);
    HDR.SampleRate = 1;
    % values for samplerate, channel label, physical units etc. not supported.
    HDR.PhysDim = 'uV';
    HDR.data = reshape(tmp.EEGdata,HDR.NS,HDR.SPR*HDR.NRec)';
    HDR.TYPE = 'native';
    
    
  elseif isfield(tmp,'daten');	% EP Daten von Michael Woertz
    HDR.NS = size(tmp.daten.raw,2)-1;
    HDR.NRec = 1;
    if ~isfield(tmp,'SampleRate')
      fprintf(HDR.FILE.stderr,'Warning SLOAD: Samplerate not known in %s. 2000Hz is chosen\n',HDR.FileName);
      HDR.SampleRate=2000;
    else
      HDR.SampleRate=tmp.SampleRate;
    end;
    HDR.PhysDim = '�V';
    fprintf(HDR.FILE.stderr,'Sensitivity not known in %s. 100�V is chosen\n',HDR.FileName);
    %signal=tmp.daten.raw(:,1:HDR.NS)*100;
    HDR.data = tmp.daten.raw*100;
    HDR.TYPE = 'native';
    
  elseif isfield(tmp,'neun') && isfield(tmp,'zehn') && isfield(tmp,'trig');	% guger,
    HDR.NS=3;
    HDR.NRec = 1;
    if ~isfield(tmp,'SampleRate')
      fprintf(HDR.FILE.stderr,'Warning SLOAD: Samplerate not known in %s. 125Hz is chosen\n',HDR.FileName);
      HDR.SampleRate=125;
    else
      HDR.SampleRate=tmp.SampleRate;
    end;
    fprintf(HDR.FILE.stderr,'Sensitivity not known in %s. \n',HDR.FileName);
    HDR.data = [tmp.neun;tmp.zehn;tmp.trig];
    HDR.Label = {'Neun','Zehn','TRIG'};
    HDR.TYPE = 'native';
    
    
  elseif isfield(tmp,'Recorder1')    % Nicolet NRF format converted into Matlab
    for k = 1:length(s.Recorder1.Channels.ChannelInfos);
      HDR.Label{k} = [s.Recorder1.Channels.ChannelInfos(k).ChannelInfo.Name,' '];
      HDR.PhysDim{k} = [s.Recorder1.Channels.ChannelInfos(k).ChannelInfo.YUnits,' '];
    end;
    signal = [];
    T = [];
    for k = 1:length(s.Recorder1.Channels.Segments)
      tmp = s.Recorder1.Channels.Segments(k).Data;
      sz = size(tmp.Samples);
      signal = [signal; repmat(nan,100,sz(1)); tmp.Samples'];
      T = [T;repmat(nan,100,1);tmp.dX0+(1:sz(2))'*tmp.dXstep ]
      fs = 1./tmp.dXstep;
      if k==1,
        HDR.SampleRate = fs;
      elseif HDR.SampleRate ~= fs;
        fprintf(2,'Error SLOAD (NRF): different Sampling rates not supported, yet.\n');
      end;
    end;
    HDR.data = signal;
    HDR.TYPE = 'native';
    
    
  elseif isfield(tmp,'ECoGdata') && isfield(tmp,'dataset')  %Michigan ECoG dataset
    HDR.data = tmp.ECoGdata';
    HDR.T0 = datevec(datenum(tmp.dataset.filetype.timestamp));
    HDR.SampleRate = tmp.dataset.specs.sample_rate;
    HDR.Filter.HighPass = tmp.dataset.specs.filters.lowcut;
    HDR.Filter.LowPass = tmp.dataset.specs.filters.highcut;
    if isfield(tmp.dataset.specs.filters,'notch60');
      HDR.FILTER.Notch = tmp.dataset.specs.filters.notch60*60;
    end;
    HDR.Patient.Sex = tmp.dataset.subject_info.gender;
    HDR.Patient.Age = tmp.dataset.subject_info.age;
    HDR.Label = tmp.dataset.electrode.names;
    HDR.NS    = tmp.dataset.electrode.number;
    
    trigchancode = getfield(tmp.dataset.electrode.options,'TRIGGER');
    HDR.AS.TRIGCHAN = find(tmp.dataset.electrode.region==trigchancode);
    HDR.TRIG  = tmp.dataset.trigger.trigs_all;
    
    HDR.FLAG.TRIGGERED = 0;
    HDR.NRec  = 1;
    HDR.SPR = size(HDR.data,1);
    HDR.Dur = HDR.SPR/HDR.SampleRate;
    HDR.TYPE  = 'native';
    clear tmp;
    
    
  elseif isfield(tmp,'P_C_S');	% G.Tec Ver 1.02, 1.5x data format
    HDR.FILE.POS = 0;
    if isa(tmp.P_C_S,'data'), %isfield(tmp.P_C_S,'version'); % without BS.analyze
      if any(tmp.P_C_S.Version==[1.02, 1.5, 1.52, 3.00]),
      else
        fprintf(HDR.FILE.stderr,'Warning: PCS-Version is %4.2f.\n',tmp.P_C_S.Version);
      end;
      HDR.Filter.LowPass  = tmp.P_C_S.LowPass;
      HDR.Filter.HighPass = tmp.P_C_S.HighPass;
      HDR.Filter.Notch    = tmp.P_C_S.Notch;
      HDR.SampleRate      = tmp.P_C_S.SamplingFrequency;
      HDR.gBS.Attribute   = tmp.P_C_S.Attribute;
      HDR.gBS.AttributeName = tmp.P_C_S.AttributeName;
      HDR.Label 	    = tmp.P_C_S.ChannelName;
      HDR.gBS.EpochingSelect = tmp.P_C_S.EpochingSelect;
      HDR.gBS.EpochingName = tmp.P_C_S.EpochingName;
      HDR.ELEC.XYZ = [tmp.P_C_S.XPosition; tmp.P_C_S.YPosition; tmp.P_C_S.ZPosition]';
      
      HDR.data = double(tmp.P_C_S.Data);
      
    else %if isfield(tmp.P_C_S,'Version'),	% with BS.analyze software, ML6.5
      if any(tmp.P_C_S.version==[1.02, 1.5, 1.52, 3.00]),
      else
        fprintf(HDR.FILE.stderr,'Warning: PCS-Version is %4.2f.\n',tmp.P_C_S.version);
      end;
      HDR.Filter.LowPass  = tmp.P_C_S.lowpass;
      HDR.Filter.HighPass = tmp.P_C_S.highpass;
      HDR.Filter.Notch    = tmp.P_C_S.notch;
      HDR.SampleRate      = tmp.P_C_S.samplingfrequency;
      HDR.gBS.Attribute   = tmp.P_C_S.attribute;
      HDR.gBS.AttributeName = tmp.P_C_S.attributename;
      HDR.Label 	    = tmp.P_C_S.channelname;
      HDR.gBS.EpochingSelect = tmp.P_C_S.epochingselect;
      HDR.gBS.EpochingName = tmp.P_C_S.epochingname;
      HDR.ELEC.XYZ = [tmp.P_C_S.xposition; tmp.P_C_S.yposition; tmp.P_C_S.zposition]';
      
      HDR.data = double(tmp.P_C_S.data);
    end;
    tmp = []; % free some memory
    
    sz       = size(HDR.data);
    HDR.NRec = sz(1);
    HDR.SPR  = sz(2);
    HDR.Dur  = sz(2)/HDR.SampleRate;
    HDR.NS   = sz(3);
    HDR.FLAG.TRIGGERED = HDR.NRec>1;
    
    HDR.data = reshape(permute(HDR.data,[2,1,3]),[sz(1)*sz(2),sz(3)]);
    
    % Selection of trials with artifacts
    ch = strmatch('ARTIFACT',HDR.gBS.AttributeName);
    if ~isempty(ch)
      HDR.ArtifactSelection = HDR.gBS.Attribute(ch,:);
    end;
    
    % Convert gBS-epochings into BIOSIG - Events
    map = zeros(size(HDR.gBS.EpochingName,1),1);
    map(strmatch('AUGE',HDR.gBS.EpochingName))=hex2dec('0101');
    map(strmatch('EOG',HDR.gBS.EpochingName))=hex2dec('0101');
    map(strmatch('MUSKEL',HDR.gBS.EpochingName))=hex2dec('0103');
    map(strmatch('MUSCLE',HDR.gBS.EpochingName))=hex2dec('0103');
    
    map(strmatch('ELECTRODE',HDR.gBS.EpochingName))=hex2dec('0105');
    
    map(strmatch('SLEEPSTAGE1',HDR.gBS.EpochingName))=hex2dec('0411');
    map(strmatch('SLEEPSTAGE2',HDR.gBS.EpochingName))=hex2dec('0412');
    map(strmatch('SLEEPSTAGE3',HDR.gBS.EpochingName))=hex2dec('0413');
    map(strmatch('SLEEPSTAGE4',HDR.gBS.EpochingName))=hex2dec('0414');
    map(strmatch('REM',HDR.gBS.EpochingName))=hex2dec('0415');
    
    if ~isempty(HDR.gBS.EpochingSelect),
      HDR.EVENT.TYP = map([HDR.gBS.EpochingSelect{:,9}]');
      HDR.EVENT.POS = [HDR.gBS.EpochingSelect{:,1}]';
      HDR.EVENT.CHN = [HDR.gBS.EpochingSelect{:,3}]';
      HDR.EVENT.DUR = [HDR.gBS.EpochingSelect{:,4}]';
    end;
    HDR.TYPE = 'native';
    
  elseif isfield(tmp,'P_C_DAQ_S');
    if ~isempty(tmp.P_C_DAQ_S.data),
      HDR.data = double(tmp.P_C_DAQ_S.data{1});
      
    else
      for k = 1:length(tmp.P_C_DAQ_S.daqboard),
        [tmppfad,file,ext] = fileparts(tmp.P_C_DAQ_S.daqboard{k}.ObjInfo.LogFileName);
        if any(file=='\'),
          %% if file was recorded on WIN but analyzed in LINUX
          file=file(max(find(file=='\'))+1:end);
        end;
        file = fullfile(HDR.FILE.Path,[file,ext]);
        if exist(file,'file')
          HDR.info{k}=daqread(file,'info');
          data = daqread(file);
          if k==1,
            HDR.data = data;
          else
            len = min(size(data,1),size(HDR.data,1));
            HDR.data = [HDR.data(1:len,:), data(1:len,:)];
          end;
        else
          fprintf(HDR.FILE.stderr,'Error SOPEN: data file %s not found\n',file);
          return;
        end;
      end;
    end;
    
    HDR.NS = size(HDR.data,2);
    HDR.Cal = tmp.P_C_DAQ_S.sens*(2.^(1-tmp.P_C_DAQ_S.daqboard{1}.HwInfo.Bits));
    HDR.Calib = sparse(2:HDR.NS+1,1:HDR.NS,HDR.Cal);
    HDR.PhysMax = max(HDR.data);
    HDR.PhysMin = min(HDR.data);
    HDR.DigMax  = HDR.PhysMax;% ./HDR.Cal;
    HDR.DigMin  = HDR.PhysMin;% ./HDR.Cal;
    HDR.Cal = ones(1,HDR.NS);
    HDR.Calib = sparse(2:HDR.NS+1,1:HDR.NS,1);
    HDR.GDFTYP  = repmat(16,1,HDR.NS);  	%% float
    
    if all(tmp.P_C_DAQ_S.unit==1)
      HDR.PhysDimCode=repmat(4275,1,HDR.NS);	%% uV
    else
      HDR.PhysDimCode=zeros(1,HDR.NS); 	%% [?]
    end;
    
    HDR.SampleRate = tmp.P_C_DAQ_S.samplingfrequency;
    sz     = size(HDR.data);
    if length(sz)==2, sz=[1,sz]; end;
    HDR.NRec = sz(1);
    HDR.Dur  = sz(2)/HDR.SampleRate;
    HDR.NS   = sz(3);
    HDR.FLAG.TRIGGERED = HDR.NRec>1;
    HDR.Label 	   = tmp.P_C_DAQ_S.channelname;
    HDR.Filter.LowPass = tmp.P_C_DAQ_S.lowpass;
    HDR.Filter.HighPass = tmp.P_C_DAQ_S.highpass;
    HDR.Filter.Notch    = tmp.P_C_DAQ_S.notch;
    if isfield(tmp.P_C_DAQ_S,'attribute')
      HDR.gBS.Attribute   = tmp.P_C_DAQ_S.attribute;
    end;
    if isfield(tmp.P_C_DAQ_S,'attributename')
      HDR.gBS.AttributeName = tmp.P_C_DAQ_S.attributename;
    end;
    HDR.TYPE = 'native';
    
    
  elseif isfield(tmp,'eventmatrix') && isfield(tmp,'samplerate')
    %%% F. Einspieler's Event information
    HDR.EVENT.POS = tmp.eventmatrix(:,1);
    HDR.EVENT.TYP = tmp.eventmatrix(:,2);
    HDR.EVENT.CHN = tmp.eventmatrix(:,3);
    HDR.EVENT.DUR = tmp.eventmatrix(:,4);
    HDR.SampleRate = tmp.samplerate;
    HDR.TYPE = 'EVENT';
    
    
  elseif isfield(tmp,'Electrode')
    if isfield(tmp.Electrode,'Theta') && isfield(tmp.Electrode,'Phi')
      Theta = tmp.Electrode.Theta(:)*pi/180;
      Phi   = tmp.Electrode.Phi(:)*pi/180;
      HDR.ELEC.XYZ = [ sin(Theta).*cos(Phi), sin(Theta).*sin(Phi),cos(Theta)];
      HDR.Label = tmp.Electrode.Acronym(:);
      HDR.TYPE = 'ELPOS';
      return;
    end;
    
  else
    HDR.Calib = 1;
    CHAN = 1;
  end;
  if strcmp(HDR.TYPE,'native'),
    if ~isfield(HDR,'NS');
      HDR.NS = size(HDR.data,2);
    end;
    if ~isfield(HDR,'SPR');
      HDR.SPR = size(HDR.data,1);
    end;
    if ~isfield(HDR.FILE,'POS');
      HDR.FILE.POS = 0;
    end;
  end;   