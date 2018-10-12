function [HDR, immediateReturn] = AINF(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 if any(HDR.FILE.PERMISSION=='r'),
    %%%% read header %%%%
    fid = fopen(fullfile(HDR.FILE.Path,[HDR.FILE.Name,'.ainf']),'rt');
    s   = char(fread(fid,[1,inf],'uint8'));
    fclose(fid);
    [tline,s] = strtok(s,[10,13]);
    while strncmp(tline,'#',1)
      [tline,s]=strtok(s,[10,13]);
      [t,r]=strtok(tline,[9,10,13,' #:=']);
      if strcmp(t,'sfreq'),
        [t,r]=strtok(r,[9,10,13,' #:=']);
        HDR.SampleRate = str2double(t);
      end;
    end;
    [n,v,sa]  = str2double([tline,s]);
    HDR.NS    = max(n(:,1));
    for k = 1:HDR.NS,
      HDR.Label{k} = [sa{k,2},' ',sa{k,3}];
    end;
    HDR.Cal   = [n(:,4).*n(:,5)];
    
    %%%% read data %%%%
    HDR.FILE.FID  = fopen(fullfile(HDR.FILE.Path,[HDR.FILE.Name,'.raw']),HDR.FILE.PERMISSION,'ieee-be');
    fseek(HDR.FILE.FID,0,'eof');
    HDR.FILE.size = ftell(HDR.FILE.FID);
    fseek(HDR.FILE.FID,0,'bof');
    
    HDR.GDFTYP = 3;
    HDR.AS.bpb = HDR.NS*2+4;
    HDR.SPR = floor(HDR.FILE.size/HDR.AS.bpb);
    HDR.NRec = 1;
    HDR.FILE.POS = 0;
    HDR.HeadLen = 0;
    HDR.PhysDimCode = zeros(HDR.NS,1);
  end;
  