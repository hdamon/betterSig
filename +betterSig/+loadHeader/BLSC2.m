function [HDR, immediateReturn] = BLSC2(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
  HDR.Header = fread(HDR.FILE.FID,[1,3720],'uint8');       % ???
  %HDR.data   = fread(HDR.FILE.FID,[32,inf],'ubit8');      % ???
  H1 = HDR.Header;
  HDR.HeadLen= H1(2)*128;
  if strcmp(HDR.TYPE,'BLSC2-128'),
    H1 = HDR.Header(129:end);
    HDR.HeadLen = H1(2)*128;
  end;
  HDR.VERSION= H1(3:4)*[1;256]/100;
  T0 = char(H1(25:34));
  T0(T0=='-') = ' ';
  T0 = str2double(T0);
  HDR.T0     = T0([3,2,1]);
  HDR.NS     = H1(347);
  HDR.SPR    = 1;
  HDR.SampleRate = 128;
  HDR.GDFTYP = 2; 	% uint8
  AmpType    = H1(6);
  HDR.Filter.LF = H1(319:323);
  HDR.Filter.HF = H1(314:328);
  RefPos   = char(H1(336:341));
  GndPos   = char(H1(342:346));
  NormFlag = H1(348);
  ReCount  = H1(353:354)*[1;256];	% EEG record count
  NoSets   = H1(355:356)*[1;256];	% Number of EEG channels
  ReCount  = H1(357:358)*[1;256]; % Number of Channels in an EEG set
  
  if (HDR.HeadLen >= 2.34)
    %		HDR.Label = cellstr(reshape(char(H1(1861:1986)),6,21));
  end;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %codetab;	% Loading the Code Table
  %load codetab
  gain_code=[10 24;
    50 25;
    75 26;
    100 27;
    150 28;
    200 29;
    300 31;
    500 17;
    750 18;
    1000 19;
    1500 20;
    2000 21;
    2500 22;
    3000 23;
    5000 9;
    7500 10;
    10000 11;
    15000 12;
    20000 13;
    25000 14;
    30000 15;
    50000 1;
    75000 2;
    100000 3;
    150000 4;
    200000 5;
    250000 6;
    300000 7];
  
  lpf_code=[ 30 100 150 300 500 750 1000 70 300 1000 1500 3000 5000 7500 10000 700];
  hpf_code=[.1 .3  1  3 10 30 100 300 inf];
  
  CV    = H1(426:446);
  DC    = H1(447:467)-128;
  SENS  = H1(468:469)*[1;256];
  CALUV = H1(470:471)*[1;256];
  GAIN  = H1(603:634);
  
  for k=1:length(GAIN),
    gain(k)=gain_code(find(gain_code(:,2)==GAIN(k)),1);
  end;
  
  if  AmpType==0	%External Amplifier
    HDR.Cal = (2*CALUV./CV)*(SENS/10);
    HDR.Off = -(128+DC)*HDR.Cal;
    %Voltage=((ADV'-128)-(DC-128))*(2*CALUV/CV)*(SENS/10);
  else %Internal Amplifier
    ch = 1:HDR.NS; %1:min(length(CV),length(gain));
    HDR.Cal =  (200./CV(ch)).*(20000./gain(ch));
    HDR.Off = -(128+DC(ch).*gain(ch)/300000).*HDR.Cal;
    %for k=(1:NoChan),
    %	Voltage(:,k)=((ADV(k,:)'-128)-((DC(k)-128)*gain(k)/300000))*((200/CV(k))*(20000/gain(k)));
    %end;
  end;
  
  HDR.Calib  = [HDR.Off; diag(HDR.Cal)];
  HDR.PhysDimCode = zeros(HDR.NS,1);
  fprintf(2,'Warning SOPEN: Format BLSC not well tested.\n');
  HDR.NRec = (HDR.FILE.size-HDR.HeadLen)/HDR.NS;
  HDR.AS.bpb = HDR.NS;
  HDR.FILE.POS = 0;
  HDR.FILE.OPEN = 1;
  HDR.TYPE   = 'BLSC2';
  fseek(HDR.FILE.FID,HDR.HeadLen,'bof');
  
  fn = fullfile(HDR.FILE.Path,[HDR.FILE.Name,'.CMT']);
  fid = fopen(fn,'rb');
  if (fid>0)
    [CMT,c] = fread(fid,[1,inf],'uint8');
    CMT = reshape(CMT(27:end),70,(c-26)/70)';
    HDR.EVENT.T = CMT(:,[55:58,63:66])*sparse([7,8,6,5,1,2,3,4],[1,1,2,3,4,5,6,6],[1,256,1,1,1,1,1,.01]);
    HDR.EVENT.CMT = CMT;
    fclose(fid);
  end;