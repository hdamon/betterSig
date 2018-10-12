function [HDR, immediateReturn] = TMIiLOG(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


if any(HDR.FILE.PERMISSION=='r'),
    %fid = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
    %H1  = fread(fid,[1,inf],'uint8=>char');
    %fclose(fid);
    %getfiletype read whole header file into HDR.H1
    GDFTYP   = 0;
    HDR.SPR  = 1;
    HDR.NRec = 1;
    [line,r] = strtok(HDR.H1,[13,10]);
    ix = find(line=='=');
    while ~isempty(ix)
      tag = line(1:ix-1);
      val = deblank(line(ix+1:end));
      if strcmp(tag,'DateTime')
        val(val=='/' | val=='-' | val==':') = ' ';
        HDR.T0 = str2double(val);
      elseif strcmp(tag,'Format')
        if     strcmp(val,'Int16') GDFTYP = 3;
        elseif strcmp(val,'Int32') GDFTYP = 5;
        elseif strcmp(val,'Float32') GDFTYP = 16;
        elseif strcmp(val,'Ascii') GDFTYP = -1;
          % else val,abs(val),
        end;
      elseif strcmp(tag,'Length')
        duration = str2double(val);
      elseif strcmp(tag,'Signals')
        HDR.NS = str2double(val);
      elseif strncmp(tag,'Signal',6)
        ch = str2double(tag(7:10));
        HDR.NS = str2double(val);
        if strcmp(tag(12:end),'Name')
          HDR.Label{ch}=val;
        elseif strcmp(tag(12:end),'UnitName')
          HDR.PhysDim{ch}=val;
        elseif strcmp(tag(12:end),'Resolution')
          HDR.Cal(ch)=str2double(val);
        elseif strcmp(tag(12:end),'StoreRate')
          HDR.AS.SampleRate(ch)=str2double(val);
          HDR.AS.SPR = HDR.AS.SampleRate(ch)*duration;
          HDR.SPR    = lcm(HDR.SPR, HDR.AS.SPR);
        elseif strcmp(tag(12:end),'File')
          HDR.TMSi.FN{ch}=val;
        elseif strcmp(tag(12:end),'Index')
        end;
      end;
      [line,r]=strtok(r,[13,10]);
      ix = find(line=='=');
    end;
    
    HDR.Calib   = sparse(2:HDR.NS+1,1:HDR.NS,HDR.Cal);
    HDR.SampleRate = HDR.SPR/duration;
    HDR.GDFTYP  = repmat(GDFTYP,1,HDR.NS);
    HDR.TMSi.FN = unique(HDR.TMSi.FN);
    if length(HDR.TMSi.FN)==1,
      if (GDFTYP>0)
        fid = fopen(fullfile(HDR.FILE.Path,HDR.TMSi.FN{1}),'rb');
        tmp = fread(fid,[1,3],'int16');
        switch tmp(3)
          case {16}
            GDFTYP=3;
          case {32}
            GDFTYP=5;
          case {32+256}
            GDFTYP=16;
        end;
        HDR.data = fread(fid, [HDR.NS,inf], gdfdatatype(GDFTYP))';
        fclose(fid);
        
      elseif (GDFTYP==-1)
        fid  = fopen(fullfile(HDR.FILE.Path,HDR.TMSi.FN{1}),'rt');
        line = fgetl(fid);
        line = fgetl(fid);
        line = fgetl(fid);
        tmp  = fread(fid,[1,inf],'uint8=>char');
        fclose(fid);
        [n,v,sa] = str2double(tmp);
        HDR.data = n(:,2:end);
      end;
    end
    HDR.TYPE = 'native';
  end;
