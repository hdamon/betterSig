function [HDR, immediateReturn] =MIT_ATR(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 tmp = dir(fullfile(HDR.FILE.Path,[HDR.FILE.Name,'.hea']));
  if isempty(tmp)
    tmp = dir(fullfile(HDR.FILE.Path,[HDR.FILE.Name,'.HEA']));
  end;
  if isempty(tmp)
    fprintf(HDR.FILE.stderr,'Warning SOPEN: no corresponing header file found for MIT-ATR EVENT file %s.\n',HDR.FileName);
  end;
  
  %------ LOAD ATTRIBUTES DATA ----------------------------------------------
  fid = fopen(HDR.FileName,'rb','ieee-le');
  if fid<0,
    A = 0; c = 0;
  else
    [A,c] = fread(fid, inf, 'uint16');
    fclose(fid);
  end;
  
  EVENTTABLE = repmat(NaN,c,3);
  Desc = repmat({''},ceil(c),1);
  FLAG63 = 0;
  K  = 0;
  i  = 1;
  ch = 0;
  accu = 0;
  
  tmp = floor(A(:)/1024);
  annoth = tmp;
  L   = A(:) - tmp*1024;
  tmp = floor(A(:)/256);
  t0  = char([A(:)-256*tmp, tmp])';
  while ((i<=size(A,1)) && (A(i)>0)),
    a = annoth(i);
    if a==0,  % end of file
      
    elseif a<50,
      K = K + 1;
      accu = accu + L(i);
      EVENTTABLE(K,:) = [a,accu,ch];
    elseif a==59,	% SKIP
      if (L(i)==0),
        accu = accu + (2.^[0,16])*[A(i+2);A(i+1)];
        i = i + 2;
      else
        accu = accu + L(i);
      end;
      %elseif a==60,	% NUM
      %[60,L,A(i)]
      % nothing to do!
      %elseif a==61,	% SUB
      %[61,L,A(i)]
      % nothing to do!
    elseif a==62,	% CHN
      ch = L(i);
    elseif a==63,	% AUX
      c = ceil(L(i)/2);
      t = t0(:,i+1:i+c)';
      Desc{K} = t(:)';
      FLAG63 = 1;
      i = i + c;
    end;
    i = i + 1;
  end;
  HDR.EVENT.TYP = EVENTTABLE(1:K,1); % + hex2dec('0540');
  HDR.EVENT.POS = EVENTTABLE(1:K,2);
  HDR.EVENT.CHN = EVENTTABLE(1:K,3);
  HDR.EVENT.DUR = zeros(K,1);
  if FLAG63, HDR.EVENT.Desc = Desc(1:K); end;
  HDR.TYPE = 'EVENT';
  
  