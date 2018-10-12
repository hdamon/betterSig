function [HDR, immediateReturn] = EEG(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 if any(HDR.FILE.PERMISSION=='r');
    if isempty(strfind(MODE,'32'))
      [HDR,H1,h2] = cntopen(HDR,CHAN,MODE,ReRefMx);
    else
      [HDR,H1,h2] = cntopen(HDR,'32bit');
    end;
    
    % support of OVERFLOWDETECTION
    if ~isfield(HDR,'THRESHOLD'),
      if HDR.FLAG.OVERFLOWDETECTION,
        fprintf(2,'WARNING SOPEN(CNT): OVERFLOWDETECTION might not work correctly. See also EEG2HIST and read \n');
        fprintf(2,'   http://dx.doi.org/10.1016/S1388-2457(99)00172-8 (A. Schl�gl et al. Quality Control ... Clin. Neurophysiol. 1999, Dec; 110(12): 2165 - 2170).\n');
        fprintf(2,'   A copy is available here, too: http://pub.ist.ac.at/~schloegl/publications/neurophys1999_2165.pdf \n');
      end;
      [datatyp,limits,datatypes,numbits,GDFTYP]=gdfdatatype(HDR.GDFTYP);
      HDR.THRESHOLD = repmat(limits,HDR.NS,1);
    end;
    
  elseif any(HDR.FILE.PERMISSION=='w');
    % check header information
    if ~isfield(HDR,'NS'),
      HDR.NS = 0;
    end;
    if ~isfinite(HDR.NS) || (HDR.NS<0)
      fprintf(HDR.FILE.stderr,'Error SOPEN CNT-Write: HDR.NS not defined\n');
      return;
    end;
    if ~isfield(HDR,'SPR'),
      HDR.SPR = 0;
    end;
    if ~isfinite(HDR.SPR)
      HDR.SPR = 0;
    end;
    type = 2;
    if strmatch(HDR.TYPE,'EEG'), type = 1;
    elseif strmatch(HDR.TYPE,'AVG'), type = 0;
    end;
    
    if ~isfield(HDR,'PID')
      HDR.PID = char(repmat(32,1,20));
    elseif numel(HDR.PID)>20,
      HDR.PID = HDR.PID(1:20);
    else
      HDR.PID = [HDR.PID(:)',repmat(32,1,20-length(HDR.PID(:)))];
      %HDR.PID = [HDR.PID,repmat(32,1,20-length(HDR.PID))];
    end;
    
    if ~isfield(HDR,'Label')
      HDR.Label = int2str((1:HDR.NS)');
    elseif iscell(HDR.Label),
      HDR.Label = char(HDR.Label);
    end;
    if size(HDR.Label,2)>10,
      HDR.Label = HDR.Label(:,1:10);
    elseif size(HDR.Label,2)<10,
      HDR.Label = [HDR.Label,repmat(32,HDR.NS,10-size(HDR.Label,2))];
    end;
    
    if ~isfield(HDR,'Calib')
      HDR.Cal = ones(HDR.NS,1);
      e.sensitivity = ones(HDR.NS,1)*204.8;
      HDR.Off = zeros(HDR.NS,1);
    else
      HDR.Cal = diag(HDR.Calib(2:end,:));
      e.sensitivity = ones(HDR.NS,1)*204.8;
      HDR.Off = round(HDR.Calib(1,:)'./HDR.Cal);
    end;
    
    % open file
    if any(HDR.FILE.PERMISSION=='z') && (HDR.SPR<=0),
      fprintf(HDR.FILE.stderr,'ERROR SOPEN (CNT) "wz": Update of HDR.SPR is not possible.\n',HDR.FileName);
      fprintf(HDR.FILE.stderr,'\t Solution(s): (1) define exactly HDR.SPR before calling SOPEN(HDR,"wz"); or (2) write to uncompressed file instead.\n');
      return;
    end;
    HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
    if HDR.FILE.FID < 0,
      return;
    end;
    HDR.FILE.OPEN = 2;
    if any([HDR.SPR] <= 0);
      HDR.FILE.OPEN = 3;
    end;
    
    % write fixed header
    fwrite(HDR.FILE.FID,'Version 3.0','uint8');
    fwrite(HDR.FILE.FID,zeros(2,1),'uint32');
    fwrite(HDR.FILE.FID,type,'uint8');
    fwrite(HDR.FILE.FID,HDR.PID,'uint8');
    
    fwrite(HDR.FILE.FID,repmat(0,1,900-ftell(HDR.FILE.FID)),'uint8')
    
    % write variable header
    for k = 1:HDR.NS,
      count = fwrite(HDR.FILE.FID,HDR.Label(k,:),'uint8');
      count = fwrite(HDR.FILE.FID,zeros(5,1),'uint8');
      count = fwrite(HDR.FILE.FID, 0, 'uint16');
      count = fwrite(HDR.FILE.FID,zeros(2,1),'uint8');
      
      count = fwrite(HDR.FILE.FID,zeros(7,1),'float');
      count = fwrite(HDR.FILE.FID,HDR.Off(k),int16);
      count = fwrite(HDR.FILE.FID,zeros(2,1),'uint8');
      count = fwrite(HDR.FILE.FID,[zeros(2,1),e.sensitivity(k)],'float');
      count = fwrite(HDR.FILE.FID,zeros(3,1),'uint8');
      count = fwrite(HDR.FILE.FID,zeros(4,1),'uint8');
      count = fwrite(HDR.FILE.FID,zeros(1,1),'uint8');
      count = fwrite(HDR.FILE.FID,HDR.Cal(k),'int16');
    end;
    
    HDR.HeadLen = ftell(HDR.FILE.FID);
    if HDR.HeadLen ~= (900+75*HDR.NS),
      fprintf(HDR.FILE.stderr,'Error SOPEN CNT-Write: Headersize does not fit\n');
    end;
  end;
  