function [HDR, immediateReturn] = GTF(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
  
  % read 3 header blocks
  HDR.GTF.H1 = fread(HDR.FILE.FID,[1,512],'uint8');
  HDR.GTF.H2 = fread(HDR.FILE.FID,[1,15306],'int8');
  HDR.GTF.H3 = fread(HDR.FILE.FID,[1,8146],'uint8');
  HDR.GTF.messages = fread(HDR.FILE.FID,[3600,1],'int8');
  HDR.GTF.states   = fread(HDR.FILE.FID,[3600,1],'int8');
  
  HDR.GTF.L1 = char(reshape(HDR.GTF.H3(1:650),65,10)');
  HDR.GTF.L2 = char(reshape(HDR.GTF.H3(650+(1:20*16)),16,20)');
  HDR.GTF.L3 = reshape(HDR.GTF.H3(1070+32*3+(1:232*20)),232,20)';
  
  HDR.Label = char(reshape(HDR.GTF.H3(1071:1070+32*3),3,32)');        % channel labels
  
  [H.i8, count]    = fread(HDR.FILE.FID,inf,'int8');
  fclose(HDR.FILE.FID);
  
  [t,status] = str2double(char([HDR.GTF.H1(35:36),32,HDR.GTF.H1(37:39)]));
  if ~any(status) && all(t>0)
    HDR.NS = t(1);
    HDR.SampleRate = t(2);
  else
    fprintf(2,'ERROR SOPEN (%s): Invalid GTF header.\n',HDR.FileName);
    HDR.TYPE = 'unknown';
    return;
  end
  
  % convert messages, states and annotations into EVENT's
  ix = find(HDR.GTF.messages<-1);
  ann.POS  = ix*HDR.SampleRate;
  ann.TYP  = -HDR.GTF.messages(ix)-1;
  ann.Desc = [repmat('A: ',length(ix),1),HDR.GTF.L1(ann.TYP,:)];
  ix = find(HDR.GTF.messages>-1);
  msg.POS  = ix*HDR.SampleRate;
  msg.TYP  = 1+HDR.GTF.messages(ix);
  msg.Desc = [repmat('M: ',length(ix),1),HDR.GTF.L2(msg.TYP,:)];
  ix       = find((HDR.GTF.states>9) & (HDR.GTF.states<20));
  sts.POS  = ix*HDR.SampleRate;
  sts.TYP  = HDR.GTF.states(ix)+1;
  % ix       = find((HDR.GTF.states==20));  % Calibration ???
  
  sts.Desc = [repmat('S: ',length(ix),1),HDR.GTF.L2(sts.TYP,:)];
  HDR.EVENT.POS  = [ann.POS(:); msg.POS(:); sts.POS(:)];
  HDR.EVENT.TYP  = [ann.TYP(:); msg.TYP(:)+10; sts.TYP(:)+10];
  HDR.EVENT.Desc = cellstr(char(ann.Desc,msg.Desc,sts.Desc));
  
  HDR.GTF.ann = ann;
  HDR.GTF.msg = msg;
  HDR.GTF.sts = sts;
  
  HDR.Dur  = 10;
  HDR.SPR  = HDR.Dur*HDR.SampleRate;
  HDR.Bits = 8;
  HDR.GDFTYP = repmat(1,HDR.NS,1);
  HDR.TYPE = 'native';
  if ~isfield(HDR.THRESHOLD'),
    HDR.THRESHOLD = repmat([-127,127],HDR.NS,1);    % support of overflow detection
  end;
  HDR.FILE.POS = 0;
  HDR.Label = HDR.Label(1:HDR.NS,:);
  
  HDR.AS.bpb = (HDR.SampleRate*240+2048);
  HDR.GTF.Preset = HDR.GTF.H3(8134)+1;	% Preset
  
  t2 = (0:floor(count/HDR.AS.bpb)-1)*HDR.AS.bpb;
  HDR.NRec = length(t2);
  [s2,sz]  = trigg(H.i8,t2+2048,1,HDR.SampleRate*240);
  HDR.data = reshape(s2,[HDR.NS,sz(2)/HDR.NS*HDR.NRec])';
  
  [s4,sz]  = trigg(H.i8,t2+1963,0,1);
  sz(sz==1)= [];
  x  = reshape(s4,sz)';
  HDR.GTF.timestamp = (x+(x<0)*256)*[1;256];      % convert from 2*int8 in 1*uint16
  
  [s4,sz] = trigg(H.i8,t2,1,2048);
  sz(sz==1)= []; if length(sz)<2,sz = [sz,1]; end;
  s4 = reshape(s4,sz);
  
  tau  = [0.01, 0.03, 0.1, 0.3, 1];
  LowPass = [30, 70];
  
  %% Scaling
  Sens = [.5, .7, 1, 1.4, 2, 5, 7, 10, 14, 20, 50, 70, 100, 140, 200];
  x    = reshape(s4(13:6:1932,:),32,HDR.NRec*HDR.Dur);
  Cal  = Sens(x(1:HDR.NS,:)+1)'/4;
  HDR.data  = HDR.data.*Cal(ceil((1:HDR.SampleRate*HDR.NRec*HDR.Dur)/HDR.SampleRate),:);
  HDR.PhysDim = 'uV';