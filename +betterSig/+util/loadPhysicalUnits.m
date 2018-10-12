function UnitsOfMeasurement = loadPhysicalUnits

%%%---------- Physical units ------------%%%
[path,~,~] = fileparts(mfilename('fullpath'));

fid = fopen(fullfile(path,'units.csv'));

line = fgetl(fid);
N1 = 0; N2 = 0;
while ~feof(fid),
  N2 = N2 + 1;
  if ~strncmp(line,'#',1),
    ix = mod(cumsum(line==char(34)),2); %% "
    tmp = line;
    tmp(~~ix) = ' ';
    ix  = find(tmp==',');
    if (length(ix)~=3)
      fprintf(2,'Warning: line (%3i: %s) not valid\n',N2,line);
    else
      t1 = line(1:ix(1)-1);
      t2 = line(ix(1)+1:ix(2)-1);
      t3 = line(ix(2)+1:ix(3)-1);
      t4 = line(ix(3)+1:end);
      Code = str2double(t1);
      if ~isempty(Code)
        N1 = N1 + 1;
        UnitsOfMeasurement.Code(N1,1)   = Code;
        ix = min(find([t2, '[' ] == '['))-1;
        UnitsOfMeasurement.Symbol{N1,1} = char(t2(2:ix-1));
      end;
    end;
  end;
  line = fgetl(fid);
end;
fclose(fid);