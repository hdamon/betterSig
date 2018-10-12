function [HDR, immediateReturn] = Persyst(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 if any(HDR.FILE.PERMISSION=='r');
    [HDR.FILE.FID] = fopen(HDR.FileName,['rb']);
    if HDR.FILE.FID < 0,
      HDR.ErrNum = [32,HDR.ErrNum];
      return;
    end;
    [H1,count] = fread(HDR.FILE.FID, [1,inf], 'uint8=>char');
    fclose(HDR.FILE.FID);
    
    HDR.EVENT.N = 0;
    HDR.NS = 0;
    HDR.Endianity ='ieee-le';
    HDR.FLAG.OVERFLOWDETECTION = 0;
    flag_interleaved = 1;
    flag_nk = 0;
    status = 0;
    line = H1;
    Desc = {};
    HDR.EVENT.POS = [];
    HDR.EVENT.DUR = [];
    HDR.EVENT.CHN = [];
    HDR.EVENT.TYP = [];
    while (~isempty(line))
      [line,H1] = strtok(H1,char([10,13]));
      if strcmp(line,'[FileInfo]')
        status = 1;
      elseif strcmp(line,'[ChannelMap]')
        status = 2;
        %%				HDR.AS.bpb = HDR.NS* 	%% todo
        HDR.PhysDimCode = zeros(HDR.NS,1);      % unknown
      elseif strcmp(line,'[Sheets]')
        status = 3;
      elseif strcmp(line,'[Comments]')
        status = 4;
      elseif strcmp(line,'[Patient]')
        status = 5;
      elseif strcmp(line,'[SampleTimes]')
        status = 6;
      elseif isempty(line)
        ; %% ignore
      elseif isempty(line)
        status = -1;
      else
        switch (status)
          case {1}
            [tag,val]=strtok(line,'=');
            val = val(2:end);
            switch (tag)
              case {'File'}
                val(val=='\')='/';
                ix = find(val=='/');
                if isempty(ix), ix = 0; end;
                datfile = val(ix(end)+1:end);
              case {'FileType'}
                flag_interleaved = strcmp(val,'Interleaved');
                flag_NK = strcmp(val,'NihonKohden');
              case {'SamplingRate'}
                HDR.SampleRate = str2double(val);
                HDR.EVENT.SampleRate = HDR.SampleRate;
              case {'Calibration'}
                HDR.Cal = str2double(val);
              case {'WaveformCount'}
                HDR.NS = str2double(val);
              case {'DataType'}
                switch (val)
                  case {'0'}
                    HDR.GDFTYP = 3;
                    HDR.AS.bpb = 2*HDR.NS;
                  case {'4'}
                    HDR.GDFTYP = 3;
                    HDR.AS.bpb = 2*HDR.NS;
                    HDR.Endianity = 'ieee-be';
                  case {'6'}
                    HDR.GDFTYP = 1;
                    HDR.AS.bpb = HDR.NS;
                  otherwise
                    
                end;
            end;
          case {2}
            [tag,val]=strtok(line,'=');
            ch = str2double(val(2:end));
            HDR.Label{ch} = tag;
          case {3}
          case {4}
            HDR.EVENT.N = HDR.EVENT.N + 1;
            [pos,ll]=strtok(line,',');
            [dur,ll]=strtok(ll,',');
            [ign,ll]=strtok(ll,',');
            [ign,ll]=strtok(ll,',');
            Desc{HDR.EVENT.N} = ll(2:end);
            HDR.EVENT.POS(HDR.EVENT.N) = str2double(pos)*HDR.EVENT.SampleRate;
            HDR.EVENT.DUR(HDR.EVENT.N) = str2double(dur)*HDR.EVENT.SampleRate;
          case {5}
            [tag,val]=strtok(line,'=');
            val = val(2:end);
            switch (tag)
              case {'First'}
                FirstName = val;
              case {'MI'}
                MiddleName = val;
              case {'Last'}
                SurName = val;
              case {'Hand'}
                HDR.Patient.Handedness = any(val(1)=='rR') + any(val(1)=='lL') * 2;
              case {'Sex'}
                HDR.Patient.Sex = any(val(1)=='mM') + any(val(1)=='fF') * 2;
              case {'BirthDate'}
                val(val==47)=' ';
                t = str2double(val);
                if t(3) < 30, 	c = 2000;
                else 		c = 1900;
                end;
                HDR.Patient.Birthday = [t(3)+c,t(1),t(2), 0, 0, 0];
              case {'TestDate'}
                val(val=='/')=' ';
                t = str2double(val);
                if t(3) < 80, 	c = 2000;
                else 		c = 1900;
                end;
                HDR.T0(1:3) = [t(3)+c,t(1),t(2)];
              case {'TestTime'}
                val(val==':')=' ';
                t = str2double(val);
                HDR.T0(4:6) = t;
              case {'ID'}
                HDR.Patient.Id = val;
                %case {'Physician'}
                %	This is not really needed
                %	HDR.REC.Doctor = val;
              case {'Technician'}
                HDR.REC.Technician = val;
              case {'Medications'}
                HDR.Patient.Medication = val;
            end;
          case {6}
        end;
      end;
    end;
    
    if (flag_nk)
      HDR = sopen(fullfile(HDR.FILE.Path,datfile));
    end;
    HDR.FILE.POS = 0;
    HDR.FILE.Ext = '.dat';
    fid = fopen(fullfile(HDR.FILE.Path,datfile),'r', HDR.Endianity);
    if HDR.GDFTYP==3,
      s = fread(fid,inf,'int16');
    elseif HDR.GDFTYP==1
      s = fread(fid,inf,'int8');
    end
    fclose(fid);
    
    if flag_interleaved,
      HDR.data = reshape(s,HDR.NS,[])';
    else
      HDR.data = reshape(s,[],HDR.NS);
    end;
    HDR.data = HDR.data*HDR.Cal;
    
    HDR.SPR     = 1;
    HDR.NRec    = size(HDR.data,1);
    HDR.TYPE    = 'native';
    HDR.DigMax  = max(HDR.data);
    HDR.DigMin  = min(HDR.data);
    HDR.PhysMax = HDR.Cal*HDR.DigMax;
    HDR.PhysMin = HDR.Cal*HDR.DigMin;
    
    HDR.Calib = sparse(2:HDR.NS+1, 1:HDR.NS, HDR.Cal);
    
    [HDR.EVENT.CodeDesc, j, HDR.EVENT.TYP] = unique(Desc);
    HDR.EVENT.CHN = zeros(size(HDR.EVENT.POS));
  end