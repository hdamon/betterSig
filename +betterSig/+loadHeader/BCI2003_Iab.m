function [HDR, immediateReturn] = BCI2003_Iab(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


% BCI competition 2003, dataset 1a+b (Tuebingen)
  data = load('-ascii',HDR.FileName);
  if strfind(HDR.FileName,'Testdata'),
    HDR.Classlabel = repmat(NaN,size(data,1),1);
  else
    HDR.Classlabel = data(:,1);
    data = data(:,2:end);
  end;
  
  HDR.NRec = length(HDR.Classlabel);
  HDR.FLAG.TRIGGERED = HDR.NRec>1;
  HDR.PhysDim = '�V';
  HDR.SampleRate = 256;
  
  if strfind(HDR.FILE.Path,'a34lkt')
    HDR.INFO='BCI competition 2003, dataset 1a (Tuebingen)';
    HDR.Dur = 3.5;
    HDR.Label = {'A1-Cz';'A2-Cz';'C3f';'C3p';'C4f';'C4p'};
    HDR.TriggerOffset = -2; %[s]
  end;
  
  if strfind(HDR.FILE.Path,'egl2ln')
    HDR.INFO='BCI competition 2003, dataset 1b (Tuebingen)';
    HDR.Dur = 4.5;
    HDR.Label = {'A1-Cz';'A2-Cz';'C3f';'C3p';'vEOG';'C4f';'C4p'};
    HDR.TriggerOffset = -2; %[s]
  end;
  HDR.SPR = HDR.SampleRate*HDR.Dur;
  HDR.NS  = length(HDR.Label);
  HDR.data = reshape(permute(reshape(data, [HDR.NRec, HDR.SPR, HDR.NS]),[2,1,3]),[HDR.SPR*HDR.NRec,HDR.NS]);
  HDR.TYPE = 'native';
  HDR.FILE.POS = 0;