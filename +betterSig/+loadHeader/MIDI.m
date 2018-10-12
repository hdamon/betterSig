function [HDR, immediateReturn] = MIDI(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],HDR.Endianity);
  
  if ~isempty(findstr(HDR.FILE.PERMISSION,'r')),		%%%%% READ
    
    [tmp,c] = fread(HDR.FILE.FID,[1,4+12*strcmp(HDR.TYPE,'RMID') ],'uint8');
    tmp = char(tmp(c+(-3:0)));
    if ~strcmpi(tmp,'MThd'),
      fprintf(HDR.FILE.stderr,'Warning SOPEN (MIDI): file %s might be corrupted 1\n',HDR.FileName);
    end;
    
    while ~feof(HDR.FILE.FID),
      tag     = char(tmp);
      tagsize = fread(HDR.FILE.FID,1,'uint32');        % which size
      filepos = ftell(HDR.FILE.FID);
      
      if 0,
        
        %%%% MIDI file format
      elseif strcmpi(tag,'MThd');
        [tmp,c] = fread(HDR.FILE.FID,[1,tagsize/2],'uint16');
        HDR.MIDI.Format = tmp(1);
        HDR.NS = tmp(2);
        if tmp(3)<2^15,
          HDR.SampleRate = tmp(3);
        else
          tmp4 = floor(tmp(3)/256);
          if tmp>127,
            tmp4 = 256-tmp4;
            HDR.SampleRate = (tmp4*rem(tmp(3),256));
          end
        end;
        CurrentTrack = 0;
        
      elseif strcmpi(tag,'MTrk');
        [tmp,c] = fread(HDR.FILE.FID,[1,tagsize],'uint8');
        CurrentTrack = CurrentTrack + 1;
        HDR.MIDI.Track{CurrentTrack} = tmp;
        k = 1;
        while 0,k<c,
          deltatime = 1;
          while tmp(k)>127,
            deltatime = mod(tmp(k),128) + deltatime*128;
            k = k+1;
          end;
          deltatime = tmp(k) + deltatime*128;
          k = k+1;
          status_byte = tmp(k);
          k = k+1;
          
          if any(floor(status_byte/16)==[8:11]), % Channel Mode Message
            databyte = tmp(k:k+1);
            k = k+2;
            
          elseif any(floor(status_byte/16)==[12:14]), % Channel Voice Message
            databyte = tmp(k);
            k = k+1;
            
          elseif any(status_byte==hex2dec(['F0';'F7'])) % Sysex events
            len = 1;
            while tmp(k)>127,
              len = mod(tmp(1),128) + len*128
              k = k+1;
            end;
            len = tmp(k) + len*128;
            data = tmp(k+(1:len));
            
            % System Common Messages
          elseif status_byte==240, % F0
          elseif status_byte==241, % F1
            while tmp(k)<128,
              k = k+1;
            end;
          elseif status_byte==242, % F2
            k = k + 1;
          elseif status_byte==243, % F3
            k = k + 1;
          elseif status_byte==244, % F4
          elseif status_byte==245, % F5
          elseif status_byte==246, % F6
          elseif status_byte==247, % F7
          elseif status_byte==(248:254), % F7:FF
            
          elseif (status_byte==255) % Meta Events
            type = tmp(k);
            k = k+1;
            len = 1;
            while tmp(k)>127,
              len = mod(tmp(1),128) + len*128
              k = k+1;
            end;
            len = tmp(k) + len*128;
            data = tmp(k+1:min(k+len,length(tmp)));
            if 0,
            elseif type==0,	HDR.MIDI.SequenceNumber = data;
            elseif type==1,	HDR.MIDI.TextEvent = char(data);
            elseif type==2,	HDR.Copyright = char(data);
            elseif type==3,	HDR.MIDI.SequenceTrackName = char(data);
            elseif type==4,	HDR.MIDI.InstrumentNumber = char(data);
            elseif type==5,	HDR.MIDI.Lyric = char(data);
            elseif type==6,	HDR.EVENT.POS = data;
            elseif type==7,	HDR.MIDI.CuePoint = char(data);
            elseif type==32,MDR.MIDI.ChannelPrefix = data;
            elseif type==47,MDR.MIDI.EndOfTrack = k;
              
            end;
          else
          end;
        end;
        
      elseif ~isempty(tagsize)
        fprintf(HDR.FILE.stderr,'Warning SOPEN (MIDI): unknown TAG in %s: %s(%i) \n',HDR.FileName,tag,tagsize);
        [tmp,c] = fread(HDR.FILE.FID,[1,min(100,tagsize)],'uint8');
        fprintf(HDR.FILE.stderr,'%s\n',char(tmp));
      end,
      
      if ~isempty(tagsize)
        status = fseek(HDR.FILE.FID,filepos+tagsize,'bof');
        if status,
          fprintf(HDR.FILE.stderr,'Warning SOPEN (MIDI): fseek failed. Probably tagsize larger than end-of-file and/or file corrupted\n');
          fseek(HDR.FILE.FID,0,'eof');
        end;
      end;
      [tmp,c] = fread(HDR.FILE.FID,[1,4],'uint8');
    end;
    
    HDR.FILE.POS = 0;
    HDR.FILE.OPEN = 1;
    HDR.NRec = 1;
  end;
  