function [HDR, immediateReturn] = DXF(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 if any(HDR.FILE.PERMISSION=='r'),
    HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
    
    while ~feof(HDR.FILE.FID),
      line1 = fgetl(HDR.FILE.FID);
      line2 = fgetl(HDR.FILE.FID);
      
      [val,status] = str2double(line1);
      
      if any(status),
        error('SOPEN (DXF)');
      elseif val==999,
        
      elseif val==0,
        
      elseif val==1,
        
      elseif val==2,
        
      else
        
      end;
    end;
    
    fclose(HDR.FILE.FID);
  end