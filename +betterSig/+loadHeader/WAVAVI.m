function [HDR, immediateReturn] = WAVAVI(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 if ~isempty(findstr(HDR.FILE.PERMISSION,'r')),		%%%%% READ
    if strcmp(HDR.TYPE,'AIF')
      HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-be');
    else
      HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
    end;
    
    tmp = char(fread(HDR.FILE.FID,[1,4],'uint8'));
    if ~strcmpi(tmp,'FORM') && ~strcmpi(tmp,'RIFF')
      fprintf(HDR.FILE.stderr,'Warning SOPEN AIF/WAV-format: file %s might be corrupted 1\n',HDR.FileName);
    end;
    tagsize  = fread(HDR.FILE.FID,1,'uint32');        % which size
    tagsize0 = tagsize + rem(tagsize,2);
    tmp = char(fread(HDR.FILE.FID,[1,4],'uint8'));
    if ~strncmpi(tmp,'AIF',3) && ~strncmpi(tmp,'WAVE',4) && ~strncmpi(tmp,'AVI ',4),
      % not (AIFF or AIFC or WAVE)
      fprintf(HDR.FILE.stderr,'Warning SOPEN AIF/WAF-format: file %s might be corrupted 2\n',HDR.FileName);
    end;
    
    [tmp,c] = fread(HDR.FILE.FID,[1,4],'uint8');
    while ~feof(HDR.FILE.FID),
      tag     = char(tmp);
      tagsize = fread(HDR.FILE.FID,1,'uint32');        % which size
      tagsize0= tagsize + rem(tagsize,2);
      filepos = ftell(HDR.FILE.FID);
      
      %%%% AIF - section %%%%%
      if strcmpi(tag,'COMM')
        if tagsize<18,
          fprintf(HDR.FILE.stderr,'Error SOPEN AIF: incorrect tag size\n');
          return;
        end;
        HDR.NS   = fread(HDR.FILE.FID,1,'uint16');
        HDR.SPR  = fread(HDR.FILE.FID,1,'uint32');
        HDR.AS.endpos = HDR.SPR;
        HDR.Bits = fread(HDR.FILE.FID,1,'uint16');
        %HDR.GDFTYP = ceil(HDR.Bits/8)*2-1; % unsigned integer of approbriate size;
        if HDR.Bits == 8;
          HDR.GDFTYP = 'uint8';
        elseif HDR.Bits == 16;
          HDR.GDFTYP = 'uint16';
        elseif HDR.Bits == 32;
          HDR.GDFTYP = 'uint32';
        else
          HDR.GDFTYP = ['ubit', int2str(HDR.Bits)];
        end;
        HDR.Cal  = 2^(1-HDR.Bits);
        HDR.Off  = 0;
        HDR.AS.bpb = ceil(HDR.Bits/8)*HDR.NS;
        
        % HDR.SampleRate; % construct Extended 80bit IEEE 754 format
        tmp = fread(HDR.FILE.FID,1,'int16');
        sgn = sign(tmp);
        if tmp(1)>= 2^15; tmp(1)=tmp(1)-2^15; end;
        e = tmp - 2^14 + 1;
        tmp = fread(HDR.FILE.FID,2,'uint32');
        HDR.SampleRate = sgn * (tmp(1)*(2^(e-31))+tmp(2)*2^(e-63));
        HDR.Dur = HDR.SPR/HDR.SampleRate;
        HDR.FILE.TYPE = 0;
        
        if tagsize>18,
          [tmp,c] = fread(HDR.FILE.FID,[1,4],'uint8');
          HDR.AIF.CompressionType = char(tmp);
          [tmp,c] = fread(HDR.FILE.FID,[1,tagsize-18-c],'uint8');
          HDR.AIF.CompressionName = tmp;
          
          if strcmpi(HDR.AIF.CompressionType,'NONE');
          elseif strcmpi(HDR.AIF.CompressionType,'fl32');
            HDR.GDFTYP = 'uint16';
            HDR.Cal = 1;
          elseif strcmpi(HDR.AIF.CompressionType,'fl64');
            HDR.GDFTYP = 'float64';
            HDR.Cal = 1;
          elseif strcmpi(HDR.AIF.CompressionType,'alaw');
            HDR.GDFTYP = 'uint8';
            HDR.AS.bpb = HDR.NS;
            %HDR.FILE.TYPE = 1;
            fprintf(HDR.FILE.stderr,'Warning SOPEN AIFC-format: data not scaled because of CompressionType ALAW\n');
            HDR.FLAG.UCAL = 1;
          elseif strcmpi(HDR.AIF.CompressionType,'ulaw');
            HDR.GDFTYP = 'uint8';
            HDR.AS.bpb = HDR.NS;
            HDR.FILE.TYPE = 1;
            
            %%%% other compression types - currently not supported, probably obsolete
            %elseif strcmpi(HDR.AIF.CompressionType,'DWVW');
            %elseif strcmpi(HDR.AIF.CompressionType,'GSM');
            %elseif strcmpi(HDR.AIF.CompressionType,'ACE2');
            %elseif strcmpi(HDR.AIF.CompressionType,'ACE8');
            %elseif strcmpi(HDR.AIF.CompressionType,'ima4');
            %elseif strcmpi(HDR.AIF.CompressionType,'MAC3');
            %elseif strcmpi(HDR.AIF.CompressionType,'MAC6');
            %elseif strcmpi(HDR.AIF.CompressionType,'Qclp');
            %elseif strcmpi(HDR.AIF.CompressionType,'QDMC');
            %elseif strcmpi(HDR.AIF.CompressionType,'rt24');
            %elseif strcmpi(HDR.AIF.CompressionType,'rt29');
          else
            fprintf(HDR.FILE.stderr,'Warning SOPEN AIFC-format: CompressionType %s is not supported\n', HDR.AIF.CompressionType);
          end;
        end;
        
      elseif strcmpi(tag,'SSND');
        HDR.AIF.offset   = fread(HDR.FILE.FID,1,'int32');
        HDR.AIF.blocksize= fread(HDR.FILE.FID,1,'int32');
        HDR.AIF.SSND.tagsize = tagsize-8;
        
        HDR.HeadLen = filepos+8;
        %HDR.AIF.sounddata= fread(HDR.FILE.FID,tagsize-8,'uint8');
        
      elseif strcmpi(tag,'FVER');
        if tagsize<4,
          fprintf(HDR.FILE.stderr,'Error SOPEN WAV: incorrect tag size\n');
          return;
        end;
        HDR.AIF.TimeStamp   = fread(HDR.FILE.FID,1,'uint32');
        
      elseif strcmp(tag,'DATA') && strcmp(HDR.TYPE,'AIF') ;	% AIF uses upper case, there is a potential conflict with WAV using lower case data
        HDR.AIF.DATA  = fread(HDR.FILE.FID,[1,tagsize],'uint8');
        
      elseif strcmpi(tag,'INST');   % not sure if this is ok !
        %HDR.AIF.INST  = fread(HDR.FILE.FID,[1,tagsize],'uint8');
        %HDR.AIF.INST.notes  = fread(HDR.FILE.FID,[1,6],'uint8');
        HDR.AIF.INST.baseNote  = fread(HDR.FILE.FID,1,'uint8');
        HDR.AIF.INST.detune    = fread(HDR.FILE.FID,1,'uint8');
        HDR.AIF.INST.lowNote   = fread(HDR.FILE.FID,1,'uint8');
        HDR.AIF.INST.highNote  = fread(HDR.FILE.FID,1,'uint8');
        HDR.AIF.INST.lowvelocity  = fread(HDR.FILE.FID,1,'uint8');
        HDR.AIF.INST.highvelocity = fread(HDR.FILE.FID,1,'uint8');
        HDR.AIF.INST.gain      = fread(HDR.FILE.FID,1,'int16');
        
        HDR.AIF.INST.sustainLoop_PlayMode = fread(HDR.FILE.FID,1,'uint8');
        HDR.AIF.INST.sustainLoop = fread(HDR.FILE.FID,2,'uint16');
        HDR.AIF.INST.releaseLoop_PlayMode = fread(HDR.FILE.FID,1,'uint8');
        HDR.AIF.INST.releaseLoop = fread(HDR.FILE.FID,2,'uint16');
        
      elseif strcmpi(tag,'MIDI');
        HDR.AIF.MIDI = fread(HDR.FILE.FID,[1,tagsize],'uint8');
        
      elseif strcmpi(tag,'AESD');
        HDR.AIF.AESD = fread(HDR.FILE.FID,[1,tagsize],'uint8');
        
      elseif strcmpi(tag,'APPL');
        HDR.AIF.APPL = fread(HDR.FILE.FID,[1,tagsize],'uint8');
        
      elseif strcmpi(tag,'COMT');
        HDR.AIF.COMT = fread(HDR.FILE.FID,[1,tagsize],'uint8');
        
      elseif strcmpi(tag,'ANNO');
        HDR.AIF.ANNO = char(fread(HDR.FILE.FID,[1,tagsize],'uint8'));
        
      elseif strcmpi(tag,'(c) ');
        [HDR.Copyright,c] = fread(HDR.FILE.FID,[1,tagsize],'uint8=>char');
        
        %%%% WAV - section %%%%%
      elseif strcmpi(tag,'fmt ')
        if tagsize<14,
          fprintf(HDR.FILE.stderr,'Error SOPEN WAV: incorrect tag size\n');
          return;
        end;
        HDR.WAV.Format = fread(HDR.FILE.FID,1,'uint16');
        HDR.NS = fread(HDR.FILE.FID,1,'uint16');
        HDR.SampleRate = fread(HDR.FILE.FID,1,'uint32');
        HDR.WAV.AvgBytesPerSec = fread(HDR.FILE.FID,1,'uint32');
        HDR.WAV.BlockAlign = fread(HDR.FILE.FID,1,'uint16');
        if HDR.WAV.Format==1,	% PCM format
          HDR.Bits = fread(HDR.FILE.FID,1,'uint16');
          HDR.Off = 0;
          HDR.Cal = 2^(1-8*ceil(HDR.Bits/8));
          if HDR.Bits<=8,
            HDR.GDFTYP = 'uint8';
            HDR.Off =  1;
            %HDR.Cal = HDR.Cal*2;
          elseif HDR.Bits<=16,
            HDR.GDFTYP = 'int16';
          elseif HDR.Bits<=24,
            HDR.GDFTYP = 'bit24';
          elseif HDR.Bits<=32,
            HDR.GDFTYP = 'int32';
          end;
        else
          fprintf(HDR.FILE.stderr,'Error SOPEN WAV: format type %i not supported\n',HDR.WAV.Format);
          fclose(HDR.FILE.FID);
          return;
        end;
        if tagsize>16,
          HDR.WAV.cbSize = fread(HDR.FILE.FID,1,'uint16');
        end;
        
      elseif strcmp(tag,'data') && strcmp(HDR.TYPE,'WAV') ;	% AIF uses upper case, there is a potential conflict with WAV using lower case data
        HDR.HeadLen = filepos;
        if HDR.WAV.Format == 1,
          HDR.AS.bpb = HDR.NS * ceil(HDR.Bits/8);
          HDR.SPR = tagsize/HDR.AS.bpb;
          HDR.Dur = HDR.SPR/HDR.SampleRate;
          
        else
          fprintf(HDR.FILE.stderr,'Error SOPEN WAV: format type %i not supported\n',HDR.WAV.Format);
        end;
        
      elseif strcmpi(tag,'fact');
        if tagsize<4,
          fprintf(HDR.FILE.stderr,'Error SOPEN WAV: incorrect tag size\n');
          return;
        end;
        [HDR.RIFF.FACT,c] = fread(HDR.FILE.FID,[1,tagsize],'uint8=>char');
        
      elseif strcmpi(tag,'disp');
        if tagsize<8,
          fprintf(HDR.FILE.stderr,'Error SOPEN WAV: incorrect tag size\n');
          return;
        end;
        [tmp,c] = fread(HDR.FILE.FID,[1,tagsize],'uint8=>char');
        HDR.RIFF.DISP = char(tmp);
        if ~all(tmp(1:8)==[0,1,0,0,0,0,1,1])
          HDR.RIFF.DISPTEXT = char(tmp(5:length(tmp)));
        end;
        
      elseif strcmpi(tag,'list');
        if tagsize<4,
          fprintf(HDR.FILE.stderr,'Error SOPEN WAV: incorrect tag size\n');
          return;
        end;
        
        if ~isfield(HDR,'RIFF');
          HDR.RIFF.N1 = 1;
        elseif ~isfield(HDR.RIFF,'N');
          HDR.RIFF.N1 = 1;
        else
          HDR.RIFF.N1 = HDR.RIFF.N1+1;
        end;
        
        %HDR.RIFF.list = char(tmp);
        [tag,c1]  = fread(HDR.FILE.FID,[1,4],'uint8');
        tag = char(tag);
        [val,c2]  = fread(HDR.FILE.FID,[1,tagsize-4],'uint8');
        HDR.RIFF = setfield(HDR.RIFF,tag,char(val));
        if 1,
        elseif strcmp(tag,'INFO'),
          HDR.RIFF.INFO=val;
        elseif strcmp(tag,'movi'),
          HDR.RIFF.movi = val;
        elseif strcmp(tag,'hdrl'),
          HDR.RIFF.hdr1 = val;
          
        elseif 0,strcmp(tag,'mdat'),
          %HDR.RIFF.mdat = val;
        else
          fprintf(HDR.FILE.stderr,'Warning SOPEN Type=RIFF: unknown Tag %s.\n',tag);
        end;
        % AVI  audio video interleave format
      elseif strcmpi(tag,'movi');
        if tagsize<4,
          fprintf(HDR.FILE.stderr,'Error SOPEN AVI: incorrect tag size\n');
          return;
        end;
        [HDR.RIFF.movi,c] = fread(HDR.FILE.FID,[1,tagsize],'uint8=>char');
        
      elseif strcmp(tag,'idx1');
        if tagsize<4,
          fprintf(HDR.FILE.stderr,'Error SOPEN AVI: incorrect tag size\n');
          return;
        end;
        [HDR.RIFF.idx1,c] = fread(HDR.FILE.FID,[1,tagsize],'uint8=>char');
        
      elseif strcmpi(tag,'junk');
        if tagsize<4,
          fprintf(HDR.FILE.stderr,'Error SOPEN AVI: incorrect tag size\n');
          return;
        end;
        [HDR.RIFF.junk,c] = fread(HDR.FILE.FID,[1,tagsize],'uint8=>char');
        
      elseif strcmpi(tag,'MARK');
        if tagsize<4,
          fprintf(HDR.FILE.stderr,'Error SOPEN AVI: incorrect tag size\n');
          return;
        end;
        [HDR.RIFF.MARK,c] = fread(HDR.FILE.FID,[1,tagsize],'uint8=>char');
        
      elseif strcmpi(tag,'AUTH');
        if tagsize<4,
          fprintf(HDR.FILE.stderr,'Error SOPEN AVI: incorrect tag size\n');
          return;
        end;
        [HDR.RIFF.AUTH,c] = fread(HDR.FILE.FID,[1,tagsize],'uint8=>char');
        
      elseif strcmpi(tag,'NAME');
        if tagsize<4,
          fprintf(HDR.FILE.stderr,'Error SOPEN AVI: incorrect tag size\n');
          return;
        end;
        [HDR.RIFF.NAME,c] = fread(HDR.FILE.FID,[1,tagsize],'uint8=>char');
        
      elseif strcmpi(tag,'afsp');
        if tagsize<4,
          fprintf(HDR.FILE.stderr,'Error SOPEN AVI: incorrect tag size\n');
          return;
        end;
        [HDR.RIFF.afsp,c] = fread(HDR.FILE.FID,[1,tagsize],'uint8=>char');
        
      elseif ~isempty(tagsize)
        fprintf(HDR.FILE.stderr,'Warning SOPEN AIF/WAV: unknown TAG in %s: %s(%i) \n',HDR.FileName,tag,tagsize);
        [tmp,c] = fread(HDR.FILE.FID,[1,min(100,tagsize)],'uint8');
        fprintf(HDR.FILE.stderr,'%s\n',char(tmp));
      end;
      
      if ~isempty(tagsize)
        status = fseek(HDR.FILE.FID,filepos+tagsize0,'bof');
        if status,
          fprintf(HDR.FILE.stderr,'Warning SOPEN (WAF/AIF/AVI): fseek failed. Probably tagsize larger than end-of-file and/or file corrupted\n');
          fseek(HDR.FILE.FID,0,'eof');
        end;
      end;
      [tmp,c] = fread(HDR.FILE.FID,[1,4],'uint8');
    end;
    
    if strncmpi(char(tmp),'AIF',3),
      if HDR.AIF.SSND.tagsize~=HDR.SPR*HDR.AS.bpb,
        fprintf(HDR.FILE.stderr,'Warning SOPEN AIF: Number of samples do not fit %i vs %i\n',tmp,HDR.SPR);
      end;
    end;
    
    if ~isfield(HDR,'HeadLen')
      fprintf(HDR.FILE.stderr,'Warning SOPEN AIF/WAV: missing data section\n');
    else
      status = fseek(HDR.FILE.FID, HDR.HeadLen, 'bof');
    end;
    
    if isnan(HDR.NS), return; end;
    [d,l,d1,b,HDR.GDFTYP] = gdfdatatype(HDR.GDFTYP);
    
    % define Calib: implements S = (S+.5)*HDR.Cal - HDR.Off;
    HDR.Calib = [repmat(.5,1,HDR.NS);eye(HDR.NS)] * diag(repmat(HDR.Cal,1,HDR.NS));
    HDR.Calib(1,:) = HDR.Calib(1,:) - HDR.Off;
    HDR.Label = repmat({' '},HDR.NS,1);
    
    HDR.FILE.POS = 0;
    HDR.FILE.OPEN = 1;
    HDR.NRec = 1;
    
    
  elseif ~isempty(findstr(HDR.FILE.PERMISSION,'w')),	%%%%% WRITE
    if any(HDR.FILE.PERMISSION=='z'),
      fprintf(HDR.FILE.stderr,'WARNING SOPEN (AIF/WAV/IIF,AVI) "wz": Writing to gzipped AIF file not supported (yet).\n');
      HDR.FILE.PERMISSION = 'w';
    end;
    if strcmp(HDR.TYPE,'AIF')
      HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-be');
    else
      HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
    end;
    HDR.FILE.OPEN = 3;
    if strcmp(HDR.TYPE,'AIF')
      fwrite(HDR.FILE.FID,'FORM','uint8');
      fwrite(HDR.FILE.FID,0,'uint32');
      fwrite(HDR.FILE.FID,'AIFFCOMM','uint8');
      fwrite(HDR.FILE.FID,18,'uint32');
      fwrite(HDR.FILE.FID,HDR.NS,'uint16');
      fwrite(HDR.FILE.FID,HDR.SPR,'uint32');
      fwrite(HDR.FILE.FID,HDR.Bits,'uint16');
      
      %HDR.GDFTYP = ceil(HDR.Bits/8)*2-1; % unsigned integer of appropriate size;
      HDR.GDFTYP = ['ubit', int2str(HDR.Bits)];
      HDR.Cal    = 2^(1-HDR.Bits);
      HDR.AS.bpb = ceil(HDR.Bits/8)*HDR.NS;
      
      [f,e] = log2(HDR.SampleRate);
      tmp = e + 2^14 - 1;
      if tmp<0, tmp = tmp + 2^15; end;
      fwrite(HDR.FILE.FID,tmp,'uint16');
      fwrite(HDR.FILE.FID,[bitshift(abs(f),31),bitshift(abs(f),63)],'uint32');
      
      HDR.AS.bpb = HDR.NS * ceil(HDR.Bits/8);
      tagsize = HDR.SPR*HDR.AS.bpb + 8;
      HDR.Dur = HDR.SPR/HDR.SampleRate;
      HDR.AS.endpos = HDR.SPR;
      
      if 0; isfield(HDR.AIF,'INST');	% does not work yet
        fwrite(HDR.FILE.FID,'SSND','uint8');
        fwrite(HDR.FILE.FID,20,'uint32');
        
        fwrite(HDR.FILE.FID,HDR.AIF.INST.baseNote,'uint8');
        fwrite(HDR.FILE.FID,HDR.AIF.INST.detune,'uint8');
        fwrite(HDR.FILE.FID,HDR.AIF.INST.lowNote,'uint8');
        fwrite(HDR.FILE.FID,HDR.AIF.INST.highNote,'uint8');
        fwrite(HDR.FILE.FID,HDR.AIF.INST.lowvelocity,'uint8');
        fwrite(HDR.FILE.FID,HDR.AIF.INST.highvelocity,'uint8');
        fwrite(HDR.FILE.FID,HDR.AIF.INST.gain,'int16');
        
        fwrite(HDR.FILE.FID,HDR.AIF.INST.sustainLoop_PlayMode,'uint8');
        fwrite(HDR.FILE.FID,HDR.AIF.INST.sustainLoop,'uint16');
        fwrite(HDR.FILE.FID,HDR.AIF.INST.releaseLoop_PlayMode,'uint8');
        fwrite(HDR.FILE.FID,HDR.AIF.INST.releaseLoop,'uint16');
      end;
      
      fwrite(HDR.FILE.FID,'SSND','uint8');
      HDR.WAV.posis = [4, ftell(HDR.FILE.FID)];
      fwrite(HDR.FILE.FID,[tagsize,0,0],'uint32');
      
      HDR.HeadLen = ftell(HDR.FILE.FID);
      
    elseif  strcmp(HDR.TYPE,'WAV'),
      fwrite(HDR.FILE.FID,'RIFF','uint8');
      fwrite(HDR.FILE.FID,0,'uint32');
      fwrite(HDR.FILE.FID,'WAVEfmt ','uint8');
      fwrite(HDR.FILE.FID,16,'uint32');
      fwrite(HDR.FILE.FID,[1,HDR.NS],'uint16');
      fwrite(HDR.FILE.FID,[HDR.SampleRate,HDR.Bits/8*HDR.NS*HDR.SampleRate],'uint32');
      fwrite(HDR.FILE.FID,[HDR.Bits/8*HDR.NS,HDR.Bits],'uint16');
      
      if isfield(HDR,'Copyright'),
        fwrite(HDR.FILE.FID,'(c) ','uint8');
        if rem(length(HDR.Copyright),2),
          HDR.Copyright(length(HDR.Copyright)+1)=' ';
        end;
        fwrite(HDR.FILE.FID,length(HDR.Copyright),'uint32');
        fwrite(HDR.FILE.FID,HDR.Copyright,'uint8');
      end;
      
      HDR.Off = 0;
      HDR.Cal = 2^(1-8*ceil(HDR.Bits/8));
      if HDR.Bits<=8,
        HDR.GDFTYP = 'uint8';
        HDR.Off =  1;
        %HDR.Cal = HDR.Cal*2;
      elseif HDR.Bits<=16,
        HDR.GDFTYP = 'int16';
      elseif HDR.Bits<=24,
        HDR.GDFTYP = 'bit24';
      elseif HDR.Bits<=32,
        HDR.GDFTYP = 'int32';
      end;
      
      HDR.AS.bpb = HDR.NS * ceil(HDR.Bits/8);
      tagsize = HDR.SPR*HDR.AS.bpb;
      HDR.Dur = HDR.SPR/HDR.SampleRate;
      HDR.AS.endpos = HDR.SPR;
      
      fwrite(HDR.FILE.FID,'data','uint8');
      HDR.WAV.posis=[4,ftell(HDR.FILE.FID)];
      fwrite(HDR.FILE.FID,tagsize,'uint32');
      
      if rem(tagsize,2)
        fprintf(HDR.FILE.stderr,'Error SOPEN WAV: data section has odd number of samples.\n. This violates the WAV specification\n');
        fclose(HDR.FILE.FID);
        HDR.FILE.OPEN = 0;
        return;
      end;
      
      HDR.HeadLen = ftell(HDR.FILE.FID);
    end;
  end;