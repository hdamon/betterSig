function [HDR, immediateReturn] = QTFF(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-be');
  if ~isempty(findstr(HDR.FILE.PERMISSION,'r')),		%%%%% READ
    HDR.FILE.OPEN = 1;
    offset = 0;
    while ~feof(HDR.FILE.FID),
      tagsize = fread(HDR.FILE.FID,1,'uint32');        % which size
      if ~isempty(tagsize),
        offset = offset + tagsize;
        tag = char(fread(HDR.FILE.FID,[1,4],'uint8'));
        if tagsize==0,
          tagsize=inf; %tagsize-8;
        elseif tagsize==1,
          tagsize=fread(HDR.FILE.FID,1,'uint64');
        end;
        
        if tagsize <= 8,
        elseif strcmp(tag,'free'),
          val = fread(HDR.FILE.FID,[1,tagsize-8],'uint8');
          HDR.MOV.free = val;
        elseif strcmp(tag,'skip'),
          val = fread(HDR.FILE.FID,[1,tagsize-8],'uint8');
          HDR.MOV.skip = val;
        elseif strcmp(tag,'wide'),
          %val = fread(HDR.FILE.FID,[1,tagsize-8],'uint8');
          %HDR.MOV.wide = val;
        elseif strcmp(tag,'pnot'),
          val = fread(HDR.FILE.FID,[1,tagsize-8],'uint8');
          HDR.MOV.pnot = val;
        elseif strcmp(tag,'moov'),
          offset2 = 8;
          while offset2 < tagsize,
            tagsize2 = fread(HDR.FILE.FID,1,'uint32');        % which size
            if tagsize2==0,
              tagsize2 = inf;
            elseif tagsize2==1,
              tagsize2=fread(HDR.FILE.FID,1,'uint64');
            end;
            offset2 = offset2 + tagsize2;
            tag2 = char(fread(HDR.FILE.FID,[1,4],'uint8'));
            if tagsize2 <= 8,
            elseif strcmp(tag2,'mvhd'),
              HDR.MOOV.Version = fread(HDR.FILE.FID,1,'uint8');
              HDR.MOOV.Flags = fread(HDR.FILE.FID,3,'uint8');
              HDR.MOOV.Times = fread(HDR.FILE.FID,5,'uint32');
              HDR.T0 = datevec(HDR.MOOV.Times(1)/(3600*24))+[1904,0,0,0,0,0];
              HDR.MOOV.prefVol = fread(HDR.FILE.FID,1,'uint16');
              HDR.MOOV.reserved = fread(HDR.FILE.FID,10,'uint8');
              HDR.MOOV.Matrix = fread(HDR.FILE.FID,[3,3],'int32')';
              HDR.MOOV.Matrix(:,1:2) = HDR.MOOV.Matrix(:,1:2)/2^16;
              HDR.MOOV.Preview = fread(HDR.FILE.FID,5,'uint32');
            elseif strcmp(tag2,'trak'),
              HDR.MOOV.trak = fread(HDR.FILE.FID,[1,tagsize2-8],'uint8');
            elseif strcmp(tag2,'cmov'),
              HDR.MOOV.cmov = fread(HDR.FILE.FID,[1,tagsize2-8],'uint8');
            elseif strcmp(tag2,'free'),
              HDR.MOOV.free = fread(HDR.FILE.FID,[1,tagsize2-8],'uint8');
            elseif strcmp(tag2,'clip'),
              HDR.MOOV.clip = fread(HDR.FILE.FID,[1,tagsize2-8],'uint8');
            elseif strcmp(tag2,'udta'),
              HDR.MOOV.udta = fread(HDR.FILE.FID,[1,tagsize2-8],'uint8');
            elseif strcmp(tag2,'ctab'),
              HDR.MOOV.ctab = fread(HDR.FILE.FID,[1,tagsize2-8],'uint8');
            else
            end;
          end;
          %HDR.MOV.moov = fread(HDR.FILE.FID,[1,tagsize-8],'uint8');
          
        elseif strcmp(tag,'mdat'),
          HDR.HeadLen = ftell(HDR.FILE.FID);
          offset2 = 8;
          while offset2 < tagsize,
            tagsize2 = fread(HDR.FILE.FID,1,'uint32');        % which size
            tag2 = char(fread(HDR.FILE.FID,[1,4],'uint8'));
            if tagsize2==0,
              tagsize2 = inf;
            elseif tagsize2==1,
              tagsize2 = fread(HDR.FILE.FID,1,'uint64');
            end;
            offset2  = offset2 + tagsize2;
            if tagsize2 <= 8,
            elseif strcmp(tag2,'mdat'),
              HDR.MDAT.mdat = fread(HDR.FILE.FID,[1,tagsize2-8],'uint8');
            elseif strcmp(tag2,'wide'),
              HDR.MDAT.wide = fread(HDR.FILE.FID,[1,tagsize2],'uint8');
            elseif strcmp(tag2,'clip'),
              HDR.MDAT.clip = fread(HDR.FILE.FID,[1,tagsize2-8],'uint8');
            elseif strcmp(tag2,'udta'),
              HDR.MDAT.udta = fread(HDR.FILE.FID,[1,tagsize2-8],'uint8');
            elseif strcmp(tag2,'ctab'),
              HDR.MDAT.ctab = fread(HDR.FILE.FID,[1,tagsize2-8],'uint8');
            else
            end;
          end;
          %HDR.MOV.mdat = fread(HDR.FILE.FID,[1,tagsize-8],'uint8');
        else
          val = fread(HDR.FILE.FID,[1,tagsize-8],'uint8');
          fprintf(HDR.FILE.stderr,'Warning SOPEN Type=MOV: unknown Tag %s.\n',tag);
        end;
        fseek(HDR.FILE.FID,offset,'bof');
      end;
    end;
  end;
  %fclose(HDR.FILE.FID);