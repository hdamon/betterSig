function [HDR, immediateReturn] = MPEG(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = true; % Default Value


% http://www.dv.co.yu/mpgscript/mpeghdr.htm
  HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
  if ~isempty(findstr(HDR.FILE.PERMISSION,'r')),		%%%%% READ
    % read header
    try,
      tmp = fread(HDR.FILE.FID,1,'ubit11');
    catch
      fprintf(HDR.FILE.stderr,'Error 1003 SOPEN: datatype UBIT11 not implented. Header cannot be read.\n');
      return;
    end;
    HDR.MPEG.syncword = tmp;
    HDR.MPEG.ID = fread(HDR.FILE.FID,1,'ubit2');
    HDR.MPEG.layer = fread(HDR.FILE.FID,1,'ubit2');
    HDR.MPEG.protection_bit = fread(HDR.FILE.FID,1,'ubit1');
    HDR.MPEG.bitrate_index = fread(HDR.FILE.FID,1,'ubit4');
    HDR.MPEG.sampling_frequency_index = fread(HDR.FILE.FID,1,'ubit2');
    HDR.MPEG.padding_bit = fread(HDR.FILE.FID,1,'ubit1');
    HDR.MPEG.privat_bit = fread(HDR.FILE.FID,1,'ubit1');
    HDR.MPEG.mode = fread(HDR.FILE.FID,1,'ubit2');
    HDR.MPEG.mode_extension = fread(HDR.FILE.FID,1,'ubit2');
    HDR.MPEG.copyright = fread(HDR.FILE.FID,1,'ubit1');
    HDR.MPEG.original_home = fread(HDR.FILE.FID,1,'ubit1');
    HDR.MPEG.emphasis = fread(HDR.FILE.FID,1,'ubit2');
    
    switch HDR.MPEG.ID,	%Layer
      case 0,
        HDR.VERSION = 2.5;
      case 1,
        HDR.VERSION = -1;% reserved
      case 2,
        HDR.VERSION = 2;
      case 3,
        HDR.VERSION = 1;
    end;
    
    tmp = [32,32,32,32,8; 64,48,40,48,16; 96,56,48,56,24; 128,64,56,64,32; 160,80,64,80,40; 192,96,80,96,48; 224,112,96,112,56; 256,128,112,128,64; 288,160,128,144,80; 320,192 160,160,96; 352,224,192,176,112; 384,256,224, 192,128; 416,320,256,224,144;  448,384,320,256,160];
    tmp = [tmp,tmp(:,5)];
    if HDR.MPEG.bitrate_index==0,
      HDR.bitrate = NaN;
    elseif HDR.MPEG.bitrate_index==15,
      fclose(HDR.FILE.FID);
      fprintf(HDR.FILE.stderr,'SOPEN: corrupted MPEG file %s ',HDR.FileName);
      return;
    else
      HDR.bitrate = tmp(HDR.MPEG.bitrate_index,floor(HDR.VERSION)*3+HDR.MPEG.layer-3);
    end;
    
    switch HDR.MPEG.sampling_frequency_index,
      case 0,
        HDR.SampleRate = 44.100;
      case 1,
        HDR.SampleRate = 48.000;
      case 2,
        HDR.SampleRate = 32.000;
      otherwise,
        HDR.SampleRate = NaN;
    end;
    HDR.SampleRate_units = 'kHz';
    HDR.SampleRate = HDR.SampleRate*(2^(1-ceil(HDR.VERSION)));
    
    switch 4-HDR.MPEG.layer,	%Layer
      case 1,
        HDR.SPR = 384;
        slot = 32*HDR.MPEG.padding_bit; % bits, 4 bytes
        HDR.FrameLengthInBytes = (12*HDR.bitrate/HDR.SampleRate+slot)*4;
      case {2,3},
        HDR.SampleRate = 1152;
        slot = 8*HDR.MPEG.padding_bit; % bits, 1 byte
        HDR.FrameLengthInBytes = 144*HDR.bitrate/HDR.SampleRate+slot;
    end;
    
    if ~HDR.MPEG.protection_bit,
      HDR.MPEG.error_check = fread(HDR.FILE.FID,1,'uint16');
    end;
    
    HDR.MPEG.allocation = fread(HDR.FILE.FID,[1,32],'ubit4');
    HDR.MPEG.NoFB = sum(HDR.MPEG.allocation>0);
    HDR.MPEG.idx = find(HDR.MPEG.allocation>0);
    HDR.MPEG.scalefactor = fread(HDR.FILE.FID,[1,HDR.MPEG.NoFB],'ubit6');
    for k = HDR.MPEG.idx,
      HDR.MPEG.temp(1:12,k) = fread(HDR.FILE.FID,[12,1],['ubit',int2str(HDR.MPEG.allocation(k))]);
    end;
    fprintf(HDR.FILE.stderr,'Warning SOPEN: MPEG not ready for use (%s)\n',HDR.FileName);
    HDR.FILE.OPEN = 1;
  end;
  HDR.FILE.OPEN = 0;
  fclose(HDR.FILE.FID);
  HDR.FILE.FID = -1;
  return;
  