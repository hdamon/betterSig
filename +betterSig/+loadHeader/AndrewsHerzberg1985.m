function [HDR, immediateReturn] = AndrewsHerzberg1985(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 s = HDR.s;
  ix1 = find((s==10) | (s==13)); % line breaks
  ix2 = find(s>'@');	% letters
  ix3 = [];
  for k=2:length(ix1)
    if any(s(ix1(k-1)+1:ix1(k))>64) && (s(ix1(k-1)+1)==' ')
      ix3 = [ix3,k-1];
      HDR.Label{length(ix3)} = s(ix1(k-1)+1:ix1(k)-1);
      t = str2double(s(ix1(k-2)+1:ix1(k-1)-1));
      if length(t)>1, t=t(2); end;
      HDR.AS.SPR(length(ix3)) = t;
    end;
  end;
  ix3 = [ix3,length(ix1)];
  for k=1:length(ix3)-1
    t = str2double(s(ix1(ix3(k)+2)+1:ix1(ix3(k+1)-1)))';
    HDR.data{k} = t(1:HDR.AS.SPR(k));
  end;