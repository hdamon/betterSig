function [HDR, immediateReturn] = ZIP(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


 % extract content into temporary directory;
  HDR.ZIP.TEMPDIR = tempname;
  mkdir(HDR.ZIP.TEMPDIR);
  system(sprintf('unzip %s -d %s >NULL',HDR.FileName,HDR.ZIP.TEMPDIR));
  
  H1 = [];
  fn = fullfile(HDR.ZIP.TEMPDIR,'content.xml');
  if exist(fn,'file')
    H1.FileName = fn;
    H1.FILE.PERMISSION = 'r';
    HDR.Content = openxml(H1);
  end;
  fn = fullfile(HDR.ZIP.TEMPDIR,'META-INF/manifest.xml');
  if exist(fn,'file')
    H1.FileName = fn;
    H1.FILE.PERMISSION = 'r';
    HDR.manifest = openxml(H1);
  end;
  fn = fullfile(HDR.ZIP.TEMPDIR,'meta.xml');
  if exist(fn,'file')
    H1.FileName = fn;
    H1.FILE.PERMISSION = 'r';
    HDR.Meta = openxml(H1);
  end;
  fn = fullfile(HDR.ZIP.TEMPDIR,'styles.xml');
  if exist(fn,'file')
    H1.FileName = fn;
    H1.FILE.PERMISSION = 'r';
    HDR.Styles = openxml(H1);
  end;
  fn = fullfile(HDR.ZIP.TEMPDIR,'settings.xml');
  if exist(fn,'file')
    H1.FileName = fn;
    H1.FILE.PERMISSION = 'r';
    HDR.Settings = openxml(H1);
  end;
  
  if 0,
  elseif strncmp(HDR.ZIP.tmp(31:end),'mimetypeapplication/vnd.sun.xml.writer',38)
  elseif strncmp(HDR.ZIP.tmp(31:end),'mimetypeapplication/vnd.sun.xml.calc',36)   % OpenOffice 1.x
    HDR.table = HDR.XML.office_body.table_table;
  elseif strncmp(HDR.ZIP.tmp(31:end),'mimetypeapplication/vnd.oasis.opendocument.spreadsheet',54)   % OpenOffice 2.0
    HDR.table = HDR.XML.office_body.office_spreadsheet.table_table;
  end;
  
  if isfield(HDR,'table'),
    try
      for k0 = 1, %:length(HDR.table),
        strarray= {};
        c_table = HDR.table{k0};
        if ~isempty(c_table.table_table_row)
          nr = length(c_table.table_table_row);
          for k1 = 1:nr-1,
            c_row = c_table.table_table_row{k1}.table_table_cell;
            nc = length(c_row);
            for k2 = 1:nc-1,
              strarray{k1,k2} = c_row{k2}.text_p;
            end;
          end;
        end;
        HDR.sa{k0} = strarray;
        HDR.data = repmat(NaN,size(strarray));
        for k1=1:size(HDR.data,1)
          for k2=1:size(HDR.data,2)
            tmp = strarray{k1,k2};
            tmp(tmp==',')=='.';
            if ~isempty(tmp)
              tmp = str2double(tmp)
            end;
            if prod(size(tmp))==1,
              HDR.data(k1,k2) = tmp;
            else
              strarray{k1,k2},
            end;
          end;
        end;
      end;
    catch;
    end
  end;
  
  if isempty(H1),
    fn = dir(HDR.ZIP.TEMPDIR);
    fn = fn(~[fn.isdir]);
    if (length(fn)==1)
      HDR = sopen(fullfile(HDR.ZIP.TEMPDIR,fn(1).name));
      return;
    end;
  end;
  
  % remove temporary directory - could be moved to SCLOSE
  [SUCCESS,MESSAGE,MESSAGEID] = rmdir(HDR.ZIP.TEMPDIR,'s');
  
  