function [HDR, immediateReturn] = BIFF(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 try,
    NEW_INTERFACE=1;
    try
      [TFM.S,txt,TFM.E] = xlsread(HDR.FileName,'Beat-To-Beat');
    catch
      [TFM.S,TFM.E] = xlsread(HDR.FileName,'Beat-to-Beat');
      NEW_INTERFACE=0;
    end;
    if size(TFM.S,1)+1==size(TFM.E,1)
      %if ~isnan(TFM.S(1,1)) && ~isempty(TFM.E{1,1})
      fprintf('Warning: XLSREAD-BUG has occured in file %s.\n',HDR.FileName);
      TFM.S = [repmat(NaN,1,size(TFM.S,2));TFM.S];
    end;
    HDR.TFM = TFM;
    
    HDR.TYPE = 'TFM_EXCEL_Beat_to_Beat';
    %HDR.Patient.Name = [TFM.E{2,3},' ', TFM.E{2,4}];
    ix = 1; while ~strncmp(TFM.E{1,ix},'Build',5); ix=ix+1; end;
    TFM.VERSION = TFM.E{2,ix};
    
    gender = TFM.E{2,6};
    if isnumeric(gender)
      HDR.Patient.Sex = gender;
    elseif strncmpi(gender,'M',1)
      HDR.Patient.Sex = 1;
    elseif strncmpi(gender,'F',1)
      HDR.Patient.Sex = 2;
    else
      HDR.Patient.Sex = 0;
    end;
    if NEW_INTERFACE;
      HDR.Patient.Birthday = datevec(TFM.E{2,5},'dd.mm.yyyy');
      HDR.T0 = datevec(datenum(datevec(TFM.E{2,1},'dd.mm.yyyy')+TFM.E{2,2}));
      HDR.Patient.Height = TFM.E{2,7};
      HDR.Patient.Weight = TFM.E{2,8};
      HDR.Patient.Surface = TFM.E{2,9};
    else
      HDR.Patient.Height = TFM.S(2,7);
      HDR.Patient.Weight = TFM.S(2,8);
      HDR.Patient.Surface = TFM.S(2,9);
      HDR.Patient.Birthday = datevec(datenum('30-Dec-1899')+TFM.S(2,5));
      HDR.T0 = datevec(datenum('30-Dec-1899')+TFM.S(2,1)+TFM.S(2,2));
    end;
    HDR.Patient.BMI = HDR.Patient.Weight * HDR.Patient.Height^-2 * 1e4;
    HDR.Patient.Birthday(4) = 12;
    HDR.Patient.Age = (datenum(HDR.T0)-datenum(HDR.Patient.Birthday))/365.25;
  catch
  end;
  
  if strcmp(HDR.TYPE, 'TFM_EXCEL_Beat_to_Beat');
    if ~isempty(strfind(TFM.E{3,1},'---'))
      TFM.S(3,:) = [];
      TFM.E(3,:) = [];
    end;
    
    HDR.Label   = TFM.E(4,:)';
    HDR.PhysDim = TFM.E(5,:)';
    if strcmp(HDR.Label{3},'RRI') && strcmp(HDR.PhysDim{3},'[%]')
      %%%% correct bug in file (due to bug in TFM
      %%%% software
      HDR.PhysDim{3} = '[ms]';
    end;
    for k=1:length(HDR.PhysDim),
      HDR.PhysDim{k} = HDR.PhysDim{k}(2:end-1); % remove brackets []
    end;
    
    TFM.S = TFM.S(6:end,:);
    TFM.E = TFM.E(6:end,:);
    
    ix = find(isnan(TFM.S(:,2)) & ~isnan(TFM.S(:,1)));
    Desc = TFM.E(ix,2);
    HDR.EVENT.POS  = ix(:);
    HDR.EVENT.TYP  = zeros(size(HDR.EVENT.POS));
    [HDR.EVENT.CodeDesc, CodeIndex, HDR.EVENT.TYP] = unique(Desc);
    
    [HDR.SPR,HDR.NS] = size(TFM.S);
    HDR.Label = HDR.Label(1:HDR.NS);
    HDR.PhysDim = HDR.PhysDim(1:HDR.NS);
    HDR.NRec = 1;
    HDR.THRESHOLD  = repmat([0,NaN],HDR.NS,1); 	% Underflow Detection
    HDR.data = TFM.S;
    HDR.TYPE = 'native';
    HDR.FILE.POS = 0;
  end;