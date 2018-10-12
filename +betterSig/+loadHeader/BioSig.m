function [HDR, immediateReturn] = BioSig(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 % this code should match HDR2ASCII in order to do ASCII2HDR
  if any(HDR.FILE.PERMISSION=='r'),
    fid = fopen(HDR.FileName,'r');
    s = fread(fid,[1,inf],'uint8=>char');
    fclose(fid);
    ix0 = strfind(s,'[Fixed Header]');
    ix1 = strfind(s,'[Channel Header]');
    ix2 = strfind(s,'[Event Table]');
    
    HDR.H1 = s(ix0:ix1-1);
    HDR.H2 = s(ix1:ix2-1);
    HDR.H3 = s(ix2-1:end);
    
    %%%%%%%%%% fixed header
    HDR.H1(HDR.H1=='=') = 9;
    [n,v,s]=str2double(HDR.H1,9);
    HDR.SampleRate = n(strmatch('SamplingRate',s(:,1)),2);
    HDR.NS = n(strmatch('NumberOfChannels',s(:,1)),2);
    HDR.SPR = n(strmatch('Number_of_Samples',s(:,1)),2);
    HDR.NRec = 1;
    HDR.TYPE = s{strmatch('Format',s(:,1)),2};
    HDR.FileName = s{strmatch('Filename',s(:,1)),2};
    
    %%%%%%%%%% variable header
    s = HDR.H2;
    [tline,s] = strtok(s,[10,13]);
    [tline,s] = strtok(s,[10,13]);
    [n,v,s]=str2double(s,9,[10,13]);
    HDR.Label = s(:,3)';
    HDR.LeadIdCode = n(:,2);
    HDR.AS.SampleRate = n(:,4);
    [datatyp,limits,datatypes,numbits,HDR.GDFTYP]=gdfdatatype(s(:,5));
    HDR.THRESHOLD = n(:,6:7);
    HDR.Off = n(:,8);
    HDR.Cal = n(:,9);
    HDR.PhysDim = s(:,10)';
    HDR.Filter.HighPass = n(:,11);
    HDR.Filter.LowPass = n(:,12);
    HDR.Filter.Notch = n(:,13);
    HDR.Impedance = n(:,14)*1000;
    HDR.ELEC.XYZ = n(:,15:17);
    
    %%%%%%%%%% event table
    s = HDR.H3;
    tline = '';
    while ~strncmp(tline,'NumberOfEvents',14);
      [tline,s] = strtok(s,[10,13]);
    end;
    [p,v] = strtok(tline,'=');
    [p,v] = strtok(v,'=');
    N  = str2double(p);
    ET = repmat(NaN,N,4);
    [tline,s] = strtok(s,[10,13]);
    for k = 1:N,
      [tline,s] = strtok(s,[10,13]);
      [typ,tline] = strtok(tline,[9,10,13]);
      ET(k,1)   = hex2dec(typ(3:end));
      [n,v,st]  = str2double(tline,[9]);
      ET(k,2:4) = n(1:3);
    end;
    HDR.EVENT.TYP = ET(:,1);
    HDR.EVENT.POS = ET(:,2);
    HDR.EVENT.CHN = ET(:,3);
    HDR.EVENT.DUR = ET(:,4);
    % the following is redundant information %
    HDR.EVENT.VAL = repmat(NaN,N,1);
    ix = find(HDR.EVENT.TYP==hex2dec('7fff'));
    HDR.EVENT.VAL(ix)=HDR.EVENT.DUR(ix);
  end;
  