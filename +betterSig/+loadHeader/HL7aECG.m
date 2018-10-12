function [HDR, immediateReturn] = HL7aECG(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 if exist('mexSLOAD','file')
    try
      [s,H]  = mexSLOAD(HDR.FileName,0,'UCAL:ON');
    catch
      fprintf(stdout,'SOPEN: failed to read XML file %s.',HDR.FileName);
      return;
    end;
    H.data = s;
    H.FLAG = HDR.FLAG;
    H.TYPE = 'native';
    H.FILE = HDR.FILE;
    H.FILE.POS = 0;
    HDR    = H;
  else
    fprintf(stdout,'SOPEN: failed to read HL7aECG/FDA-XML files.\nUse mexSLOAD from BioSig4C++ instead!\n');
    %HDR = openxml(HDR,CHAN,MODE,ReRefMx); 	% experimental version for reading various xml files
    return;
  end;