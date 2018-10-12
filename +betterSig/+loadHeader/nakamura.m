function [HDR, immediateReturn] = nakamura(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 % Nakamura data set
  fid = fopen(fullfile(HDR.FILE.Path,[HDR.FILE.Name,'.chn']),'r');
  s = char(fread(fid,[1,inf],'uint8'));
  fclose(fid);
  [tmp1,tmp2,HDR.Label]=str2double(s);
  HDR.NS = length(HDR.Label);
  for k=1:HDR.NS
    HDR.Label{k} = sprintf('#%02i: %s',k,HDR.Label{k});
  end;
  
  fid = fopen(fullfile(HDR.FILE.Path,[HDR.FILE.Name,'.log']),'r');
  s = char(fread(fid,[1,inf],'uint8'));
  fclose(fid);
  [n,v,sa]    = str2double(s);
  HDR.NRec    = size(n,1);
  HDR.LOG.num = n(:,3:2:end);
  HDR.LOG.str = sa(:,2:2:end);
  styIDX = strmatch('sty',sa(1,:),'exact')+1;	% stimulus type
  stmIDX = strmatch('sttm',sa(1,:),'exact')+1;	% stimulus time
  rtyIDX = strmatch('rty',sa(1,:),'exact')+1;	% response type
  rtmIDX = strmatch('rstm',sa(1,:),'exact')+1;	% response time
  
  fid = fopen(fullfile(HDR.FILE.Path,[HDR.FILE.Name,'.dm6']),'r','ieee-le');
  [s,count] = fread(fid,[1,inf],'float');
  fclose(fid);
  HDR.SPR  = count/(HDR.NS*HDR.NRec);
  HDR.SampleRate = 200;
  HDR.data = reshape(permute(reshape(s(1:HDR.SPR*HDR.NS*HDR.NRec),[HDR.SPR,HDR.NS,HDR.NRec]),[1,3,2]),[HDR.SPR*HDR.NRec,HDR.NS]);
  HDR.FLAG.TRIGGERED = 1;
  HDR.TYPE = 'native';
  HDR.FILE.POS = 0;
  HDR.EVENT.POS = [0:HDR.NRec-1]'*HDR.SPR+n(:,rtyIDX);
  HDR.EVENT.TYP = n(:,11);
  %%% ###FIXME###
  HDR.PhysDimCode = 512+zeros(1,HDR.NS); % normalized, dimensionless
  % HDR.PhysDim
  % HDR.Calib