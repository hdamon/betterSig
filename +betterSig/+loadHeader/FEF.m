function [HDR, immediateReturn] = FEF(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


  HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],HDR.Endianity);
  status = fseek(HDR.FILE.FID,32,'bof'); 	% skip preamble
  
  if exist('fefopen','file') && ~status,
    HDR = fefopen(HDR,CHAN,MODE,ReRefMx);
  end;
  
  fprintf(HDR.FILE.stderr,'Warning SOPEN: Implementing Vital/FEF format not completed yet. Contact <Biosig-general@lists.sourceforge.net> if you are interested in this feature.\n');
  HDR.FILE.FID = -1;