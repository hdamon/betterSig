function [HDR, immediateReturn] = ISHNE(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 if any(HDR.FILE.PERMISSION=='r'),
    HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
    
    fprintf(HDR.FILE.stderr,'Format not tested yet. \nFor more information contact <Biosig-general@lists.sourceforge.net> Subject: Biosig/Dataformats \n',HDR.FILE.PERMISSION);
    
    HDR.FILE.OPEN = 1;
    fseek(HDR.FILE.FID,10,'bof');
    HDR.variable_length_block = fread(HDR.FILE.FID,1,'int32');
    HDR.SPR = fread(HDR.FILE.FID,1,'int32');
    HDR.NRec= 1;
    HDR.offset_variable_length_block = fread(HDR.FILE.FID,1,'int32');
    HDR.HeadLen = fread(HDR.FILE.FID,1,'int32');
    HDR.VERSION = fread(HDR.FILE.FID,1,'int16');
    HDR.Patient.Name = char(fread(HDR.FILE.FID,[1,80],'uint8'));
    %HDR.Surname = fread(HDR.FILE.FID,40,'uint8');
    HDR.Patient.Id  = char(fread(HDR.FILE.FID,[1,20],'uint8'));
    HDR.Patient.Sex = fread(HDR.FILE.FID,1,'int16');
    HDR.Patient.Race = fread(HDR.FILE.FID,1,'int16');
    HDR.Patient.Birthday([3:-1:1,4:6]) = [fread(HDR.FILE.FID,[1,3],'int16'),12,0,0];
    %HDR.Patient.Surname = char(fread(HDR.FILE.FID,40,'uint8')');
    Date  = fread(HDR.FILE.FID,[1,3],'int16');
    Date2 = fread(HDR.FILE.FID,[1,3],'int16');
    Time  = fread(HDR.FILE.FID,[1,3],'int16');
    HDR.T0 = [Date([3,2,1]),Time];
    
    HDR.NS = fread(HDR.FILE.FID,1,'int16');
    HDR.Lead.Specification = fread(HDR.FILE.FID,12,'int16');
    HDR.Lead.Quality = fread(HDR.FILE.FID,12,'int16');
    
    HDR.Lead.AmplitudeResolution = fread(HDR.FILE.FID,12,'int16');
    if any(HDR.Lead.AmplitudeResolution ~= -9)
      fprintf(HDR.FILE.stderr,'Warning: AmplitudeResolution and Number of Channels %i do not fit.\n',HDR.NS);
    end;
    
    HDR.ISHNE.PacemakerCode  = fread(HDR.FILE.FID,1,'int16');
    HDR.ISHNE.TypeOfRecorder = char(fread(HDR.FILE.FID,[1,40],'uint8'));
    tmp = fread(HDR.FILE.FID,1,'int16');
    if tmp==-9,
      HDR.SampleRate = 200;
    else
      fprintf(HDR.FILE.stderr,'Warning SOPEN (ISHNE): Sample rate not correctly reconstructed!!!\n');
      HDR.SampleRate = 1;
    end;
    HDR.ISHNE.Proprietary_of_ECG = char(fread(HDR.FILE.FID,[1,80],'uint8'));
    HDR.ISHNE.Copyright = char(fread(HDR.FILE.FID,[1,80],'uint8'));
    HDR.ISHNE.reserved1 = char(fread(HDR.FILE.FID,[1,80],'uint8'));
    if ftell(HDR.FILE.FID) ~= HDR.offset_variable_length_block,
      fprintf(HDR.FILE.stderr,'Warning: length of fixed header does not fit %i %i \n',ftell(HDR.FILE.FID),HDR.offset_variable_length_block);
      HDR.ISHNE.reserved2 = char(fread(HDR.FILE.FID,[1,max(0,HDR.offset_variable_length_block-ftell(HDR.FILE.FID))],'uint8'));
      fseek(HDR.FILE.FID,HDR.offset_variable_length_block,'bof');
    end;
    HDR.VariableHeader = fread(HDR.FILE.FID,[1,HDR.variable_length_block],'uint8');
    if ftell(HDR.FILE.FID)~=HDR.HeadLen,
      fprintf(HDR.FILE.stderr,'ERROR: length of variable header does not fit %i %i \n',ftell(HDR.FILE.FID),HDR.HeadLen);
      fseek(HDR.FILE.FID,HDR.HeadLen,'bof');
    end;
    HDR.PhysDim= 'uV';
    HDR.AS.bpb = 2*HDR.NS;
    
    HDR.Cal = HDR.Lead.AmplitudeResolution(1:HDR.NS)/1000;
    HDR.Calib  = sparse(2:HDR.NS+1,1:HDR.NS,HDR.Cal,HDR.NS+1,HDR.NS);
    if HDR.VERSION,
      HDR.GDFTYP = 3; % 'int16'
    else
      %% does not follow the specification (generated with Medilog Darwin software ?)
      HDR.GDFTYP = 4; % 'uint16'
      HDR.Off = -(2^15)*HDR.Cal;
      HDR.Calib(1,:)=HDR.Off';
    end;
    
    HDR.AS.endpos = HDR.SPR;
    HDR.FLAG.TRIGGERED = 0;	% Trigger Flag
    HDR.Label = cellstr([repmat('#',HDR.NS,1),num2str([1:HDR.NS]')]);
    HDR.FILE.POS = 0;
  else
    fprintf(HDR.FILE.stderr,'PERMISSION %s not supported\n',HDR.FILE.PERMISSION);
  end;
  