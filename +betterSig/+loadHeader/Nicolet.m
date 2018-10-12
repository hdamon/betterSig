function [HDR, immediateReturn] = Nicolet(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 fid = fopen(fullfile(HDR.FILE.Path,HDR.FILE.Name,'.bni'),'rt');
  HDR.H1 = char(fread(fid,[1,inf],'uint8=>char'));
  fclose(fid);
  HDR = bni2hdr(HDR,CHAN,MODE,ReRefMx);
  HDR.FILE.FID = fopen(fullfile(HDR.FILE.Path,HDR.FILE.Name,'.eeg'),'r','ieee-le');
  status = fseek(HDR.FILE.FID,-4,'eof');
  if status,
    fprintf(2,'Error SOPEN: file %s\n',HDR.FileName);
    return;
  end
  datalen = fread(fid,1,'uint32');
  status  = fseek(fid,datalen,'bof');
  HDR.H2  = char(fread(fid,[1,1e6],'uint8'));
  status  = fseek(HDR.FILE.FID,0,'bof');
  HDR.SPR = datalen/(2*HDR.NS);
  HDR.NRec   = 1;
  HDR.AS.endpos = HDR.SPR;
  HDR.GDFTYP = 3; % int16;
  HDR.HeadLen = 0;
  
%  %% Obsolete Function Below
%    if any(HDR.FILE.PERMISSION=='r'),
%     HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
%     if HDR.FILE.FID<0,
%       return;
%     end
%     
%     HDR.FILE.POS  = 0;
%     HDR.FILE.OPEN = 1;
%     HDR.AS.endpos = HDR.SPR;
%     HDR.AS.bpb = 2*HDR.NS;
%     HDR.GDFTYP = 'int16';
%     HDR.HeadLen = 0;
%   else
%     fprintf(HDR.FILE.stderr,'PERMISSION %s not supported\n',HDR.FILE.PERMISSION);
%   end;