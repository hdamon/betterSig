function [HDR, immediateReturn] = CinC2007Challenge(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 ix = find(HDR.s==10);
  d  = str2double(HDR.data(ix(4)+1:end));
  HDR.data = d(:,7:end);
  HDR.TYPE = 'native';
  [HDR.SPR,HDR.NS] = size(HDR.data);
  HDR.NRec = 1;
  HDR.Calib= sparse(2:HDR.NS+1,1:HDR.NS,1);
  %%% FIXME
  % HDR.ELEC.XYZ
  % HDR.PhysDimCode