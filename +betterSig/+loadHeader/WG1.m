function [HDR, immediateReturn] = WG1(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 if ~isempty(findstr(HDR.FILE.PERMISSION,'r')),		%%%%% READ
    HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],HDR.Endianity);
    HDR.VERSION = dec2hex(fread(HDR.FILE.FID,1,'uint32'));
    if strcmp(HDR.VERSION,'AFFE5555')
      error('This version of WG1 format is not supported, yet')
      
    elseif any(strcmp(HDR.VERSION,{'DADAFEFA','AFFEDADA'}))
      HDR.WG1.MachineId = fread(HDR.FILE.FID,1,'uint32');
      HDR.WG1.Day = fread(HDR.FILE.FID,1,'uint32');
      HDR.WG1.millisec = fread(HDR.FILE.FID,1,'uint32');
      HDR.T0    = datevec(HDR.WG1.Day - 15755 - hex2dec('250000'));
      HDR.T0(1) = HDR.T0(1) + 1970;
      HDR.T0(4) = floor(HDR.WG1.millisec/3600000);
      HDR.T0(5) = mod(floor(HDR.WG1.millisec/60000),60);
      HDR.T0(6) = mod(HDR.WG1.millisec/1000,60);
      dT = fread(HDR.FILE.FID,1,'uint32');
      HDR.SampleRate = 1e6/dT;
      HDR.WG1.pdata = fread(HDR.FILE.FID,1,'uint16');
      HDR.NS = fread(HDR.FILE.FID,1,'uint16');
      HDR.WG1.poffset = fread(HDR.FILE.FID,1,'uint16');
      HDR.WG1.pad1 = fread(HDR.FILE.FID,38,'uint8');
      HDR.Cal = repmat(NaN,HDR.NS,1);
      HDR.ChanSelect = repmat(NaN,HDR.NS,1);
      for k=1:HDR.NS,
        HDR.Label{k} = char(fread(HDR.FILE.FID,[1,8],'uint8'));
        HDR.Cal(k,1) = fread(HDR.FILE.FID,1,'uint32')/1000;
        tmp = fread(HDR.FILE.FID,[1,2],'uint16');
        HDR.ChanSelect(k) = tmp(1)+1;
      end;
      %HDR.Calib = sparse(2:HDR.NS+1,HDR.ChanSelect,HDR.Cal);
      HDR.Calib = sparse(2:HDR.NS+1,1:HDR.NS,HDR.Cal);
      HDR.PhysDimCode = zeros(HDR.NS,1);
      
      status = fseek(HDR.FILE.FID,7*256,'bof');
      HDR.WG1.neco1 = fread(HDR.FILE.FID,1,'uint32');
      HDR.Patient.Id = fread(HDR.FILE.FID,[1,12],'uint8');
      HDR.Patient.LastName = fread(HDR.FILE.FID,[1,20],'uint8');
      HDR.Patient.text1 = fread(HDR.FILE.FID,[1,20],'uint8');
      HDR.Patient.FirstName = fread(HDR.FILE.FID,[1,20],'uint8');
      HDR.Patient.Sex = fread(HDR.FILE.FID,[1,2],'uint8');
      HDR.Patient.vata = fread(HDR.FILE.FID,[1,8],'uint8');
      HDR.Patient.text2 = fread(HDR.FILE.FID,[1,14],'uint8');
      HDR.WG1.Datum = fread(HDR.FILE.FID,1,'uint32');
      HDR.WG1.mstime = fread(HDR.FILE.FID,1,'uint32');
      HDR.WG1.nic = fread(HDR.FILE.FID,[1,4],'uint32');
      HDR.WG1.neco3 = fread(HDR.FILE.FID,1,'uint32');
      
      status = fseek(HDR.FILE.FID,128,'cof');
      HDR.HeadLen = ftell(HDR.FILE.FID);
      HDR.FILE.OPEN = 1;
      HDR.FILE.POS  = 0;
      
      HDR.WG1.szBlock  = 256;
      HDR.WG1.szOffset = 128;
      HDR.WG1.szExtra  = HDR.WG1.pdata-(HDR.NS+HDR.WG1.poffset);
      szOneRec = HDR.WG1.szOffset*4+(HDR.NS+HDR.WG1.szExtra)*HDR.WG1.szBlock;
      HDR.AS.bpb = szOneRec;
      HDR.WG1.szRecs = floor((HDR.FILE.size-HDR.HeadLen)/HDR.AS.bpb);
      HDR.WG1.szData = HDR.WG1.szBlock*HDR.WG1.szRecs;
      HDR.WG1.unknownNr = 11;
      conv = round(19*sinh((0:127)/19));
      conv = [conv, HDR.WG1.unknownNr, -conv(end:-1:2)];
      HDR.WG1.conv = conv;
      HDR.NRec = HDR.WG1.szRecs;
      HDR.SPR  = HDR.WG1.szBlock;
      HDR.Dur  = HDR.SPR/HDR.SampleRate;
      HDR.AS.endpos = HDR.NRec*HDR.SPR;
    end
    
    %----- load event information -----
    eventFile = fullfile(HDR.FILE.Path,[HDR.FILE.Name, '.wg2']);
    if ~exist(eventFile,'file')
      eventFile = fullfile(HDR.FILE.Path,[HDR.FILE.Name, '.WG2']);
    end;
    if exist(eventFile,'file')
      fid= fopen(eventFile,'r');
      nr = 1;
      [s,c] = fread(fid,1,'uint32');
      while ~feof(fid)
        HDR.EVENT.POS(nr,1) = s;
        pad = fread(fid,3,'uint32');
        len = fread(fid,1,'uint8');
        tmp = char(fread(fid,[1,47], 'uint8'));
        Desc{nr,1} = tmp(1:len);
        % find string between quotation marks
        %  HDR.EVENT.Desc{nr}=regexpi(Event,'(?<=\'').*(?=\'')','match','once');
        [s,c] = fread(fid,1,'uint32');
        nr  = nr+1;
      end;
      [HDR.EVENT.CodeDesc, CodeIndex, HDR.EVENT.TYP] = unique(Desc);
      fclose(fid);
    end;
  end;