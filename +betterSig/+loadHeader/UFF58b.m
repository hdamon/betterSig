function [HDR, immediateReturn] = UFF58b(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value



 if ~isempty(findstr(HDR.FILE.PERMISSION,'r')),		%%%%% READ
    HDR.FILE.FID = fopen(HDR.FileName,'r','ieee-le');
    tline = fgetl(HDR.FILE.FID); 	% line 1
    tline = fgetl(HDR.FILE.FID); 	% line 2
    if strncmp(tline,'    58b     1     1',19)
      HDR.Endianity = 'vax';
    elseif strncmp(tline,'    58b     1     2',19)
      HDR.Endianity = 'ieee-le';
      HDR.GDFTYP = 16;
    elseif strncmp(tline,'    58b     2     2',19)
      HDR.Endianity = 'ieee-be';
    elseif 0, strncmp(tline,'    58b     1     3',19)
      HDR.Endianity = 'ibm370';
    else
      HDR.Endianity = ''; % not supported;
      fprintf(HDR.FILE.stderr,'ERROR SOPEN(UFF): binary format (IBM370, DEC/VMS) not supported, yet.');
      fclose(fid);
      return;
    end;
    [HDR.UFF.NoLines,v,str] = str2double(tline(20:31));
    [HDR.UFF.NoBytes,v,str] = str2double(tline(32:43));
    for k = 1:HDR.UFF.NoLines,
      tline = fgetl(HDR.FILE.FID);  %line k+2
      if strncmp(tline,'NONE',4)
      elseif strncmp(tline,'@',1)
      elseif strcmp(tline([3,7,13,16]),'--::')
        HDR.T0 = datevec(datenum(tline));
      else
      end;
    end;
    HDR.HeadLen = ftell(HDR.FILE.FID);
    if ~strcmp(HDR.Endianity,'ieee-le')
      fclose(HDR.FILE.FID);
      HDR.FILE.FID = fopen(HDR.FileName,'r',HDR.Endianity);
      fseek(HDR.FILE.FID,HDR.HeadLen,'bof');
    end;
    HDR.data = fread(HDR.FILE.FID,[2,HDR.UFF.NoBytes/8],'float32')'
    HDR.Calib = [1;sqrt(-1)];
    fclose(HDR.FILE.FID);
    fprintf(HDR.FILE.stderr, 'WARNING SOPEN(UFF58): support for UFF58 format not complete.\n');
  end;
  