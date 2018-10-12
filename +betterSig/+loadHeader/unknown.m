function [HDR, immediateReturn] = unknown(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


if ~isfield(HDR.FLAG,'ASCII'); HDR.FLAG.ASCII = 0; end;
  if HDR.FLAG.ASCII,
    s = HDR.s;
    if strcmpi(HDR.FILE.Ext,'DAT')
      [NUM, STATUS,STRARRAY] = str2double(char(s));
      if (size(NUM,2)<4) && ~any(any(STATUS))
        HDR.Label = STRARRAY(:,1);
        r2 = sum(NUM(:,2:3).^2,2);
        HDR.ELEC.XYZ = [NUM(:,2:3),sqrt(max(r2)-r2)];
        HDR.CHAN  = NUM(:,1);
        HDR.TYPE  = 'ELPOS';
      elseif (size(NUM,2)==4) && ~any(any(STATUS))
        HDR.Label = STRARRAY(:,1);
        HDR.ELEC.XYZ  = NUM(:,2:4);
        HDR.ELEC.CHAN = NUM(:,1);
        HDR.TYPE  = 'ELPOS';
      elseif (size(NUM,2)==4) && ~any(any(STATUS(:,[1,3:4])))
        HDR.Label = STRARRAY(:,2);
        r2 = sum(NUM(:,3:4).^2,2);
        HDR.ELEC.XYZ = [NUM(:,3:4),sqrt(max(r2)-r2)];
        HDR.CHAN  = NUM(:,1);
        HDR.TYPE  = 'ELPOS';
      elseif (size(NUM,2)==5) && ~any(any(STATUS(:,3:5)))
        HDR.Label = STRARRAY(:,1);
        HDR.ELEC.XYZ  = NUM(:,3:5);
        HDR.TYPE  = 'ELPOS';
      end;
      return;
      
      
    elseif strncmp(s,'NumberPositions',15) && strcmpi(HDR.FILE.Ext,'elc');  % Polhemus
      K = 0;
      [tline, s] = strtok(s, [10,13]);
      while ~isempty(s),
        [num, stat, strarray] = str2double(tline);
        if strcmp(strarray{1},'NumberPositions')
          NK = num(2);
        elseif strcmp(strarray{1},'UnitPosition')
          HDR.ELEC.PositionUnit = strarray{2};
        elseif strcmp(strarray{1},'Positions')
          ix = strfind(s,'Labels');
          ix = min([ix-1,length(s)]);
          [num, stat, strarray] = str2double(s(1:ix));
          s(1:ix) = [];
          if ~any(any(stat))
            HDR.ELEC.XYZ = num*[0,-1,0;1,0,0;0,0,1];
            HDR.TYPE = 'ELPOS';
          end;
        elseif strcmp(strarray{1},'Labels')
          [tline, s] = strtok(s, [10,13]);
          [num, stat, strarray] = str2double(tline);
          HDR.Label = strarray';
        end
        [tline, s] = strtok(s, [10,13]);
      end;
      return;
      
    elseif strncmp(s,'Site',4) && strcmpi(HDR.FILE.Ext,'txt');
      [line1, s] = strtok(s, [10,13]);
      s(s==',') = '.';
      [NUM, STATUS, STRARRAY] = str2double(s,[9,32]);
      if (size(NUM,2)==3) && ~any(any(STATUS(:,2:3)))
        HDR.Label = STRARRAY(:,1);
        Theta     = abs(NUM(:,2))*pi/180;
        Phi       = NUM(:,3)*pi/180 + pi*(NUM(:,2)<0);
        HDR.ELEC.XYZ = [sin(Theta).*cos(Phi),sin(Theta).*sin(Phi),cos(Theta)];
        HDR.ELEC.R   = 1;
        HDR.TYPE     = 'ELPOS';
      elseif (size(NUM,2)==4) && ~any(any(STATUS(:,2:4)))
        HDR.Label = STRARRAY(:,1);
        HDR.ELEC.XYZ = NUM(:,2:4);
        HDR.TYPE  = 'ELPOS';
      end;
      return;
      
    elseif strcmpi(HDR.FILE.Ext,'elp')
      [line1,s]=strtok(s,[10,13]);
      [NUM, STATUS,STRARRAY] = str2double(char(s));
      if size(NUM,2)==3,
        if ~any(any(STATUS(:,2:3)))
          HDR.Label = STRARRAY(:,1);
          Theta = NUM(:,2)*pi/180;
          Phi   = NUM(:,3)*pi/180;
          HDR.ELEC.XYZ = [sin(Theta).*cos(Phi),sin(Theta).*sin(Phi),cos(Theta)];
          HDR.ELEC.R   = 1;
          HDR.TYPE = 'ELPOS';
        end;
      elseif size(NUM,2)==4,
        if ~any(any(STATUS(:,3:4)))
          HDR.Label = STRARRAY(:,2);
          Theta = NUM(:,2)*pi/180;
          Phi   = NUM(:,3)*pi/180;
          HDR.ELEC.XYZ = [sin(Theta).*cos(Phi),sin(Theta).*sin(Phi),cos(Theta)];
          HDR.ELEC.R   = 1;
          HDR.ELEC.CHAN = NUM(:,1);
          HDR.TYPE = 'ELPOS';
        end;
      end;
      return;
      
    elseif strcmpi(HDR.FILE.Ext,'ced')
      [line1,s]=strtok(char(s),[10,13]);
      [NUM, STATUS,STRARRAY] = str2double(char(s));
      if ~any(any(STATUS(:,[1,5:7])))
        HDR.Label = STRARRAY(:,2);
        HDR.ELEC.XYZ  = NUM(:,5:7)*[0,1,0;-1,0,0;0,0,1];
        HDR.ELEC.CHAN = NUM(:,1);
        HDR.TYPE  = 'ELPOS';
      end;
      return;
      
      
    elseif (strcmpi(HDR.FILE.Ext,'loc') || strcmpi(HDR.FILE.Ext,'locs'))
      %                        [line1,s]=strtok(char(s),[10,13]);
      [NUM, STATUS,STRARRAY] = str2double(char(s));
      if ~any(any(STATUS(:,1:3)))
        HDR.Label = STRARRAY(:,4);
        HDR.CHAN  = NUM(:,1);
        Phi       = NUM(:,2)/180*pi;
        %Theta     = asin(NUM(:,3));
        Theta     = NUM(:,3);
        HDR.ELEC.XYZ = [sin(Theta).*sin(Phi),sin(Theta).*cos(Phi),cos(Theta)];
        HDR.TYPE  = 'ELPOS';
      end;
      return;
      
    elseif strcmpi(HDR.FILE.Ext,'sfp')
      [NUM, STATUS,STRARRAY] = str2double(char(s));
      if ~any(any(STATUS(:,2:4)))
        HDR.Label    = STRARRAY(:,1);
        HDR.ELEC.XYZ = NUM(:,2:4);
        HDR.TYPE     = 'ELPOS';
      end;
      return;
      
    elseif strcmpi(HDR.FILE.Ext,'xyz')
      [NUM, STATUS,STRARRAY] = str2double(char(s));
      if ~any(any(STATUS(:,2:4)))
        HDR.Label    = STRARRAY(:,5);
        HDR.ELEC.CHAN= NUM(:,1);
        HDR.ELEC.XYZ = NUM(:,2:4);
        HDR.TYPE     = 'ELPOS';
      end;
      return;
    end;
  else
    %HDR.ErrMsg = sprintf('ERROR SOPEN: File %s could not be opened - unknown type.\n',HDR.FileName);
    %fprintf(HDR.FILE.stderr,'ERROR SOPEN: File %s could not be opened - unknown type.\n',HDR.FileName);
  end;