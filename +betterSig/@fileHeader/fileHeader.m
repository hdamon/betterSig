classdef fileHeader < dynamicprops
% File Header Object Class
%
%

properties
  FileName = '';
  FILE = struct(...
                'Name',[], ...
                'Path',[], ...
                'Ext',[],...
                'PERMISSION','r',...
                'OPEN',0,...
                'FID',-1,...
                'size',nan,...
                'stdout',1,...
                'stderr',2);
  TYPE = 'unknown';
  ErrNum = 0 ;
  ErrMsg = '' ;
  keycode  
  FLAG = struct(...
              'FILT',0,...
              'TRIGGERED',0,...
              'UCAL',nan,...
              'OVERFLOWDETECTION',nan,...
              'FORCEALLCHANNEL',nan,...
              'OUTPUT','double');  
  NS = NaN;
  SampleRate = NaN;
  T0 = nan(1,6);
  Filter = struct('Notch',nan,'LowPass',nan,'HighPass',nan);  
  EVENT = struct('TYP',[],'POS',[]);
end

%% PUBLIC METHODS
%%%%%%%%%%%%%%%%%%%%%%%%%
methods
  function obj = fileHeader(argIn,varargin)
    
    p = inputParser;
    p.addOptional('PERMISSION','r',@(x) ischar(x));
    p.addOptional('CHAN',0,@(x) isnumeric(x));
    p.addOptional('MODE','',@(x) ischar(x));
    p.parse(varargin{:});
    
    PERMISSION = p.Results.PERMISSION;
    CHAN = p.Results.CHAN;
    MODE = p.Results.MODE;
    
    if nargin>0
      if ischar(argIn)
        obj.FileName = argIn;
      elseif isfield(argIn,'name')
        obj.FileName = argIn.name;
      elseif isa(argIn,'betterSig.fileHeader')        
        obj = argIn;
      else
        error('Unknown input type');
      end;
    end;
    
    obj.FILE.PERMISSION = PERMISSION;
    obj.setFILEFields;
    obj.getFileSize;
    obj.parseFirst1024;
  end
  
  function set.FileName(obj,val)
    assert(ischar(val),'FileName must be a character string');
    obj.FileName = val;
  end;
  
  function set.FILE(obj,val)
    allFields = {'Name','Path','Ext','PERMISSION','OPEN','FID','size','stdout','stderr'};
    if any(~ismember(fields(val),allFields))
      error('Invalid FILE field name');
    end
    if isfield(val,'PERMISSION')&&~any(val.PERMISSION(1)=='RWrrw')
      warning('PERMISSION must be ''r'' or ''w''. Assuming PERMISSION is ''r''\');
      val.PERMISSION = 'r';
    end;
    
    obj.FILE = val;
  end
  
  parseFirst1024(HDR);
  
  function setFILEFields(obj)   
    [pfad,file,FileExt] = fileparts(obj.FileName);
    if ~isempty(pfad)
      obj.FILE.Path = pfad;
    else
      obj.FILE.Path = pwd;
    end
    obj.FILE.Name = file;
    obj.FILE.Ext = char(FileExt(2:end));     
  end
  
  function setNotFound(obj)
    obj.ErrNum = -1;
    obj.ErrMsg = -1;
  end
  
  function [fid,msg] = fopen(HDR)
    [fid,msg] = fopen(obj.FileName,obj.PERMISSION);
    if fid<0
      HDR.setNotFound;
      return;
    else
      
    end
  end
      
  
  function val = getFileSize(obj)
    if isnan(obj.FILE.size)
      fid = fopen(obj.FileName,obj.FILE.PERMISSION);
      if fid<0
        obj.setNotFound;        
        return;
      else
        if ~any(obj.FILE.PERMISSION=='z')
          fseek(fid,0,'eof');
        else
          fseek(fid,2^32,'bof');
        end
        obj.FILE.size = ftell(fid);
      end
    end
    val = obj.FILE.size;
  end
  
  
  function set.FLAG(obj,val)
    allFields = {'FILT','TRIGGERED','UCAL','OVERFLOWDETECTION','FORCEALLCHANNEL','OUTPUT'};
        if any(~ismember(fields(val),allFields))
      error('Invalid FLAG field name');
    end
    obj.FLAG = val;
  end
  
end

end