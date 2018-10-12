function [HDR, immediateReturn] = FLAC(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-be');
  
  if HDR.FILE.FID > 0,
    HDR.magic  = fread(HDR.FILE.FID,[1,4],'uint8');
    
    % read METADATA_BLOCK
    % 	read METADATA_BLOCK_HEADER
    tmp = fread(HDR.FILE.FID,[1,4],'uint8')
    while (tmp(1)<128),
      BLOCK_TYPE = mod(tmp(1),128);
      LEN = tmp(2:4)*2.^[0;8;16];
      POS = ftell(HDR.FILE.FID);
      if (BLOCK_TYPE == 0),		% STREAMINFO
        minblksz = fread(HDR.FILE.FID,1,'uint16')
        maxblksz = fread(HDR.FILE.FID,1,'uint16')
        minfrmsz = 2.^[0,8,16]*fread(HDR.FILE.FID,3,'uint8')
        maxfrmsz = 2.^[0,8,16]*fread(HDR.FILE.FID,3,'uint8')
        %Fs = fread(HDR.FILE.FID,3,'ubit20')
      elseif (BLOCK_TYPE == 1),	% PADDING
      elseif (BLOCK_TYPE == 2),	% APPLICATION
        HDR.FLAC.Reg.Appl.ID = fread(HDR.FILE.FID,1,'uint32')
      elseif (BLOCK_TYPE == 3),	% SEEKTABLE
        HDR.EVENT.N = LEN/18;
        for k = 1:LEN/18,
          HDR.EVENT.POS(k) = 2.^[0,32]*fread(HDR.FILE.FID,2,'uint32');
          HDR.EVENT.DUR(k) = 2.^[0,32]*fread(HDR.FILE.FID,2,'uint32');
          HDR.EVENT.nos(k) = fread(HDR.FILE.FID,1,'uint16');
          
        end;
      elseif (BLOCK_TYPE == 4),	% VORBIS_COMMENT
      elseif (BLOCK_TYPE == 5),	% CUESHEET
      else					% reserved
      end;
      
      fseek(HDR.FILE.FID, POS+LEN,'bof');
      tmp = fread(HDR.FILE.FID,[1,4],'uint8')
    end;
    
    % 	read METADATA_BLOCK_DATA
    
    % read METADATA_BLOCK_DATA
    % 	read METADATA_BLOCK_STREAMINFO
    % 	read METADATA_BLOCK_PADDING
    % 	read METADATA_BLOCK_APPLICATION
    % 	read METADATA_BLOCK_SEEKTABLE
    % 	read METADATA_BLOCK_COMMENT
    % 	read METADATA_BLOCK_CUESHEET
    
    % read FRAME
    %	read FRAME_HEADER
    %	read FRAME_SUBFRAME
    %		read FRAME_SUBFRAME_HEADER
    %	read FRAME_HEADER
    
    fclose(HDR.FILE.FID)
    
    fprintf(HDR.FILE.stderr,'Warning SOPEN: FLAC not ready for use\n');
    return;
  end;
  