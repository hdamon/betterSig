function [HDR, immediateReturn] = MAT4(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],HDR.MAT4.opentyp);
  k=0; NB=0;
  %type = fread(HDR.FILE.FID,4,'uint8'); 	% 4-byte header
  type = fread(HDR.FILE.FID,1,'uint32'); 	% 4-byte header
  while ~isempty(type),
    type = sprintf('%04i',type)';
    type = type - abs('0');
    k = k + 1;
    [mrows,c] = fread(HDR.FILE.FID,1,'uint32'); 	% tag, datatype
    ncols = fread(HDR.FILE.FID,1,'uint32'); 	% tag, datatype
    imagf = fread(HDR.FILE.FID,1,'uint32'); 	% tag, datatype
    namelen  = fread(HDR.FILE.FID,1,'uint32'); 	% tag, datatype
    if namelen>HDR.FILE.size,
      %	fclose(HDR.FILE.FID);
      HDR.ErrNum  = -1;
      HDR.ErrMsg = sprintf('Error SOPEN (MAT4): Could not open %s\n',HDR.FileName);
      return;
    end;
    [name,c] = fread(HDR.FILE.FID,namelen,'uint8');
    
    if imagf,
      HDR.ErrNum=-1;
      fprintf(HDR.FILE.stderr,'Warning %s: Imaginary data not tested\n',mfilename);
    end;
    if type(4)==2,
      HDR.ErrNum=-1;
      fprintf(HDR.FILE.stderr,'Error %s: sparse data not supported\n',mfilename);
    elseif type(4)>2,
      type(4)=rem(type(4),2);
    end;
    
    dt=type(3);
    if     dt==0, SIZOF=8; TYP = 'float64';
    elseif dt==6, SIZOF=1; TYP = 'uint8';
    elseif dt==4, SIZOF=2; TYP = 'uint16';
    elseif dt==3, SIZOF=2; TYP = 'int16';
    elseif dt==2, SIZOF=4; TYP = 'int32';
    elseif dt==1, SIZOF=4; TYP = 'float32';
    else
      fprintf(HDR.FILE.stderr,'Error %s: unknown data type\n',mfilename);
    end;
    
    HDR.Var(k).Name  = char(name(1:length(name)-1)');
    HDR.Var(k).Size  = [mrows,ncols];
    HDR.Var(k).SizeOfType = SIZOF;
    HDR.Var(k).Type  = [type;~~imagf]';
    HDR.Var(k).TYP   = TYP;
    HDR.Var(k).Pos   = ftell(HDR.FILE.FID);
    
    c=0;
    %% find the ADICHT data channels
    if strfind(HDR.Var(k).Name,'data_block'),
      HDR.ADI.DB(str2double(HDR.Var(k).Name(11:length(HDR.Var(k).Name))))=k;
    elseif strfind(HDR.Var(k).Name,'ticktimes_block'),
      HDR.ADI.TB(str2double(HDR.Var(k).Name(16:length(HDR.Var(k).Name))))=k;
    end;
    
    tmp1=ftell(HDR.FILE.FID);
    
    % skip next block
    tmp=(prod(HDR.Var(k).Size)-c)*HDR.Var(k).SizeOfType*(1+(~~imagf));
    fseek(HDR.FILE.FID,tmp,0);
    
    tmp2=ftell(HDR.FILE.FID);
    if (tmp2-tmp1) < tmp,  % if skipping the block was not successful
      HDR.ErrNum = -1;
      HDR.ErrMsg = sprintf('file %s is corrupted',HDR.FileName);
      fprintf(HDR.FILE.stderr,'Error SOPEN: MAT4 (ADICHT) file %s is corrupted\n',HDR.FileName);
      return;
    end;
    
    %type = fread(HDR.FILE.FID,4,'uint8');  	% 4-byte header
    type = fread(HDR.FILE.FID,1,'uint32'); 	% 4-byte header
  end;
  HDR.FILE.OPEN = 1;
  HDR.FILE.POS = 0;
  
  
  if isfield(HDR,'ADI')
    HDR.TYPE = 'ADI', % ADICHT-data, converted into a Matlab 4 file
    
    fprintf(HDR.FILE.stderr,'Format not tested yet. \nFor more information contact <Biosig-general@lists.sourceforge.net> Subject: Biosig/Dataformats \n',HDR.FILE.PERMISSION);
    
    %% set internal sampling rate to 1000Hz (default). Set HDR.iFs=[] if no resampling should be performed
    HDR.iFs = []; %1000;
    HDR.NS  = HDR.Var(HDR.ADI.DB(1)).Size(1);
    HDR.ADI.comtick = [];
    HDR.ADI.comTick = [];
    HDR.ADI.comtext = [];
    HDR.ADI.comchan = [];
    HDR.ADI.comblok = [];
    HDR.ADI.index   = [];
    HDR.ADI.range   = [];
    HDR.ADI.scale   = [];
    HDR.ADI.titles  = [];
    
    HDR.ADI.units   = [];
    
    for k=1:length(HDR.ADI.TB),
      [HDR,t1] = matread(HDR,['ticktimes_block' int2str(k)],[1 2]);	% read first and second element of timeblock
      [HDR,t2] = matread(HDR,['ticktimes_block' int2str(k)],HDR.Var(HDR.ADI.DB(k)).Size(2)); % read last element of timeblock
      HDR.ADI.ti(k,1:2) = [t1(1),t2];
      HDR.SampleRate(k) = round(1/diff(t1));
      
      [HDR,tmp] = matread(HDR,['comtick_block' int2str(k)]);	% read first and second element of timeblock
      HDR.ADI.comtick = [HDR.ADI.comtick;tmp];
      %HDR.ADI.comTick = [HDR.ADI.comTick;tmp/HDR.SampleRate(k)+HDR.ADI.ti(k,1)];
      [HDR,tmp] = matread(HDR,['comchan_block' int2str(k)]);	% read first and second element of timeblock
      HDR.ADI.comchan = [HDR.ADI.comchan;tmp];
      [HDR,tmp] = matread(HDR,['comtext_block' int2str(k)]);	% read first and second element of timeblock
      tmp2 = size(HDR.ADI.comtext,2)-size(tmp,2);
      if tmp2>=0,
        HDR.ADI.comtext = [HDR.ADI.comtext;[tmp,zeros(size(tmp,1),tmp2)]];
      else
        HDR.ADI.comtext = [[HDR.ADI.comtext,zeros(size(HDR.ADI.comtext,1),-tmp2)];tmp];
      end;
      HDR.ADI.comblok=[HDR.ADI.comblok;repmat(k,size(tmp,1),1)];
      
      [HDR,tmp] = matread(HDR,['index_block' int2str(k)]);	% read first and second element of timeblock
      if isempty(tmp),
        HDR.ADI.index{k} = 1:HDR.NS;
      else
        HDR.NS=length(tmp); %
        HDR.ADI.index{k} = tmp;
      end;
      [HDR,tmp] = matread(HDR,['range_block' int2str(k)]);	% read first and second element of timeblock
      HDR.ADI.range{k} = tmp;
      [HDR,tmp] = matread(HDR,['scale_block' int2str(k)]);	% read first and second element of timeblock
      HDR.ADI.scale{k} = tmp;
      [HDR,tmp] = matread(HDR,['titles_block' int2str(k)]);	% read first and second element of timeblock
      HDR.ADI.titles{k} = tmp;
      
      [HDR,tmp] = matread(HDR,['units_block' int2str(k)]);	% read first and second element of timeblock
      HDR.ADI.units{k} = char(tmp);
      if k==1;
        HDR.PhysDim = char(sparse(find(HDR.ADI.index{1}),1:sum(HDR.ADI.index{1}>0),1)*HDR.ADI.units{1}); % for compatibility with the EDF toolbox
      elseif any(size(HDR.ADI.units{k-1})~=size(tmp))
        fprintf(HDR.FILE.stderr,'Warning MATOPEN: Units are different from block to block\n');
      elseif any(any(HDR.ADI.units{k-1}~=tmp))
        fprintf(HDR.FILE.stderr,'Warning MATOPEN: Units are different from block to block\n');
      end;
      HDR.PhysDim = char(sparse(find(HDR.ADI.index{k}),1:sum(HDR.ADI.index{k}>0),1)*HDR.ADI.units{k}); % for compatibility with the EDF toolbox
      %HDR.PhysDim=HDR.ADI.PhysDim;
    end;
    HDR.T0 = datevec(datenum(1970,1,1)+HDR.ADI.ti(1,1)/24/3600);
    for k=1:size(HDR.ADI.comtext,1),
      HDR.ADI.comtime0(k)=HDR.ADI.comtick(k)./HDR.SampleRate(HDR.ADI.comblok(k))'+HDR.ADI.ti(HDR.ADI.comblok(k),1)-HDR.ADI.ti(1,1);
    end;
    
    % Test if timeindex is increasing
    tmp = size(HDR.ADI.ti,1);
    if ~all(HDR.ADI.ti(2:tmp,2)>HDR.ADI.ti(1:tmp-1,1)),
      HDR.ErrNum=-1;
      fprintf(HDR.FILE.stderr,'Warning MATOPEN: Time index are not monotonic increasing !!!\n');
      return;
    end;
    % end of ADI-Mode
    HDR.Calib = sparse(2:HDR.NS+1,1:HDR.NS,ones(1,HDR.NS));
  else
    fclose(HDR.FILE.FID);
    HDR.FILE.FID = -1;
    return;
  end;