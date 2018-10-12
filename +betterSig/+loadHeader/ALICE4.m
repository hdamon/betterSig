function [HDR, immediateReturn] = ALICE4(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 fprintf(HDR.FILE.stderr,'Warning SOPEN: Support of ALICE4 format not completeted. \n\tCalibration, filter setttings and SamplingRate are missing\n');
  HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
  [s,c]  = fread(HDR.FILE.FID,[1,408],'uint8');
  HDR.NS = s(55:56)*[1;256];
  HDR.SampleRate   = 100;
  HDR.Patient.Id   = char(s(143:184));
  HDR.Patient.Sex  = char(s(185));
  HDR.Patient.Date = char(s(187:194));
  [H2,c] = fread(HDR.FILE.FID,[118,HDR.NS],'uint8');
  HDR.Label = char(H2(1:12,:)');
  HDR.HeadLen = ftell(HDR.FILE.FID);
  HDR.AS.bpb = HDR.NS*HDR.SampleRate + 5;
  [a,count] = fread(HDR.FILE.FID,[HDR.AS.bpb,floor((HDR.FILE.size-HDR.HeadLen)/HDR.AS.bpb)],'uint8');
  fclose(HDR.FILE.FID);
  count = ceil(count/HDR.AS.bpb);
  HDR.data = repmat(NaN,100*count,HDR.NS);
  for k = 1:HDR.NS,
    HDR.data(:,k)=reshape(a(k*HDR.SampleRate+[1-HDR.SampleRate:0],:),HDR.SampleRate*count,1);
  end
  HDR.SPR = size(HDR.data,1);
  
  HDR.NRec = 1;
  HDR.FLAG.UCAL = 1;
  HDR.TYPE  = 'native';
  HDR.FILE.POS = 0;
  