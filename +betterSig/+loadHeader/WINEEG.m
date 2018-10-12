function [HDR, immediateReturn] = WINEEG(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


if any(HDR.FILE.PERMISSION=='r'),
    fprintf(HDR.FILE.stderr,'Warning SOPEN (WINEEG): this is still under developement.\n');
    HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
    % HDR.FILE.OPEN = 1;
    HDR.FILE.POS = 0;
    HDR.EEG.H1   = fread(HDR.FILE.FID,[1,1152],'uint8');
    fseek(HDR.FILE.FID,0,'bof');
    HDR.EEG.H1u16  = fread(HDR.FILE.FID,[1,1152/2],'uint16');
    tmp = HDR.EEG.H1(197:218); tmp(tmp==47) = ' '; tmp(tmp==0) = ' '; tmp(tmp==':') = ' ';
    [n,v,s] = str2double(char(tmp));
    HDR.T0  = n([3,2,1,4,5,6]);
    HDR.NS  = HDR.EEG.H1(3:4)*[1;256];
    HDR.SampleRate = HDR.EEG.H1(5:6)*[1;256];
    HDR.EEG.H2  = fread(HDR.FILE.FID,[64,HDR.NS],'uint8')';
    fseek(HDR.FILE.FID,1152,'bof');
    HDR.EEG.H2f32 = fread(HDR.FILE.FID,[64/4,HDR.NS],'float')';
    HDR.Label   = char(HDR.EEG.H2(:,1:4));
    %HDR.FLAG.UCAL = 1;
    HDR.Cal     = HDR.EEG.H2f32(:,7);
    HDR.PhysDim = repmat({'uV'},HDR.NS,1);
    
    HDR.HeadLen = ftell(HDR.FILE.FID);
    HDR.SPR     = floor((HDR.FILE.size-HDR.HeadLen)/(HDR.NS*2));
    HDR.NRec    = 1;
    
    HDR.data    = fread(HDR.FILE.FID,[HDR.NS,inf],'int16')';
    HDR.TYPE    = 'native';
    fclose(HDR.FILE.FID);
  end;