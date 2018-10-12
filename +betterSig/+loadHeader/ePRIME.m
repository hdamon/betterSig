function [HDR, immediateReturn] = ePRIME(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 HDR.FILE.FID = fopen(HDR.FileName,HDR.FILE.PERMISSION);
  fprintf(HDR.FILE.stderr,'Warning SOPEN: Implementing ePrime format not well tested, yet.\n');
  fseek(HDR.FILE.FID,0,'bof');
  hdrline = fgetl(HDR.FILE.FID);
  c = 1; fname={};
  [fname{1}, r]=strtok(hdrline,char([9,10,13]));
  while ~isempty(r)
    c = c+1;
    [fname{c}, r]=strtok(r,char([9,10,13]));
  end;
  s = fread(HDR.FILE.FID,[1,inf],'uint8=>char');
  fclose(HDR.FILE.FID);
  HDR.FILE.OPEN = 0;
  HDR.NS = 0;
  HDR.SPR = 1;
  HDR.NRec= 0;
  s(s==13) = [];
  while any(s(1)==[10,13]), s(1)=[]; end;
  
  try
    [N,V,S] = str2array(s,char(9),char(10));
  catch
    [N,V,S] = str2double(s,char(9),char(10));
  end
  
  c = strmatch('Subject',fname);
  if ~V(1,c)
    HDR.Patient.Id = num2str(N(1,c));
  else
    HDR.Patient.Id = S{1,c};
  end;
  
  c = strmatch('Display.RefreshRate',fname);
  if all(N(1,c)==N(:,c))
    HDR.EVENT.SampleRate = N(1,c);
  else
    fprintf(HDR.FILE.stderr,'Warning SOPEN (ePrime): could not identify display rate\n');
  end;
  
  t = [S{2,strmatch('SessionDate',fname)}, ' ', S{2,strmatch('SessionTime',fname)}];
  t(t==':' | t=='-')=' ';
  try
    T0 = str2double(t,' ');
    HDR.T0 = T0([3,1,2,4,5,6]);
  end;
  
  OnsetTime = N(:,strmatch('PictureTarget.OnsetTime',fname));
  HDR.EVENT.POS = OnsetTime;
  OnsetDelay = N(:,strmatch('PictureTarget.OnsetDelay',fname));
  t = S(:,strmatch('Stimulus',fname));
  [HDR.EVENT.Desc,I,HDR.EVENT.TYP] = unique(t);
  HDR.EVENT.DUR = N(:,strmatch('PictureTarget.RT',fname));
  HDR.EVENT.CHN = zeros(size(HDR.EVENT.POS));
  
  HDR.ePrime.N = N;
  HDR.ePrime.S = S;