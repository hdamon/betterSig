function DecimalFactor = loadDecimalFactors
% Load Decimal Factors
%
% Output
% ------
%



[path,~,~] = fileparts(mfilename('fullpath'));

fullName = fullfile(path,'DecimalFactors.txt');
[fid,msg] = fopen(fullName,'rt','ieee-le');

line = fgetl(fid);
N1 = 0; N2 = 0;
while ~feof(fid)
  if ~strncmp(line,'#',1)
    N1 = N1 + 1;
    [n,v,s] = str2double(line);
    n = n(~v);
    DecimalFactor.Code(N1,1) = n(2);
    DecimalFactor.Cal(N1,1) = n(1);
    s = s(~~v);
    if any(v)
      DecimalFactor.Name(N1,1) = s(1);
      DecimalFactor.Prefix(N1,1) = s(2);
    end;
  end;
  line = fgetl(fid);
end;
fclose(fid);