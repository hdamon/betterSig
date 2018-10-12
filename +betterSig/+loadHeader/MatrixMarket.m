function [HDR, immediateReturn] = MatrixMarket(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 if (HDR.FILE.PERMISSION=='r')
    fid = fopen(HDR.FileName,HDR.FILE.PERMISSION,'ieee-le');
    K = 0;
    status = 0;
    while ~feof(fid);
      line = fgetl(fid);
      if length(line)<3,
        ;
      elseif all(line(1:2)=='%') && isspace(line(3)),
        if strncmp(line,'%% LABELS',9)
          status = 1;
        elseif strncmp(line,'%% ENDLABEL',11)
          status = 0;
        elseif status,
          k=3;
          while (isspace(line(k))) k=k+1; end;
          [t,r] = strtok(line(k:end),char([9,32]));
          ch = str2double(t);
          k = 1;
          while (isspace(r(k))) k=k+1; end;
          r = r(k:end);
          k = length(r);
          while (isspace(r(k))) k=k-1; end;
          HDR.Label{ch} = r(1:k);
        end;
      elseif (line(1)=='%')
        ;
      else
        [n,v,sa] = str2double(line);
        K = K+1;
        if (K==1)
          HDR.Calib = sparse([],[],[],n(1),n(2),n(3));
        else
          HDR.Calib(n(1),n(2))=n(3);
        end;
      end;
    end;
    fclose(fid);
    HDR.FILE.FID = fid;
    
  elseif (HDR.FILE.PERMISSION=='w')
    fid = fopen(HDR.FileName,HDR.FILE.PERMISSION,'ieee-le');
    
    [I,J,V] = find(HDR.Calib);
    fprintf(fid,'%%%%MatrixMarket matrix coordinate real general\n');
    fprintf(fid,'%% generated on %04i-%02i-%02i %02i:%02i:%02.0f\n',clock);
    fprintf(fid,'%% Spatial Filter for EEG/BioSig data\n%%\n');
    if isfield(HDR,'Label')
      fprintf(fid,'%%%% LABELS [for channels in target file]\n');
      for k = 1:length(HDR.Label),
        fprintf(fid,'%%%%\t%i\t%s\n', k, HDR.Label{k});
      end;
      fprintf(fid,'%%%% ENDLABELS\n');
    end
    if isfield(HDR,'NumberOfSamplesUsed')
      %%% used when matrix contain correction coefficients for e.g. eog artifacts, then this value
      %%% should contain the number of samples used for estimating these correction coefficients.
      %%% It can be used for quality control, whether the coefficients are reliable or not.
      fprintf(fid,'%%%% NumberOfSamplesUsed: %i\n',HDR.NumberOfSamplesUsed);
    end;
    fprintf(fid,'%%\n%%============================================\n%i %i %i\n',size(HDR.Calib),length(V));
    for k = 1:length(V),
      fprintf(fid,'%2i %2i %.18e\n',I(k),J(k),V(k));
    end;
    fclose(fid);
    
  end;
  