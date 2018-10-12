function [HDR, immediateReturn] = WFT(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


  HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'b'],'ieee-le');
  [s,c] = fread(HDR.FILE.FID,1536,'uint8');
  [tmp,s] = strtok(s,char([0,32]));
  Nic_id0 = str2double(tmp);
  [tmp,s] = strtok(s,char([0,32]));
  Niv_id1 = str2double(tmp);
  [tmp,s] = strtok(s,char([0,32]));
  Nic_id2 = str2double(tmp);
  [tmp,s] = strtok(s,char([0,32]));
  User_id = str2double(tmp);
  [tmp,s] = strtok(s,char([0,32]));
  HDR.HeadLen = str2double(tmp);
  [tmp,s] = strtok(s,char([0,32]));
  HDR.FILE.Size = str2double(tmp);
  [tmp,s] = strtok(s,char([0,32]));
  HDR.VERSION = str2double(tmp);
  [tmp,s] = strtok(s,char([0,32]));
  HDR.WFT.WaveformTitle = str2double(tmp);
  [tmp,s] = strtok(s,char([0,32]));
  HDR.T0(1) = str2double(tmp);
  [tmp,s] = strtok(s,char([0,32]));
  HDR.T0(1,2) = str2double(tmp);
  [tmp,s] = strtok(s,char([0,32]));
  HDR.T0(1,3) = str2double(tmp);
  [tmp,s] = strtok(s,char([0,32]));
  tmp = str2double(tmp);
  HDR.T0(1,4:6) = [floor(tmp/3600000),floor(rem(tmp,3600000)/60000),rem(tmp,60000)];
  [tmp,s] = strtok(s,char([0,32]));
  HDR.SPR = str2double(tmp);
  [tmp,s] = strtok(s,char([0,32]));
  HDR.Off = str2double(tmp);
  [tmp,s] = strtok(s,char([0,32]));
  HDR.Cal = str2double(tmp);
  
  fseek(HDR.FILE.FID,HDR.HeadLen,'bof');
  
  fprintf(HDR.FILE.stderr,'Warning SOPEN: Implementing Nicolet WFT file format not completed yet. Contact <Biosig-general@lists.sourceforge.net> if you are interested in this feature.\n');
  fclose(HDR.FILE.FID);