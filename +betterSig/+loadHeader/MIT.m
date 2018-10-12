function [HDR, immediateReturn] = MIT(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 if any(HDR.FILE.PERMISSION=='r'),
    HDR.FileName = fullfile(HDR.FILE.Path,[HDR.FILE.Name,'.',HDR.FILE.Ext]);
    
    HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
    if HDR.FILE.FID<0,
      fprintf(HDR.FILE.stderr,'Error SOPEN: Couldnot open file %s\n',HDR.FileName);
      return;
    end;
    
    fid = HDR.FILE.FID;
    z   = fgetl(fid);
    while strncmp(z,'#',1) || isempty(z),
      z   = fgetl(fid);
    end;
    tmpfile = strtok(z,' /');
    if ~strcmpi(HDR.FILE.Name,tmpfile),
      fprintf(HDR.FILE.stderr,'Error: RecordName %s does not fit filename %s\n',tmpfile,HDR.FILE.Name);
      fclose(HDR.FILE.FID)
      return;
    end;
    
    %A = sscanf(z, '%*s %d %d %d',[1,3]);
    t = z;
    k = 0;
    while ~isempty(t)
      k = k + 1;
      [s,t] = strtok(t,[9,10,13,32]);
      Z{k}  = s;
      if any(s==':'),
        t0 = str2double(s,':');
        HDR.T0(3+(1:length(t0))) = t0;
      elseif sum(s=='/')==2,
        HDR.T0([3,2,1])=str2double(s,'/');
      end;
    end;
    HDR.NS   = str2double(Z{2});   % number of signals
    
    if k>2,
      [tmp,tmp1] = strtok(Z{3},'/');
      HDR.SampleRate = str2double(tmp);   % sample rate of data
    end;
    
    [tmp,z1] = strtok(Z{1},'/');
    if ~isempty(z1)
      %%%%%%%%%% Multi-Segment files %%%%%%%
      fprintf(HDR.FILE.stderr,'Error SOPEN (MIT) %s:  multi-segment files not supported.\n',tmpfile);
      
      return;
      
      HDR.FLAG.TRIGGERED = 1;
      z1 = strtok(z1,'/');
      HDR.NRec = str2double(z1);
      
      HDR.EVENT.TYP = repmat(hex2dec('0300'),HDR.NRec,1);
      HDR.EVENT.POS = repmat(NaN,HDR.NRec,1);
      HDR.EVENT.DUR = repmat(NaN,HDR.NRec,1);
      HDR.EVENT.CHN = repmat(0,HDR.NRec,1);
      count = 0;
      for k = 1:HDR.NRec;
        [s,t] = strtok(fgetl(fid));
        [hdr] = sopen(fullfile(HDR.FILE.Path,[s,'.hea']),'r',CHAN);
        [s,hdr] = sread(hdr);
        hdr = sclose(hdr);
        if k==1,
          HDR.data = repmat(s,HDR.NRec,1);
        else
          HDR.data(count+1:count+size(s,1),:) = s;
        end;
        HDR.EVENT.POS(k) = count;
        HDR.EVENT.DUR(k) = size(s,1);
        count = count + size(s,1);
      end;
      HDR.Label = hdr.Label;
      HDR.PhysDim = hdr.PhysDim;
      HDR.SPR = size(s,1);
      HDR.NS  = hdr.NS;
      HDR.Calib = (hdr.Calib>0);
      HDR.FLAG.TRIGGERED = 1;
      HDR.FILE.POS = 0;
      HDR.TYPE = 'native';
      
    else
      
      [tmp,z] = strtok(z);
      [tmp,z] = strtok(z);
      %HDR.NS  = str2double(Z{2});   % number of signals
      [tmp,z] = strtok(z);
      [tmp,z] = strtok(z,' ()');
      HDR.NRec = str2double(tmp);   % length of data
      HDR.SPR = 1;
      
      HDR.MIT.gain = zeros(1,HDR.NS);
      HDR.MIT.zerovalue  = repmat(NaN,1,HDR.NS);
      HDR.MIT.firstvalue = repmat(NaN,1,HDR.NS);
      for k = 1:HDR.NS,
        z = fgetl(fid);
        [HDR.FILE.DAT{k,1},z]=strtok(z);
        for k0 = 1:7,
          [tmp,z] = strtok(z);
          if k0 == 1,
            [tmp, tmp1] = strtok(tmp,'x:+');
            [tmp, status] = str2double(tmp);
            HDR.MIT.dformat(k,1) = tmp;
            HDR.AS.SPR(k) = 1;
            if isempty(tmp1)
            elseif tmp1(1)=='x'
              HDR.AS.SPR(k) = str2double(tmp1(2:end));
            elseif tmp1(1)==':'
              fprintf(HDR.FILE.stderr,'Warning SOPEN: skew information in %s is ignored.\n', HDR.FileName);
            end
          elseif k0==2,
            % EC13*.HEA files have special gain values like "200(23456)/uV".
            [tmp, tmp2] = strtok(tmp,'/');
            tmp2 = [tmp2(2:end),' '];
            HDR.PhysDim(k,1:length(tmp2)) = tmp2;
            [tmp, tmp1] = strtok(tmp,' ()');
            [tmp, status] = str2double(tmp);
            if isempty(tmp), tmp = 0; end;   % gain
            if isnan(tmp),   tmp = 0; end;
            HDR.MIT.gain(1,k) = tmp;
          elseif k0==3,
            [tmp, status] = str2double(tmp);
            if isempty(tmp), tmp = NaN; end;
            if isnan(tmp),   tmp = NaN; end;
            HDR.Bits(1,k) = tmp;
          elseif k0==4,
            [tmp, status] = str2double(tmp);
            if isempty(tmp), tmp = 0; end;
            if isnan(tmp),   tmp = 0; end;
            HDR.MIT.zerovalue(1,k) = tmp;
          elseif k0==5,
            [tmp, status] = str2double(tmp);
            if isempty(tmp), tmp = NaN; end;
            if isnan(tmp),   tmp = NaN; end;
            HDR.MIT.firstvalue(1,k) = tmp;        % first integer value of signal (to test for errors)
          else
            
          end;
        end;
        HDR.Label{k} = strtok(z,[9,10,13,32]);
      end;
      
      HDR.MIT.gain(HDR.MIT.gain==0) = 200;    % default gain
      HDR.Calib = sparse([HDR.MIT.zerovalue; eye(HDR.NS)]*diag(1./HDR.MIT.gain(:)));
      
      z = char(fread(fid,[1,inf],'uint8'));
      ix1 = [strfind(upper(z),'AGE:')+4, strfind(upper(z),'AGE>:')+5];
      if ~isempty(ix1),
        [tmp,z]=strtok(z(ix1(1):length(z)));
        HDR.Patient.Age = str2double(tmp);
      end;
      ix1 = [strfind(upper(z),'SEX:')+4, strfind(upper(z),'SEX>:')+5];
      if ~isempty(ix1),
        [HDR.Patient.Sex,z]=strtok(z(ix1(1):length(z)));
      end;
      ix1 = [strfind(upper(z),'BMI:')+4, strfind(upper(z),'BMI>:')+5];
      if ~isempty(ix1),
        [tmp,z]=strtok(z(ix1(1):length(z)));
        HDR.Patient.BMI = str2double(tmp);
      end;
      ix1 = [strfind(upper(z),'DIAGNOSIS:')+10; strfind(upper(z),'DIAGNOSIS>:')+11];
      if ~isempty(ix1),
        [HDR.Patient.Diagnosis,z]=strtok(z(ix1(1):length(z)),char([10,13,abs('#<>')]));
      end;
      ix1 = [strfind(upper(z),'MEDICATIONS:')+12, strfind(upper(z),'MEDICATIONS>:')+13];
      if ~isempty(ix1),
        [HDR.Patient.Medication,z]=strtok(z(ix1(1):length(z)),char([10,13,abs('#<>')]));
      end;
      fclose(fid);
      
      %------ LOAD ATR FILE ---------------------------------------------------
      tmp = fullfile(HDR.FILE.Path,[HDR.FILE.Name,'.atr']);
      if ~exist(tmp,'file'),
        tmp = fullfile(HDR.FILE.Path,[HDR.FILE.Name,'.ATR']);
      end;
      if exist(tmp,'file'),
        H = sopen(tmp);
        HDR.EVENT = H.EVENT;
        HDR.EVENT.SampleRate = HDR.SampleRate;
      end;
      
      %------ LOAD BINARY DATA --------------------------------------------------
      if ~HDR.NS,
        return;
      end;
      if all(HDR.MIT.dformat==HDR.MIT.dformat(1)),
        HDR.VERSION = HDR.MIT.dformat(1);
      else
        fprintf(HDR.FILE.stderr,'Error SOPEN: different DFORMATs not supported.\n');
        HDR.FILE.FID = -1;
        return;
      end;
      
      GDFTYP = repmat(NaN,HDR.NS,1);
      GDFTYP(HDR.MIT.dformat==80) = 2;
      GDFTYP(HDR.MIT.dformat==16) = 3;
      GDFTYP(HDR.MIT.dformat==24) = 255+24;
      GDFTYP(HDR.MIT.dformat==32) = 5;
      GDFTYP(HDR.MIT.dformat==61) = 3;
      GDFTYP(HDR.MIT.dformat==160)= 4;
      GDFTYP(HDR.MIT.dformat==212)= 255+12;
      GDFTYP(HDR.MIT.dformat==310)= 255+10;
      GDFTYP(HDR.MIT.dformat==311)= 255+10;
      if ~any(isnan(GDFTYP)), HDR.GDFTYP = GDFTYP; end;
      HDR.RID = HDR.FILE(1).Name;
      HDR.PID = '';
      
      HDR.AS.spb = sum(HDR.AS.SPR);
      if 0,
        
      elseif HDR.VERSION == 212,
        HDR.AS.bpb = HDR.AS.spb*3/2;
      elseif HDR.VERSION == 310,
        HDR.AS.bpb = HDR.AS.spb/3*4;
      elseif HDR.VERSION == 311,
        HDR.AS.bpb = HDR.AS.spb/3*4;
      elseif HDR.VERSION == 8,
        HDR.AS.bpb = HDR.AS.spb;
      elseif HDR.VERSION == 80,
        HDR.AS.bpb = HDR.AS.spb;
      elseif HDR.VERSION == 160,
        HDR.AS.bpb = HDR.AS.spb;
      elseif HDR.VERSION == 16,
        HDR.AS.bpb = HDR.AS.spb;
      elseif HDR.VERSION == 61,
        HDR.AS.bpb = HDR.AS.spb;
      end;
      if HDR.AS.bpb==round(HDR.AS.bpb),
        d = 1;
      else
        [HDR.AS.bpb,d] = rat(HDR.AS.bpb);
        HDR.NRec   = HDR.NRec/d;
        HDR.AS.SPR = HDR.AS.SPR*d;
        HDR.AS.spb = HDR.AS.spb*d;
      end;
      HDR.AS.bi = [0;cumsum(HDR.AS.SPR(:))];
      HDR.SPR = HDR.AS.SPR(1);
      for k = 2:HDR.NS,
        HDR.SPR = lcm(HDR.SPR,HDR.AS.SPR(k));
      end;
      HDR.AS.SampleRate = HDR.SampleRate*HDR.AS.SPR/d;
      HDR.SampleRate = HDR.SampleRate*HDR.SPR/d;
      HDR.Dur = HDR.SPR/HDR.SampleRate;
      
      if HDR.VERSION ==61,
        MACHINE_FORMAT='ieee-be';
      else
        MACHINE_FORMAT='ieee-le';
      end;
      
      DAT = char(HDR.FILE.DAT);
      if all(all(DAT == DAT(ones(size(DAT,1),1),:))),
        % single DAT-file: only this provides high performance
        HDR.FILE.DAT = DAT(1,:);
        
        tmpfile = fullfile(HDR.FILE.Path,HDR.FILE.DAT);
        if  ~exist(tmpfile,'file'),
          HDR.FILE.DAT = upper(HDR.FILE.DAT);
          tmpfile = fullfile(HDR.FILE.Path,HDR.FILE.DAT);
        end;
        if  ~exist(tmpfile,'file'),
          HDR.FILE.DAT = lower(HDR.FILE.DAT);
          tmpfile = fullfile(HDR.FILE.Path,HDR.FILE.DAT);
        end;
        HDR.FILE.FID = fopen(tmpfile,'rb',MACHINE_FORMAT);
        if HDR.FILE.FID<0,
          fprintf(HDR.FILE.stderr,'Error SOPEN: Couldnot open file %s\n',tmpfile);
          return;
        end;
        
        HDR.FILE.OPEN = 1;
        HDR.FILE.POS  = 0;
        HDR.HeadLen   = 0;
        status = fseek(HDR.FILE.FID,0,'eof');
        tmp = ftell(HDR.FILE.FID);
        try
          HDR.AS.endpos = tmp/HDR.AS.bpb;
        catch
          fprintf(HDR.FILE.stderr,'Warning 2003 SOPEN: FTELL does not return numeric value (Octave > 2.1.52).\nHDR.AS.endpos not completed.\n');
        end;
        status = fseek(HDR.FILE.FID,0,'bof');
        
        HDR.InChanSelect = 1:HDR.NS;
        FLAG_UCAL = HDR.FLAG.UCAL;
        HDR.FLAG.UCAL = 1;
        S = NaN;
        [S,HDR] = sread(HDR,HDR.SPR/HDR.SampleRate); % load 1st sample
        if (HDR.VERSION>0) && (any(S(1,:) - HDR.MIT.firstvalue)),
          fprintf(HDR.FILE.stderr,'Warning SOPEN MIT-ECG: First values of header and datablock do not fit in file %s.\n\tHeader:\t',HDR.FileName);
          fprintf(HDR.FILE.stderr,'\t%5i',HDR.MIT.firstvalue);
          fprintf(HDR.FILE.stderr,'\n\tData 1:\t');
          fprintf(HDR.FILE.stderr,'\t%5i',S(1,:));
          fprintf(HDR.FILE.stderr,'\n');
        end;
        HDR.FLAG.UCAL = FLAG_UCAL ;
        fseek(HDR.FILE.FID,0,'bof');	% reset file pointer
        
      else
        % Multi-DAT files
        [i,j,k]=unique(HDR.FILE.DAT);
        for k1 = 1:length(j),
          ix = (k==k1);
          f = fullfile(HDR.FILE.Path,HDR.FILE.DAT{j(k1)});
          hdr.FILE.FID = fopen(f,'rb');
          if hdr.FILE.FID>0,
            hdr.FILE.stderr = HDR.FILE.stderr;
            hdr.FILE.stdout = HDR.FILE.stdout;
            hdr.FILE.POS = 0;
            hdr.NS = sum(ix);
            hdr.InChanSelect = 1:hdr.NS;
            hdr.MIT.dformat = HDR.MIT.dformat(ix);
            %hdr.Calib = HDR.Calib(:,ix);
            hdr.AS.spb = sum(HDR.AS.SPR(ix));
            hdr.SampleRate = HDR.SampleRate;
            hdr.TYPE = 'MIT';
            hdr.SPR = HDR.SPR;
            hdr.AS.SPR = HDR.AS.SPR(ix);
            hdr.FLAG = HDR.FLAG;
            hdr.FLAG.UCAL = 1;
            
            if all(hdr.MIT.dformat(1)==hdr.MIT.dformat),
              hdr.VERSION = hdr.MIT.dformat(1);
            else
              fprintf(hdr.FILE.stderr,'different DFORMATs not supported.\n');
              hdr.FILE.FID = -1;
              return;
            end;
            if 0,
              
            elseif hdr.VERSION == 212,
              if mod(hdr.AS.spb,2)
                hdr.AS.spb = hdr.AS.spb*2;
              end
              hdr.AS.bpb = hdr.AS.spb*3/2;
            elseif hdr.VERSION == 310,
              if mod(hdr.AS.spb,3)
                hdr.AS.spb = hdr.AS.spb*2/3;
              end
              hdr.AS.bpb = hdr.AS.spb*2;
            elseif hdr.VERSION == 311,
              if mod(hdr.AS.spb,3)
                hdr.AS.spb = hdr.AS.spb*3;
              end
              hdr.AS.bpb = hdr.AS.spb*4;
            elseif hdr.VERSION == 8,
              hdr.AS.bpb = hdr.AS.spb;
            elseif hdr.VERSION == 80,
              hdr.AS.bpb = hdr.AS.spb;
            elseif hdr.VERSION == 160,
              hdr.AS.bpb = hdr.AS.spb;
            elseif hdr.VERSION == 16,
              hdr.AS.bpb = hdr.AS.spb;
            elseif hdr.VERSION == 61,
              hdr.AS.bpb = hdr.AS.spb;
            end;
            [s,hdr] = sread(hdr);
            fclose(hdr.FILE.FID);
          else
            s = [];
          end;
          
          if k1==1,
            HDR.data = s;
          else
            n = [size(s,1),size(HDR.data,1)];
            if any(n~=n(1)),
              fprintf(HDR.FILE.stderr,'Warning SOPEN MIT-ECG(%s): lengths of %s (%i) and %s (%i) differ\n',HDR.FileName,HDR.FILE.DAT{j(k1-1)},n(1),HDR.FILE.DAT{j(k1)},n(2));
            end;
            n = min(n);
            HDR.data = [HDR.data(1:n,:),s(1:n,:)];
          end;
        end;
        HDR.FILE.POS = 0;
        HDR.TYPE = 'native';
      end;
    end;
    
  elseif any(HDR.FILE.PERMISSION=='w'),
    
    fn = fullfile(HDR.FILE.Path,[HDR.FILE.Name,'.hea']);
    fid = fopen(fn,'wt','ieee-le');
    fprintf(fid, '%s %i %f %i %02i:%02i:%02i %02i/%02i/%04i',HDR.FILE.Name,HDR.NS,HDR.SampleRate,HDR.NRec*HDR.SPR,HDR.T0([4:6,3,2,1]));
    if ~isfield(HDR,'GDFTYP')
      HDR.GDFTYP=repmat(3,1,HDR.NS);       % int16
    end;
    for k = 1:HDR.NS,
      if 0,
      elseif HDR.GDFTYP(k)==2,
        HDR.MIT.dformat = 80;
      elseif HDR.GDFTYP(k)==3,
        HDR.MIT.dformat = 16;
      elseif HDR.GDFTYP(k)==4,
        HDR.MIT.dformat = 160;
      else
        error('SOPEN (MIT write): dataformat not supported');
      end;
      ical = (HDR.DigMax(k)-HDR.DigMin(k))/(HDR.PhysMax(k)-HDR.PhysMin(k));
      off  = HDR.DigMin(k) - ical*HDR.PhysMin(k);
      fprintf(fid,'\n%s %i %f(%f)',[HDR.FILE.Name,'.dat'],HDR.MIT.dformat,ical,off);
      
      if isfield(HDR,'PhysDim')
        physdim = HDR.PhysDim(k,:);
        physdim(physdim<33) = [];  	% remove any whitespace
        fprintf(fid,'/%s ',physdim);
      end;
      if isfield(HDR,'Label')
        fprintf(fid,'%s ',HDR.Label(k,:));
      end;
    end;
    fclose(fid);
    HDR.Cal = (HDR.PhysMax-HDR.PhysMin)./(HDR.DigMax-HDR.DigMin);
    HDR.Off = HDR.PhysMin - HDR.Cal .* HDR.DigMin;
    
    HDR.FileName  = fullfile(HDR.FILE.Path,[HDR.FILE.Name,'.dat']);
    HDR.FILE.FID  = fopen(HDR.FileName,'wb','ieee-le');
    HDR.FILE.OPEN = 2;
  end;
  