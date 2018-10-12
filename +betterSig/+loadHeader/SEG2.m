function [HDR, immediateReturn] = SEG2(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 if any(HDR.FILE.PERMISSION=='r'),
    HDR.FILE.FID = fopen(HDR.FileName,PERMISSION,HDR.Endianity);
    
    HDR.FILE.OPEN = 1;
    HDR.FILE.POS  = 0;
    HDR.VERSION = fread(HDR.FILE.FID,1,'int16');
    HDR.HeadLen = fread(HDR.FILE.FID,1,'uint16');
    HDR.NS      = fread(HDR.FILE.FID,1,'uint16');
    HDR.SEG2.nsterm = fread(HDR.FILE.FID,1,'uint8'); 	% number of string terminator
    HDR.SEG2.sterm  = fread(HDR.FILE.FID,2,'uint8'); 	% string terminator
    HDR.SEG2.nlterm = fread(HDR.FILE.FID,1,'uint8'); 	% number of line terminator
    HDR.SEG2.lterm  = fread(HDR.FILE.FID,2,'uint8'); 	% line terminator
    HDR.SEG2.TraceDesc = fread(HDR.FILE.FID,HDR.NS,'uint32');
    
    % initialize date
    HDR.SEG2.blocksize = repmat(nan,HDR.NS,1);
    HDR.AS.bpb = repmat(nan,HDR.NS,1);
    HDR.AS.spb = repmat(nan,HDR.NS,1);
    HDR.SEG2.DateFormatCode = repmat(nan,HDR.NS,1);
    
    if ftell(HDR.FILE.FID) ~= HDR.HeadLen,
      fprintf(HDR.FILE.stderr,'Warning SOPEN TYPE=SEG2: headerlength does not fit.\n');
    end;
    
    optstrings = fread(HDR.FILE.FID,HDR.SEG2.TraceDesc(1)-HDR.Headlen,'uint8');
    
    id_tmp = fread(HDR.FILE.FID,1,'uint16');
    if id_tmp ~=hex2dec('4422')
      fprintf(HDR.FILE.stderr,'Error SOPEN TYPE=SEG2: incorrect trace descriptor block ID.\n');
    end;
    
    for k = 1:HDR.NS,
      fseek(HDR.FILE.FID,HDR.SEG2.TraceDesc(k),'bof');
      HDR.SEG2.blocksize(k)  = fread(HDR.FILE.FID,1,'uint16');
      HDR.AS.bpb(k)  = fread(HDR.FILE.FID,1,'uint32');
      HDR.AS.spb(k)  = fread(HDR.FILE.FID,1,'uint32');
      HDR.SEG2.DateFormatCode(k) = fread(HDR.FILE.FID,1,'uint8');
      
      fseek(HDR.FILE.FID,32-13,'cof');
      %[tmp,c] = fread(HDR.FILE.FID,32-13,'uint8');	% reserved
      
      optstrings = fread(HDR.FILE.FID,HDR.SEG2.blocksize(k)-32,'uint8');
    end;
    
    fprintf(HDR.FILE.stderr,'Format %s not implemented yet. \nFor more information contact <Biosig-general@lists.sourceforge.net> Subject: Biosig/Dataformats \n',HDR.TYPE);
    fclose(HDR.FILE.FID);
    HDR.FILE.FID = -1;
    HDR.FILE.OPEN = 0;
  end;