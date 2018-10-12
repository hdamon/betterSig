function [HDR, immediateReturn] = ASCII_IBI(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = true; % Default Value


 fid = fopen(HDR.FileName,'r');
  line = fgetl(fid);
  N = 0;
  HDR.SampleRate = 1000;
  HDR.EVENT.SampleRate = 1000;
  HDR.EVENT.POS = [];
  HDR.EVENT.TYP = [];
  DescList = {};
  %%	while (~isempty(line))
  while (length(line)>5)
    if ((line(1)<'0') || (line(1)>'9'))
      f=deblank(strtok(line,':'));
      v=deblank(strtok(line,':'));
      if strcmp(f,'File version')
        HDR.VERSION = str2double(v);
      elseif strcmp(f,'Identification')
        HDR.Patient.Name = v;
      end;
    else
      N = N+1;
      if (N>length(HDR.EVENT.POS))
        HDR.EVENT.POS = [HDR.EVENT.POS;zeros(2^12,1)];
        HDR.EVENT.TYP = [HDR.EVENT.TYP;zeros(2^12,1)];
      end;
      if exist('OCTAVE_VERSION','builtin')
        [y,mo,dd,hh,mi,se,ms,desc,rri,count]=sscanf(line,'%02u-%02u-%02u %02u:%02u:%02u %03u %s %f','C');
        y = [y,mo,dd,hh,mi,se,ms];
      else
        [y,COUNT,ERRMSG,NEXTINDEX1] = sscanf(line,'%02u-%02u-%02u %02u:%02u:%02u %03u',7);
        [desc,COUNT,ERRMSG,NEXTINDEX2] = sscanf(line(NEXTINDEX1:end),'%s',1);
        [rri,COUNT,ERRMSG,NEXTINDEX] = sscanf(line(NEXTINDEX1+NEXTINDEX2-1:end),'%4i',1);
      end;
      
      %% t = datenum(y,mo,dd,hh,mi,se+ms/1000);
      if (N==1)
        if y(3)<70, y(3)=y(3)+2000;
        else   y(3)=y(3)+1900;
        end;
        HDR.T0 = [y(3),y(2),y(1),y(4),y(5),y(6)+(y(7)-rri)/1000];
        HDR.EVENT.POS = [0;rri];
        HDR.EVENT.TYP = [1;1]*hex2dec('0501');
        N = 2;
      else
        HDR.EVENT.POS(N) = HDR.EVENT.POS(N-1)+rri;
        HDR.EVENT.TYP(N) = hex2dec('0501');
      end;
      %% ix = strmatch(desc,DescList,'exact');
      %% if isempty(ix)
      %%	DescList{end+1}=desc;
      %%	ix = length(DescList);
      %% end;
      %% HDR.EVENT.TYP(N) = ix;
    end;
    line = fgetl(fid);
  end
  fclose(fid);
  HDR.EVENT.POS = HDR.EVENT.POS(1:N);
  HDR.EVENT.TYP = HDR.EVENT.TYP(1:N);
  HDR.EVENT.CodeDesc = DescList;
  % HDR.EVENT.CodeIndex = [1:length(DescList)]';
  HDR.TYPE = 'EVENT';