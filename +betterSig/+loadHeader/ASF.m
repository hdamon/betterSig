function [HDR, immediateReturn] = ASF(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 if exist('asfopen','file'),
    HDR = asfopen(HDR,[HDR.FILE.PERMISSION,'b']);
  else
    fprintf(1,'SOPEN ASF-File: Microsoft claims that its illegal to implement the ASF format.\n');
    fprintf(1,'     Anyway Microsoft provides the specification at http://www.microsoft.com/windows/windowsmedia/format/asfspec.aspx \n');
    fprintf(1,'     So, you can implement it and use it for your own purpose.\n');
  end;