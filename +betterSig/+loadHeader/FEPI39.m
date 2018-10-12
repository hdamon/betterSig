function [HDR, immediateReturn] = FEPI39(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 % https://epilepsy.uni-freiburg.de/seizure-prediction-workshop-2007/prediction-contest/data-download
  if any(HDR.FILE.PERMISSION=='r'),
    if isfield(HDR,'H1'),
      t = HDR.H1;
      HDR.Cal = .165;
      while ~isempty(t)
        [line,t]=strtok(t,[10,13]);
        [t1,r] = strtok(line,'=');
        [t2,r] = strtok(r,'=');
        num = str2double(t2);
        if strcmp(t1,'SamplingRate')
          HDR.SampleRate = num;
        elseif strcmp(t1,'NbOfChannels')
          HDR.NS = num;
        elseif strcmp(t1,'unit')
          HDR.PhysDim = repmat({t2},HDR.NS,1);
        elseif strcmp(t1,'FirstSampleTime')
          t2(t2==':')=' ';
          HDR.T0(4:6) = str2double(t2);
        elseif strcmp(t1,'Gainx1000')
          HDR.Cal = str2double(t2,',')/1000;
        elseif strcmp(t1,'PatientNo')
          switch num,
            case 1,
              HDR.Patient.Age = 30;
              HDR.Patient.Sex = 2;	% female
            case 2,
              HDR.Patient.Age = 17;
              HDR.Patient.Sex = 1;	% male
            case 3,
              HDR.Patient.Age = 10;
              HDR.Patient.Sex = 1;	% male
          end;
        elseif strcmp(t1,'Channels')
          for k=1:HDR.NS,
            [HDR.Label{k},t2] = strtok(t2,',');
          end;
        end;
      end;
    end;
    %        	fclose(fid);
    
    n = length(HDR.FEPI.ListOfDataFiles);
    HDR.FEPI.SEG = repmat(NaN,n,2);
    K = 0; 		% event counter
    for k = 1:n;
      tmp = HDR.FEPI.ListOfDataFiles{k};
      f1  = fullfile(HDR.FILE.Path,[tmp,'.bin']);
      f2  = fullfile(HDR.FILE.Path,[tmp,'.info']);
      fid = fopen(f2,'r');
      if fid>0,
        STATUS = 0;
        while ~feof(fid)
          line = fgetl(fid);
          if strcmp(line,'[INFORMATIONS]')
            STATUS = 1;
          elseif strcmp(line,'[EVENT]')
            STATUS = 2;
          end
          
          line = fgetl(fid);
          if ischar(line) && ~isempty(line),
            switch STATUS,
              case 1,
                [t1,r] = strtok(line,[10,13,'=']);
                [t2,r] = strtok(r,[10,13,'=']);
                num    = str2double(t2);
                if strcmp(t1,'FirstSample')
                  HDR.FEPI.SEG(k,1) = num;
                elseif strcmp(t1,'LastSample')
                  HDR.FEPI.SEG(k,2) = num;
                end;
              case 2,
                [t1,r] = strtok(line,',');
                [t2,r] = strtok(r,',');
                [t3,r] = strtok(t2,': ');
                [t4,r] = strtok(r,': ()');
                num = str2double(t1);
                K = K+1;
                HDR.EVENT.POS(K,1) = num;
                tmp = 0;
                if ~isempty(t4),
                  tmp = strmatch(t4,HDR.Label);
                end;
                if isempty(tmp), tmp=0; end;
                HDR.EVENT.CHN(K,1) = tmp;
                %HDR.EVENT.Desc{K,1} = t2;
                Desc{K,1} = t4;
                
                % according to https://epilepsy.uni-freiburg.de/seizure-prediction-workshop-2007/prediction-contest/data-download/the-datareader
                % ESO (Electrographic seizure onset): Type 1
                % EST (Electrographic seizure termination): Type 3
                % CSO (Clinical Seizure Onset): Type 5
                % CSO NA (Clinical Seizure Onset not available): Type 7
                % CST (Clinical Seizure Termination): Type 8
                % CST NA (Clinical Seizure Termination not available): Type  10
                % SSO (Subclinical Seizure Onset): Type 11
                % SST (Subclinical Seizure Termination): Type 14
                % STS (Start of Stimulation Interval): Type 17
                % STE (End of Stimulation Interval): Type 18
                % ART (Artefact): Type 19
                % MRX (Measurement Range Exceeded): Type 21
                % EBD (Electrode Box Disconnected): Type 24
                % EBR (Electrode Box Reconnected): Type 25
                % No Data (Gap in the Recording): Type 26
                
                if 0,
                elseif strncmp(t2,'ESO',3), typ = 1;
                elseif strncmp(t2,'EST',3), typ = 3;
                elseif strncmp(t2,'CSO NA',6), typ = 7;
                elseif strncmp(t2,'CSO',3), typ = 5;
                elseif strncmp(t2,'CST NA',6), typ = 10;
                elseif strncmp(t2,'CST',3), typ = 8;
                elseif strncmp(t2,'SSO',3), typ = 11;
                elseif strncmp(t2,'SST',3), typ = 14;
                elseif strncmp(t2,'STS',3), typ = 17;
                elseif strncmp(t2,'STE',3), typ = 18;
                  
                elseif strncmp(t2,'ART',3), typ = 19;
                elseif strncmp(t2,'MRX',3), typ = 21;
                elseif strncmp(t2,'EBD',3), typ = 24;
                elseif strncmp(t2,'EBR',3), typ = 25;
                elseif strncmp(t2,'No Data',3), typ = 26;
                else typ = 0;
                end;
                HDR.EVENT.TYP(K,1) = typ;
                HDR.EVENT.CodeDesc{typ} = t2;
            end;
          end;
        end;
        fclose(fid);
      end;
    end;
    HDR.EVENT.DUR = zeros(size(HDR.EVENT.POS));
    
    x = [NaN;HDR.FEPI.SEG(1:end-1,2)-HDR.FEPI.SEG(2:end,1)+1];
    if  any(x),
      for k=1:n,
        fprintf(1,'%s\t%10i %10i %10i\n', HDR.FEPI.ListOfDataFiles{k},HDR.FEPI.SEG(k,:),x(k));
      end;
    end;
    
    HDR.Cal = HDR.Cal(1); 	% hack for pat2
    HDR.Calib = sparse(2:HDR.NS+1,1:HDR.NS,HDR.Cal);
    HDR.FILE.OPEN = 1;
    HDR.FILE.POS  = 0;
    HDR.NRec = 1;
    HDR.SPR  = HDR.FEPI.SEG(end,2);
    HDR.AS.endpos = HDR.FEPI.SEG(end,2);
  end;
  