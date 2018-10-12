function [HDR, immediateReturn] = EEG_1100(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


  try
    [s,H]  = mexSLOAD(HDR.FileName,ReRefMx);
    H.data = s;
    H.TYPE = 'native';
    H.FILE.stderr = HDR.FILE.stderr;
    H.FILE.PERMISSION = HDR.FILE.PERMISSION;
    H.FLAG.FORCEALLCHANNEL = HDR.FLAG.FORCEALLCHANNEL;
    H.FLAG.TRIGGERED = 0;
    H.FILE.POS = 0;
    H.FLAG.OUTPUT = HDR.FLAG.OUTPUT;
    H.FILE.OPEN = HDR.FILE.OPEN;
    H.FILE.FID = HDR.FILE.FID;
    HDR = H;
    
  catch
    fprintf(HDR.FILE.stderr,'Warning SOPEN: family of Nihon-Kohden 1100 format is implemented only fully in libbiosig.\n');
    fprintf(HDR.FILE.stderr,'You need to have mexSLOAD installed in order to load file %s,\n',HDR.FileName);
    fprintf(HDR.FILE.stderr,' or you get only some limited header information');
    
    %% TODO: use mexSOPEN and SREAD.M together in order to avoid the need to load the whole data section
    
    H = mexSSOPEN(HDR.FileName);
    %% This will do some parts, but the internal fields needed by SREAD() and channel selection need still be defined.
    
    HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
    if any(HDR.FILE.PERMISSION=='r'),		%%%%% READ
      [H1,count] = fread(HDR.FILE.FID,[1,6160],'uint8');
      % HDR.Patient.Name = char(H1(79+(1:32)));
      if count < 6160,
        fclose(HDR.FILE.FID);
        return;
      end;
      HDR.T0(1:6) = str2double({H1(65:68),H1(69:70),H1(71:72),H1(6148:6149),H1(6150:6151),H1(6152:6153)});
      if strcmp(HDR.FILE.Ext,'LOG')
        [s,c] = fread(HDR.FILE.FID,[1,inf],'uint8');
        s = char([H1(1025:end),s]);
        K = 0;
        [t1,s] = strtok(s,0);
        while ~isempty(s),
          K = K + 1;
          [HDR.EVENT.x{K},s] = strtok(s,0);
        end
      end;
      fclose(HDR.FILE.FID);
    end;
  end