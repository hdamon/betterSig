function [HDR, immediateReturn] = Delta(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-be');
  if any(HDR.FILE.PERMISSION=='r'),		%%%%% READ
    warning('Support for Delta/NihonKohden Format is not implemented yet. ')
    HDR.HeadLen = hex2dec('304');
    HDR.H1 = fread(HDR.FILE.FID,[1,HDR.HeadLen],'uint8');
    HDR.Patient.Id = char(HDR.H1(314:314+80));
    
    if 1,
      HDR.NS   = 36;
      HDR.SampleRate = 256;
      HDR.NRec = 1;
      HDR.SPR  = 137216;
      HDR.data = fread(HDR.FILE.FID,[HDR.NS,HDR.SPR],'int16');
      HDR.EventTablePos = HDR.NRec*HDR.SPR*HDR.NS*2+HDR.HeadLen;
    end;
    tmp = fread(HDR.FILE.FID,[1,inf],'uint8');
    
    %%%%% identify events
    %ix = [strfind(char(HDR.ev),'TEST'),
    ix = strfind(char(tmp),'trigger');
    HDR.EVENT.TYP = tmp(ix-4)';
    HDR.EVENT.POS = [tmp(ix-12)',tmp(ix-11)',tmp(ix-10)',tmp(ix-9)']*(256.^[0:3]');
    
    fclose(HDR.FILE.FID);
  end;