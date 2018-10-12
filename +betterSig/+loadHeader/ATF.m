function [HDR, immediateReturn] = ATF(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 if any(HDR.FILE.PERMISSION=='r'),
    HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'t'],'ieee-le');
    t = fgetl(HDR.FILE.FID);
    t = str2double(fgetl(HDR.FILE.FID));
    HDR.ATF.NoptHdr = t(1);
    HDR.ATF.NS = t(2);
    HDR.ATF.NormalizationFactor = [];
    t = fgetl(HDR.FILE.FID);
    while any(t=='=')
      [f,t]=strtok(t,[34,61]);        %  "=
      [c,t]=strtok(t,[34,61]);        %  "=
      if strfind(f,'NormalizationFactor:')
        [t1, t2] = strtok(f,':');
        [f] = strtok(t2,':');
        HDR.ATF.NormalizationFactor = setfield(HDR.ATF.NormalizationFactor,f,str2double(c));
      else
        HDR.ATF = setfield(HDR.ATF,f,c);
      end
      t = fgetl(HDR.FILE.FID);
    end;
    k = 0;
    HDR.Label = {};
    while ~isempty(t),
      k = k + 1;
      [HDR.Label{k,1},t] = strtok(t,[9,34]);    % ", TAB
    end
    HDR.HeadLen = ftell(HDR.FILE.FID);
    if isfield(HDR.ATF,'DateTime');
      tmp = HDR.ATF.DateTime;
      tmp(tmp=='/' | tmp==':')=' ';
      HDR.T0 = str2double(tmp);
    end;
    HDR.FILE.OPEN = 1;
  end