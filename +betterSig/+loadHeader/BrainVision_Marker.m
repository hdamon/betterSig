function [HDR, immediateReturn] = BrainVision_Marker(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 %read event file
  fid = fopen(HDR.FileName,'rt');
  if fid>0,
    NoSegs = 0;
    while ~feof(fid),
      u = fgetl(fid);
      if strncmp(u,'Mk',2),
        [N,s] = strtok(u(3:end),'=');
        ix = find(s==',');
        ix(length(ix)+1) = length(s)+1;
        N = str2double(N);
        HDR.EVENT.POS(N,1) = str2double(s(ix(2)+1:ix(3)-1));
        HDR.EVENT.TYP(N,1) = 0;
        HDR.EVENT.DUR(N,1) = str2double(s(ix(3)+1:ix(4)-1));
        HDR.EVENT.CHN(N,1) = str2double(s(ix(4)+1:ix(5)-1));
        HDR.EVENT.TeegType{N,1} = s(2:ix(1)-1);
        Desc{N,1} = s(ix(1)+1:ix(2)-1);
        if strncmp('New Segment',s(2:ix(1)-1),4);
          t = s(ix(5)+1:end);
          NoSegs = NoSegs+1;
          HDR.EVENT.Segments{NoSegs}.T0 = str2double(char([t(1:4),32,t(5:6),32,t(7:8),32,t(9:10),32,t(11:12),32,t(13:14)]));
          HDR.EVENT.Segments{NoSegs}.Start = HDR.EVENT.POS(N);
          HDR.EVENT.TYP(N,1) = hex2dec('7ffe');
        end;
        if NoSegs>0,
          HDR.T0 = HDR.EVENT.Segments{1}.T0;
        end;
      end;
    end;
    fclose(fid);
    HDR.TYPE = 'EVENT';
    HDR.EVENT.Desc = Desc;
    [HDR.EVENT.CodeDesc, CodeIndex, j] = unique(Desc);
    ix = (HDR.EVENT.TYP==0);
    HDR.EVENT.TYP(ix) = j(ix);
  end;