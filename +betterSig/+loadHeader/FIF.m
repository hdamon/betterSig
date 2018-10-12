function [HDR, immediateReturn] = FIF(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


if any(exist('rawdata')==[3,6]),
    if isempty(FLAG_NUMBER_OF_OPEN_FIF_FILES)
      FLAG_NUMBER_OF_OPEN_FIF_FILES = 0;
    end;
    if ~any(FLAG_NUMBER_OF_OPEN_FIF_FILES==[0,1])
      fprintf(HDR.FILE.stderr,'ERROR SOPEN (FIF): number of open FIF files should be zero or one\n\t Perhaps, you forgot to SCLOSE(HDR,CHAN,MODE,ReRefMx) the previous FIF-file.\n');
      %return;
    end;
    
    try
      rawdata('any',HDR.FileName);  % opens file
      FLAG_NUMBER_OF_OPEN_FIF_FILES = 1;
    catch
      tmp = which('rawdata');
      [p,f,e]=fileparts(tmp);
      fprintf(HDR.FILE.stderr,'ERROR SOPEN (FIF): Maybe you forgot to do \"export LD_LIBRARY_PATH=%s/i386 \" before you started Matlab. \n',p);
      return
    end
    HDR.FILE.FID = 1;
    HDR.SampleRate = rawdata('sf');
    HDR.AS.endpos = rawdata('samples');
    [HDR.MinMax,HDR.Cal] = rawdata('range');
    [HDR.Label, cIDX, number] = channames(HDR.FileName);
    if (sum(cIDX==1)==122)
      tmp = 'NM122coildef.mat';
      if exist(tmp,'file'),
        load(tmp);
        HDR.ELEC.XYZ = VM(ceil([1:122]/2),:);
      end;
    elseif (sum(cIDX==1)==306)
      tmp = 'NM306coildef.mat';
      if exist(tmp,'file'),
        load(tmp);
        HDR.ELEC.XYZ = VM(ceil([1:306]/3),:);
      end;
    end;
    
    rawdata('goto',-inf);
    [buf, status] = rawdata('next');
    HDR.Dur = rawdata('t');
    [HDR.NS,HDR.SPR] = size(buf);
    HDR.NRec = 1;
    HDR.AS.bpb = HDR.NS * 2;
    HDR.Calib = [zeros(1,HDR.NS);diag(HDR.Cal)];
    
    rawdata('goto', -inf);
    HDR.FILE.POS = 0;
    HDR.FILE.OPEN = 1;
    HDR.PhysDimCode = zeros(HDR.NS,1);
    
  else
    fprintf(HDR.FILE.stderr,'ERROR SOPEN (FIF): NeuroMag FIFF access functions not available. \n');
    fprintf(HDR.FILE.stderr,'\tOnline available at: http://www.kolumbus.fi/kuutela/programs/meg-pd/ \n');
    return;
  end;
  