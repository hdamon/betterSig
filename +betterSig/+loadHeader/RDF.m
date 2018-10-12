function [HDR, immediateReturn] = RDF(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
  
  status = fseek(HDR.FILE.FID,4,-1);
  HDR.FLAG.compressed = fread(HDR.FILE.FID,1,'uint16');
  HDR.NS = fread(HDR.FILE.FID,1,'uint16');
  status = fseek(HDR.FILE.FID,552,-1);
  HDR.SampleRate  = fread(HDR.FILE.FID,1,'uint16');
  status = fseek(HDR.FILE.FID,580,-1);
  HDR.Label = char(fread(HDR.FILE.FID,[8,HDR.NS],'uint8')');
  
  cnt = 0;
  ev_cnt = 0;
  ev = [];
  
  % first pass, scan data
  totalsize = 0;
  tag = fread(HDR.FILE.FID,1,'uint32');
  while ~feof(HDR.FILE.FID) %& ~status,
    if tag == hex2dec('f0aa55'),
      cnt = cnt + 1;
      HDR.Block.Pos(cnt) = ftell(HDR.FILE.FID);
      
      % Read nchans and block length
      tmp = fread(HDR.FILE.FID,34,'uint16');
      
      %fseek(HDR.FILE.FID,2,0);
      nchans = tmp(2); %fread(HDR.FILE.FID,1,'uint16');
      %fread(HDR.FILE.FID,1,'uint16');
      block_size = 2^tmp(3); %fread(HDR.FILE.FID,1,'uint16');
      blocksize2 = tmp(4);
      %ndupsamp = fread(HDR.FILE.FID,1,'uint16');
      %nrun = fread(HDR.FILE.FID,1,'uint16');
      %err_detect = fread(HDR.FILE.FID,1,'uint16');
      %nlost = fread(HDR.FILE.FID,1,'uint16');
      HDR.EVENT.N = tmp(9); %fread(HDR.FILE.FID,1,'uint16');
      %fseek(HDR.FILE.FID,50,0);
      
      % Read events
      HDR.EVENT.POS = repmat(nan,HDR.EVENT.N,1);
      HDR.EVENT.TYP = repmat(nan,HDR.EVENT.N,1);
      for i = 1:HDR.EVENT.N,
        tmp = fread(HDR.FILE.FID,2,'uint8');
        %cond_code = fread(HDR.FILE.FID,1,'uint8');
        ev_code = fread(HDR.FILE.FID,1,'uint16');
        ev_cnt  = ev_cnt + 1;
        tmp2.sample_offset = tmp(1) + (cnt-1)*128;
        tmp2.cond_code     = tmp(2);
        tmp2.event_code    = ev_code;
        if ~exist('OCTAVE_VERSION','builtin'),
          ev{ev_cnt} = tmp2;
        end;
        HDR.EVENT.POS(ev_cnt) = tmp(1) + (cnt-1)*128;
        HDR.EVENT.TYP(ev_cnt) = ev_code;
      end;
      status = fseek(HDR.FILE.FID,4*(110-HDR.EVENT.N)+2*nchans*block_size,0);
    else
      [tmp, c] = fread(HDR.FILE.FID,3,'uint16');
      if (c > 2),
        nchans = tmp(2); %fread(HDR.FILE.FID,1,'uint16');
        block_size = 2^tmp(3); %fread(HDR.FILE.FID,1,'uint16');
        
        %fseek(HDR.FILE.FID,62+4*(110-HDR.EVENT.N)+2*nchans*block_size,0);
        sz = 62 + 4*110 + 2*nchans*block_size;
        status = -(sz>=(2^31));
        if ~status,
          status = fseek(HDR.FILE.FID, sz, 0);
        end;
      end;
    end
    tag = fread(HDR.FILE.FID,1,'uint32');
  end
  HDR.NRec = cnt;
  
  HDR.Events = ev;
  HDR.HeadLen = 0;
  HDR.FLAG.TRIGGERED = 1;
  HDR.FILE.POS = 0;
  HDR.SPR = block_size;
  HDR.AS.bpb = HDR.SPR*HDR.NS*2;
  HDR.Dur = HDR.SPR/HDR.SampleRate;
  HDR.PhysDimCode = zeros(1,HDR.NS);
  