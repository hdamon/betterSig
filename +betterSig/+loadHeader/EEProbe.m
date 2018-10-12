function [HDR, immediateReturn] = EEProbe(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 if strcmp(HDR.TYPE,'EEProbe-CNT'),
    %if
    try
      % Read the first sample of the file with a mex function
      % this also gives back header information, which is needed here
      tmp = read_eep_cnt(HDR.FileName, 1, 1);
      
      % convert the header information to BIOSIG standards
      HDR.FILE.FID = 1;               % ?
      HDR.FILE.POS = 0;
      HDR.NS = tmp.nchan;             % number of channels
      HDR.SampleRate = tmp.rate;      % sampling rate
      HDR.NRec = 1;                   % it is always continuous data, therefore one record
      HDR.FLAG.TRIGGERED = 0;
      HDR.SPR = tmp.nsample;          % total number of samples in the file
      HDR.Dur = tmp.nsample/tmp.rate; % total duration in seconds
      HDR.Calib = [zeros(1,HDR.NS) ; eye(HDR.NS, HDR.NS)];  % is this correct?
      HDR.Cal   = ones(1,HDR.NS);
      HDR.Label = char(tmp.label);
      HDR.PhysDimCode = ones(1,HDR.NS)*4275;	% uV
      HDR.AS.endpos = HDR.SPR;
      HDR.Label = tmp.label;
      H = [];
      %else %
    catch
      HDR.FILE.FID = fopen(HDR.FileName,'rb');
      H = openiff(HDR.FILE.FID);
    end;
    
    if isfield(H,'RIFF');
      HDR.FILE.OPEN = 1;
      HDR.RIFF = H.RIFF;
      HDR.Label = {};
      HDR.PhysDim = {};
      HDR.SPR  = inf;
      HDR.NRec = 1;
      HDR.FILE.POS = 0;
      if ~isfield(HDR.RIFF,'CNT');
        HDR.TYPE = 'unknown';
      elseif ~isfield(HDR.RIFF.CNT,'eeph');
        HDR.TYPE = 'unknown';
      else
        s = char(HDR.RIFF.CNT.eeph);
        field = '';
        while ~isempty(s)
          [line,s] = strtok(s,[10,13]);
          if strncmp(line,'[Sampling Rate]',15);
            field = 'SampleRate';
          elseif strncmp(line,'[Samples]',9);
            field = 'SPR';
          elseif strncmp(line,'[Channels]',10);
            field = 'NS';
          elseif strncmp(line,'[Basic Channel Data]',20);
            k = 0;
            while (k<HDR.NS),
              [line,s] = strtok(s,[10,13]);
              if ~strncmp(line,';',1);
                k = k+1;
                [num,status,sa]=str2double(line);
                HDR.Label{k} = sa{1};
                HDR.PhysDim{k} = sa{4};
                HDR.Cal(k) = num(2)*num(3);
              end;
            end;
          elseif strncmp(line,';',1);
          elseif strncmp(line,'[',1);
            field = '';
          elseif ~isempty(field);
            [num,status,sa] = str2double(line);
            if ~status,
              HDR = setfield(HDR,field,num);
            end;
          end;
        end;
        
        %HDR.Calib = sparse(2:HDR.NS+1,1:HDR.NS,HDR.Cal);
        HDR.Calib = sparse(2:HDR.NS+1,1:HDR.NS,1); % because SREAD uses READ_EEP_CNT.MEX
        HDR.Cal   = ones(1,HDR.NS);
        HDR.GDFTYP = repmat(16,1,HDR.NS);	%float32
      end
    end
  end;
  
  % read event file, if applicable
  fid = 0;
  if strcmp(HDR.TYPE,'EEProbe-TRG'),
    fid = fopen(HDR.FileName,'rt');
  elseif strcmp(HDR.TYPE,'EEProbe-CNT')
    fid = fopen(fullfile(HDR.FILE.Path,[HDR.FILE.Name,'.trg']),'rt');
  end;
  if fid>0,
    tmp = str2double(fgetl(fid));
    if ~isnan(tmp(1))
      HDR.EVENT.SampleRate = 1/tmp(1);
      N = 0;
      while ~feof(fid),
        tmp = fscanf(fid, '%f %d %s', 3);
        if ~isempty(tmp)
          N = N + 1;
          HDR.EVENT.POS(N,1)  = round(tmp(1)*HDR.EVENT.SampleRate);
          HDR.EVENT.TYP(N,1)  = 0;
          %HDR.EVENT.DUR(N,1) = 0;
          %HDR.EVENT.CHN(N,1) = 0;
          
          HDR.EVENT.TeegType{N,1} = char(tmp(3:end));
          HDR.EVENT.TYP(N,1)  = str2double(HDR.EVENT.TeegType{N,1});		% numeric
        end
      end;
      HDR.EVENT.TYP(isnan(HDR.EVENT.TYP))=0;
      HDR.TRIG = HDR.EVENT.POS(HDR.EVENT.TYP>0);
      %                HDR.EVENT.POS = HDR.EVENT.POS(HDR.EVENT.TYP>0);
      %                HDR.EVENT.TYP = HDR.EVENT.TYP(HDR.EVENT.TYP>0);
      %                HDR.EVENT = rmfield(HDR.EVENT,'TeegType');
    end;
    fclose(fid);
  end;
  
  if strcmp(HDR.TYPE,'EEProbe-AVR'),
    % it appears to be a EEProbe file with an averaged ERP
    try
      tmp = read_eep_avr(HDR.FileName);
    catch
      fprintf(HDR.FILE.stderr,'ERROR SOPEN (EEProbe): Cannot open EEProbe-file, because read_eep_avr.mex not installed. \n');
      fprintf(HDR.FILE.stderr,'ERROR SOPEN (EEProbe): see http://www.smi.auc.dk/~roberto/eeprobe/\n');
      return;
    end
    
    % convert the header information to BIOSIG standards
    HDR.FILE.FID = 1;               % ?
    HDR.FILE.POS = 0;
    HDR.NS = tmp.nchan;             % number of channels
    HDR.SampleRate = tmp.rate;      % sampling rate
    HDR.NRec  = 1;                   % it is an averaged ERP, therefore one record
    HDR.SPR   = tmp.npnt;             % total number of samples in the file
    HDR.Dur   = tmp.npnt/tmp.rate;    % total duration in seconds
    HDR.Calib = [zeros(1,HDR.NS) ; eye(HDR.NS, HDR.NS)];  % is this correct?
    HDR.Label = char(tmp.label);
    HDR.PhysDim   = 'uV';
    HDR.FLAG.UCAL = 1;
    HDR.FILE.POS  = 0;
    HDR.AS.endpos = HDR.SPR;
    HDR.Label = tmp.label;
    HDR.TriggerOffset = 0;
    
    HDR.EEP.data = tmp.data';
  end;