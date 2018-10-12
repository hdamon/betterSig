function [HDR, immediateReturn] = ABF(HDR,CHAN,MODE,ReRefMx)
   immediateReturn = false; % Default Value


  fprintf(HDR.FILE.stderr,'Warning: SOPEN (ABF) is still experimental.\n');
  if any(HDR.FILE.PERMISSION=='r'),
    HDR.FILE.FID = fopen(HDR.FileName,[HDR.FILE.PERMISSION,'t'],'ieee-le');
    HDR.ABF.ID = char(fread(HDR.FILE.FID,[1,4],'uint8'));
    %HDR.ABF.ID = fread(HDR.FILE.FID,1,'uint32');
    %HDR.Version = fread(HDR.FILE.FID,1,'float32');
    HDR.Version = fread(HDR.FILE.FID,1,'uint32');
    HDR.ABF.Mode = fread(HDR.FILE.FID,1,'uint16');
    HDR.AS.endpos = fread(HDR.FILE.FID,1,'uint32');
    HDR.ABF.NumPoinstsIgnored = fread(HDR.FILE.FID,1,'uint16');
    HDR.NRec = fread(HDR.FILE.FID,1,'uint32');
    t = fread(HDR.FILE.FID,3,'uint32');
    HDR.T0(1:3) = [floor(t(1)/1e4), floor(mod(t(1),1e4)/100), mod(t(1),100)];
    HDR.T0(4:6) = [floor(t(2)/3600),floor(mod(t(2),3600)/60),mod(t(2),60)];
    if HDR.T0(1)<80, HDR.T0(1)=HDR.T0(1)+2000;
    elseif HDR.T0(1)<100, HDR.T0(1)=HDR.T0(1)+1900;
    end;
    
    HDR.ABF.HeaderVersion = fread(HDR.FILE.FID,1,'float');
    if HDR.ABF.HeaderVersion>=1.6,
      HDR.HeadLen = 1394+6144+654;
    else
      HDR.HeadLen =  370+2048+654;
    end;
    HDR.ABF.FileType = fread(HDR.FILE.FID,1,'uint16');
    HDR.ABF.MSBinFormat = fread(HDR.FILE.FID,1,'uint16');
    
    HDR.ABF.SectionStart = fread(HDR.FILE.FID,15,'uint32');
    DataFormat = fread(HDR.FILE.FID,1,'uint16');
    HDR.ABF.simultanousScan = fread(HDR.FILE.FID,1,'uint16');
    t = fread(HDR.FILE.FID,4,'uint32');
    
    HDR.NS = fread(HDR.FILE.FID,1,'uint16');
    tmp = fread(HDR.FILE.FID,4,'float32');
    
    HDR.SampleRate = 1000/tmp(1);
    if ~DataFormat
      HDR.GDFTYP = 3;		% int16
      HDR.AS.bpb = 2*HDR.NS;
    else
      HDR.GDFTYP = 16;	% float32
      HDR.AS.bpb = 4*HDR.NS;
    end;
    HDR.SPR = HDR.AS.endpos/HDR.NRec;
    HDR.Dur = HDR.SPR/HDR.SampleRate;
    if HDR.FILE.size ~= HDR.HeadLen + HDR.AS.bpb*HDR.NRec*HDR.SPR;
      [HDR.FILE.size,HDR.HeadLen,HDR.AS.bpb*HDR.NRec*HDR.SPR]
      fprintf(HDR.FILE.stderr,'Warning SOPEN (ABF): filesize does not fit.\n');
    end;
    
    t = fread(HDR.FILE.FID,5,'uint32');
    
    t = fread(HDR.FILE.FID,3,'uint16');
    HDR.FLAG.AVERAGE = t(1);
    
    HDR.TRIGGER.THRESHOLD = fread(HDR.FILE.FID,1,'float');
    t = fread(HDR.FILE.FID,3,'uint16');
    
    % this part is from IMPORT_ABF.M from
    %     � 2002 - Michele Giugliano, PhD (http://www.giugliano.info) (Bern, Friday March 8th, 2002 - 20:09)
    
    HDR.ABF.ScopeOutputInterval  = fread(HDR.FILE.FID,1,'float'); % 174
    HDR.ABF.EpisodeStartToStart  = fread(HDR.FILE.FID,1,'float'); % 178
    HDR.ABF.RunStartToStart      = fread(HDR.FILE.FID,1,'float'); % 182
    HDR.ABF.TrialStartToStart    = fread(HDR.FILE.FID,1,'float'); % 186
    HDR.ABF.AverageCount         = fread(HDR.FILE.FID,1,'int');   % 190
    HDR.ABF.ClockChange          = fread(HDR.FILE.FID,1,'int');   % 194
    HDR.ABF.AutoTriggerStrategy  = fread(HDR.FILE.FID,1,'int16'); % 198
    %-----------------------------------------------------------------------------
    % Display Parameters
    HDR.ABF.DrawingStrategy      = fread(HDR.FILE.FID,1,'int16'); % 200
    HDR.ABF.TiledDisplay         = fread(HDR.FILE.FID,1,'int16'); % 202
    HDR.ABF.EraseStrategy        = fread(HDR.FILE.FID,1,'int16'); % 204
    HDR.ABF.DataDisplayMode      = fread(HDR.FILE.FID,1,'int16'); % 206
    HDR.ABF.DisplayAverageUpdate = fread(HDR.FILE.FID,1,'int');   % 208
    HDR.ABF.ChannelStatsStrategy = fread(HDR.FILE.FID,1,'int16'); % 212
    HDR.ABF.CalculationPeriod    = fread(HDR.FILE.FID,1,'int');   % 214
    HDR.ABF.SamplesPerTrace      = fread(HDR.FILE.FID,1,'int');   % 218
    HDR.ABF.StartDisplayNum      = fread(HDR.FILE.FID,1,'int');   % 222
    HDR.ABF.FinishDisplayNum     = fread(HDR.FILE.FID,1,'int');   % 226
    HDR.ABF.MultiColor           = fread(HDR.FILE.FID,1,'int16'); % 230
    HDR.ABF.ShowPNRawData        = fread(HDR.FILE.FID,1,'int16'); % 232
    HDR.ABF.StatisticsPeriod     = fread(HDR.FILE.FID,1,'float'); % 234
    HDR.ABF.StatisticsMeasurements=fread(HDR.FILE.FID,1,'int');   % 238
    %-----------------------------------------------------------------------------
    % Hardware Information
    HDR.ABF.StatisticsSaveStrategy=fread(HDR.FILE.FID,1,'int16'); % 242
    HDR.ABF.ADCRange             = fread(HDR.FILE.FID,1,'float'); % 244
    HDR.ABF.DACRange             = fread(HDR.FILE.FID,1,'float'); % 248
    HDR.ABF.ADCResolution        = fread(HDR.FILE.FID,1,'int');   % 252
    HDR.ABF.DACResolution        = fread(HDR.FILE.FID,1,'int');   % 256
    %-----------------------------------------------------------------------------
    % Environmental Information
    HDR.ABF.ExperimentType       = fread(HDR.FILE.FID,1,'int16'); % 260
    HDR.ABF.x_AutosampleEnable   = fread(HDR.FILE.FID,1,'int16'); % 262
    HDR.ABF.x_AutosampleADCNum   = fread(HDR.FILE.FID,1,'int16'); % 264
    HDR.ABF.x_AutosampleInstrument=fread(HDR.FILE.FID,1,'int16'); % 266
    HDR.ABF.x_AutosampleAdditGain= fread(HDR.FILE.FID,1,'float'); % 268
    HDR.ABF.x_AutosampleFilter   = fread(HDR.FILE.FID,1,'float'); % 272
    HDR.ABF.x_AutosampleMembraneCapacitance=fread(HDR.FILE.FID,1,'float'); % 276
    HDR.ABF.ManualInfoStrategy   = fread(HDR.FILE.FID,1,'int16'); % 280
    HDR.ABF.CellID1              = fread(HDR.FILE.FID,1,'float'); % 282
    HDR.ABF.CellID2              = fread(HDR.FILE.FID,1,'float'); % 286
    HDR.ABF.CellID3              = fread(HDR.FILE.FID,1,'float'); % 290
    HDR.ABF.CreatorInfo          = fread(HDR.FILE.FID,16,'uint8'); % 16char % 294
    HDR.ABF.x_FileComment        = fread(HDR.FILE.FID,56,'uint8'); % 56char % 310
    HDR.ABF.Unused366            = fread(HDR.FILE.FID,12,'uint8'); % 12char % 366
    %-----------------------------------------------------------------------------
    % Multi-channel Information
    HDR.ABF.ADCPtoLChannelMap    = fread(HDR.FILE.FID,16,'int16');    % 378
    HDR.ABF.ADCSamplingSeq       = fread(HDR.FILE.FID,16,'int16');    % 410
    HDR.ABF.ADCChannelName       = fread(HDR.FILE.FID,16*10,'uint8');  % 442
    HDR.ABF.ADCUnits             = fread(HDR.FILE.FID,16*8,'uint8');   % 8char % 602
    HDR.ABF.ADCProgrammableGain  = fread(HDR.FILE.FID,16,'float');    % 730
    HDR.ABF.ADCDisplayAmplification=fread(HDR.FILE.FID,16,'float');   % 794
    HDR.ABF.ADCDisplayOffset     = fread(HDR.FILE.FID,16,'float');    % 858
    HDR.ABF.InstrumentScaleFactor= fread(HDR.FILE.FID,16,'float');    % 922
    HDR.ABF.InstrumentOffset     = fread(HDR.FILE.FID,16,'float');    % 986
    HDR.ABF.SignalGain           = fread(HDR.FILE.FID,16,'float');    % 1050
    HDR.Off			     = fread(HDR.FILE.FID,16,'float');    % 1114
    HDR.ABF.SignalLowpassFilter  = fread(HDR.FILE.FID,16,'float');    % 1178
    HDR.ABF.SignalHighpassFilter = fread(HDR.FILE.FID,16,'float');    % 1242
    HDR.ABF.DACChannelName       = fread(HDR.FILE.FID,4*10,'uint8');   % 1306
    HDR.ABF.DACChannelUnits      = fread(HDR.FILE.FID,4*8,'uint8');    % 8char % 1346
    HDR.ABF.DACScaleFactor       = fread(HDR.FILE.FID,4,'float');     % 1378
    HDR.ABF.DACHoldingLevel      = fread(HDR.FILE.FID,4,'float');     % 1394
    HDR.ABF.SignalType           = fread(HDR.FILE.FID,1,'int16');     % 12char % 1410
    HDR.ABF.Unused1412           = fread(HDR.FILE.FID,10,'uint8');     % 10char % 1412
    %-----------------------------------------------------------------------------
    % Synchronous Timer Outputs
    HDR.ABF.OUTEnable            = fread(HDR.FILE.FID,1,'int16');     % 1422
    HDR.ABF.SampleNumberOUT1     = fread(HDR.FILE.FID,1,'int16');     % 1424
    HDR.ABF.SampleNumberOUT2     = fread(HDR.FILE.FID,1,'int16');     % 1426
    HDR.ABF.FirstEpisodeOUT      = fread(HDR.FILE.FID,1,'int16');     % 1428
    HDR.ABF.LastEpisodeOUT       = fread(HDR.FILE.FID,1,'int16');     % 1430
    HDR.ABF.PulseSamplesOUT1     = fread(HDR.FILE.FID,1,'int16');     % 1432
    HDR.ABF.PulseSamplesOUT2     = fread(HDR.FILE.FID,1,'int16');     % 1434
    %-----------------------------------------------------------------------------
    % Epoch Waveform and Pulses
    HDR.ABF.DigitalEnable        = fread(HDR.FILE.FID,1,'int16');     % 1436
    HDR.ABF.x_WaveformSource     = fread(HDR.FILE.FID,1,'int16');     % 1438
    HDR.ABF.ActiveDACChannel     = fread(HDR.FILE.FID,1,'int16');     % 1440
    HDR.ABF.x_InterEpisodeLevel  = fread(HDR.FILE.FID,1,'int16');     % 1442
    HDR.ABF.x_EpochType          = fread(HDR.FILE.FID,10,'int16');    % 1444
    HDR.ABF.x_EpochInitLevel     = fread(HDR.FILE.FID,10,'float');    % 1464
    HDR.ABF.x_EpochLevelInc      = fread(HDR.FILE.FID,10,'float');    % 1504
    HDR.ABF.x_EpochInitDuration  = fread(HDR.FILE.FID,10,'int16');    % 1544
    HDR.ABF.x_EpochDurationInc   = fread(HDR.FILE.FID,10,'int16');    % 1564
    HDR.ABF.DigitalHolding       = fread(HDR.FILE.FID,1,'int16');     % 1584
    HDR.ABF.DigitalInterEpisode  = fread(HDR.FILE.FID,1,'int16');     % 1586
    HDR.ABF.DigitalValue         = fread(HDR.FILE.FID,10,'int16');    % 1588
    HDR.ABF.Unavailable1608      = fread(HDR.FILE.FID,4,'uint8');      % 1608
    HDR.ABF.Unused1612           = fread(HDR.FILE.FID,8,'uint8');      % 8char % 1612
    %-----------------------------------------------------------------------------
    % DAC Output File
    HDR.ABF.x_DACFileScale       = fread(HDR.FILE.FID,1,'float');     % 1620
    HDR.ABF.x_DACFileOffset      = fread(HDR.FILE.FID,1,'float');     % 1624
    HDR.ABF.Unused1628           = fread(HDR.FILE.FID,2,'uint8');      % 2char % 1628
    HDR.ABF.x_DACFileEpisodeNum  = fread(HDR.FILE.FID,1,'int16');     % 1630
    HDR.ABF.x_DACFileADCNum      = fread(HDR.FILE.FID,1,'int16');     % 1632
    HDR.ABF.x_DACFileName        = fread(HDR.FILE.FID,12,'uint8');     % 12char % 1634
    HDR.ABF.DACFilePath=fread(HDR.FILE.FID,60,'uint8');                % 60char % 1646
    HDR.ABF.Unused1706=fread(HDR.FILE.FID,12,'uint8');                 % 12char % 1706
    %-----------------------------------------------------------------------------
    % Conditioning Pulse Train
    HDR.ABF.x_ConditEnable       = fread(HDR.FILE.FID,1,'int16');     % 1718
    HDR.ABF.x_ConditChannel      = fread(HDR.FILE.FID,1,'int16');     % 1720
    HDR.ABF.x_ConditNumPulses    = fread(HDR.FILE.FID,1,'int');       % 1722
    HDR.ABF.x_BaselineDuration   = fread(HDR.FILE.FID,1,'float');     % 1726
    HDR.ABF.x_BaselineLevel      = fread(HDR.FILE.FID,1,'float');     % 1730
    HDR.ABF.x_StepDuration       = fread(HDR.FILE.FID,1,'float');     % 1734
    HDR.ABF.x_StepLevel          = fread(HDR.FILE.FID,1,'float');     % 1738
    HDR.ABF.x_PostTrainPeriod    = fread(HDR.FILE.FID,1,'float');     % 1742
    HDR.ABF.x_PostTrainLevel     = fread(HDR.FILE.FID,1,'float');     % 1746
    HDR.ABF.Unused1750           = fread(HDR.FILE.FID,12,'uint8');     % 12char % 1750
    %-----------------------------------------------------------------------------
    % Variable Parameter User List
    HDR.ABF.x_ParamToVary        = fread(HDR.FILE.FID,1,'int16');     % 1762
    HDR.ABF.x_ParamValueList     = fread(HDR.FILE.FID,80,'uint8');     % 80char % 1764
    %-----------------------------------------------------------------------------
    % Statistics Measurement
    HDR.ABF.AutopeakEnable       = fread(HDR.FILE.FID,1,'int16'); % 1844
    HDR.ABF.AutopeakPolarity     = fread(HDR.FILE.FID,1,'int16'); % 1846
    HDR.ABF.AutopeakADCNum       = fread(HDR.FILE.FID,1,'int16'); % 1848
    HDR.ABF.AutopeakSearchMode   = fread(HDR.FILE.FID,1,'int16'); % 1850
    HDR.ABF.AutopeakStart        = fread(HDR.FILE.FID,1,'int');   % 1852
    HDR.ABF.AutopeakEnd          = fread(HDR.FILE.FID,1,'int');   % 1856
    HDR.ABF.AutopeakSmoothing    = fread(HDR.FILE.FID,1,'int16'); % 1860
    HDR.ABF.AutopeakBaseline     = fread(HDR.FILE.FID,1,'int16'); % 1862
    HDR.ABF.AutopeakAverage      = fread(HDR.FILE.FID,1,'int16'); % 1864
    HDR.ABF.Unavailable1866      = fread(HDR.FILE.FID,2,'uint8');  % 1866
    HDR.ABF.AutopeakBaselineStart= fread(HDR.FILE.FID,1,'int');   % 1868
    HDR.ABF.AutopeakBaselineEnd  = fread(HDR.FILE.FID,1,'int');   % 1872
    HDR.ABF.AutopeakMeasurements = fread(HDR.FILE.FID,1,'int');   % 1876
    %-----------------------------------------------------------------------------
    % Channel Arithmetic
    HDR.ABF.ArithmeticEnable     = fread(HDR.FILE.FID,1,'int16'); % 1880
    HDR.ABF.ArithmeticUpperLimit = fread(HDR.FILE.FID,1,'float'); % 1882
    HDR.ABF.ArithmeticLowerLimit = fread(HDR.FILE.FID,1,'float'); % 1886
    HDR.ABF.ArithmeticADCNumA    = fread(HDR.FILE.FID,1,'int16'); % 1890
    HDR.ABF.ArithmeticADCNumB    = fread(HDR.FILE.FID,1,'int16'); % 1892
    HDR.ABF.ArithmeticK1         = fread(HDR.FILE.FID,1,'float'); % 1894
    HDR.ABF.ArithmeticK2         = fread(HDR.FILE.FID,1,'float'); % 1898
    HDR.ABF.ArithmeticK3         = fread(HDR.FILE.FID,1,'float'); % 1902
    HDR.ABF.ArithmeticK4         = fread(HDR.FILE.FID,1,'float'); % 1906
    HDR.ABF.ArithmeticOperator   = fread(HDR.FILE.FID,2,'uint8');  % 2char % 1910
    HDR.ABF.ArithmeticUnits      = fread(HDR.FILE.FID,8,'uint8');  % 8char % 1912
    HDR.ABF.ArithmeticK5         = fread(HDR.FILE.FID,1,'float'); % 1920
    HDR.ABF.ArithmeticK6         = fread(HDR.FILE.FID,1,'float'); % 1924
    HDR.ABF.ArithmeticExpression = fread(HDR.FILE.FID,1,'int16'); % 1928
    HDR.ABF.Unused1930           = fread(HDR.FILE.FID,2,'uint8');  % 2char % 1930
    %-----------------------------------------------------------------------------
    % On-line Subtraction
    HDR.ABF.x_PNEnable           = fread(HDR.FILE.FID,1,'int16'); % 1932
    HDR.ABF.PNPosition           = fread(HDR.FILE.FID,1,'int16'); % 1934
    HDR.ABF.x_PNPolarity         = fread(HDR.FILE.FID,1,'int16'); % 1936
    HDR.ABF.PNNumPulses          = fread(HDR.FILE.FID,1,'int16'); % 1938
    HDR.ABF.x_PNADCNum           = fread(HDR.FILE.FID,1,'int16'); % 1940
    HDR.ABF.x_PNHoldingLevel     = fread(HDR.FILE.FID,1,'float'); % 1942
    HDR.ABF.PNSettlingTime       = fread(HDR.FILE.FID,1,'float'); % 1946
    HDR.ABF.PNInterpulse         = fread(HDR.FILE.FID,1,'float'); % 1950
    HDR.ABF.Unused1954           = fread(HDR.FILE.FID,12,'uint8'); % 12char % 1954
    %-----------------------------------------------------------------------------
    % Unused Space at End of Header Block
    HDR.ABF.x_ListEnable         = fread(HDR.FILE.FID,1,'int16'); % 1966
    HDR.ABF.BellEnable           = fread(HDR.FILE.FID,2,'int16'); % 1968
    HDR.ABF.BellLocation         = fread(HDR.FILE.FID,2,'int16'); % 1972
    HDR.ABF.BellRepetitions      = fread(HDR.FILE.FID,2,'int16'); % 1976
    HDR.ABF.LevelHysteresis      = fread(HDR.FILE.FID,1,'int');   % 1980
    HDR.ABF.TimeHysteresis       = fread(HDR.FILE.FID,1,'int');   % 1982
    HDR.ABF.AllowExternalTags    = fread(HDR.FILE.FID,1,'int16'); % 1986
    HDR.ABF.LowpassFilterType    = fread(HDR.FILE.FID,16,'uint8'); % 1988
    HDR.ABF.HighpassFilterType   = fread(HDR.FILE.FID,16,'uint8');% 2004
    HDR.ABF.AverageAlgorithm     = fread(HDR.FILE.FID,1,'int16'); % 2020
    HDR.ABF.AverageWeighting     = fread(HDR.FILE.FID,1,'float'); % 2022
    HDR.ABF.UndoPromptStrategy   = fread(HDR.FILE.FID,1,'int16'); % 2026
    HDR.ABF.TrialTriggerSource   = fread(HDR.FILE.FID,1,'int16'); % 2028
    HDR.ABF.StatisticsDisplayStrategy= fread(HDR.FILE.FID,1,'int16'); % 2030
    HDR.ABF.Unused2032           = fread(HDR.FILE.FID,16,'uint8'); % 2032
    
    %-----------------------------------------------------------------------------
    % File Structure 2
    HDR.ABF.DACFilePtr           = fread(HDR.FILE.FID,2,'int'); % 2048
    HDR.ABF.DACFileNumEpisodes   = fread(HDR.FILE.FID,2,'int'); % 2056
    HDR.ABF.Unused2              = fread(HDR.FILE.FID,10,'uint8');%2064
    %-----------------------------------------------------------------------------
    % Multi-channel Information 2
    HDR.ABF.DACCalibrationFactor = fread(HDR.FILE.FID,4,'float'); % 2074
    HDR.ABF.DACCalibrationOffset = fread(HDR.FILE.FID,4,'float'); % 2090
    HDR.ABF.Unused7              = fread(HDR.FILE.FID,190,'uint8');% 2106
    %-----------------------------------------------------------------------------
    % Epoch Waveform and Pulses 2
    HDR.ABF.WaveformEnable       = fread(HDR.FILE.FID,2,'int16'); % 2296
    HDR.ABF.WaveformSource       = fread(HDR.FILE.FID,2,'int16'); % 2300
    HDR.ABF.InterEpisodeLevel    = fread(HDR.FILE.FID,2,'int16'); % 2304
    HDR.ABF.EpochType            = fread(HDR.FILE.FID,10*2,'int16');% 2308
    HDR.ABF.EpochInitLevel       = fread(HDR.FILE.FID,10*2,'float');% 2348
    HDR.ABF.EpochLevelInc        = fread(HDR.FILE.FID,10*2,'float');% 2428
    HDR.ABF.EpochInitDuration    = fread(HDR.FILE.FID,10*2,'int');  % 2508
    HDR.ABF.EpochDurationInc     = fread(HDR.FILE.FID,10*2,'int');  % 2588
    HDR.ABF.Unused9              = fread(HDR.FILE.FID,40,'uint8');   % 2668
    %-----------------------------------------------------------------------------
    % DAC Output File 2
    HDR.ABF.DACFileScale         = fread(HDR.FILE.FID,2,'float');     % 2708
    HDR.ABF.DACFileOffset        = fread(HDR.FILE.FID,2,'float');     % 2716
    HDR.ABF.DACFileEpisodeNum    = fread(HDR.FILE.FID,2,'int');       % 2724
    HDR.ABF.DACFileADCNum        = fread(HDR.FILE.FID,2,'int16');     % 2732
    HDR.ABF.DACFilePath          = fread(HDR.FILE.FID,2*256,'uint8');  % 2736
    HDR.ABF.Unused10             = fread(HDR.FILE.FID,12,'uint8');     % 3248
    %-----------------------------------------------------------------------------
    % Conditioning Pulse Train 2
    HDR.ABF.ConditEnable         = fread(HDR.FILE.FID,2,'int16');     % 3260
    HDR.ABF.ConditNumPulses      = fread(HDR.FILE.FID,2,'int');       % 3264
    HDR.ABF.BaselineDuration     = fread(HDR.FILE.FID,2,'float');     % 3272
    HDR.ABF.BaselineLevel        = fread(HDR.FILE.FID,2,'float');     % 3280
    HDR.ABF.StepDuration         = fread(HDR.FILE.FID,2,'float');     % 3288
    HDR.ABF.StepLevel            = fread(HDR.FILE.FID,2,'float');     % 3296
    HDR.ABF.PostTrainPeriod      = fread(HDR.FILE.FID,2,'float');     % 3304
    HDR.ABF.PostTrainLevel       = fread(HDR.FILE.FID,2,'float');     % 3312
    HDR.ABF.Unused11             = fread(HDR.FILE.FID,2,'int16');     % 3320
    HDR.ABF.Unused11             = fread(HDR.FILE.FID,36,'uint8');     % 3324
    %-----------------------------------------------------------------------------
    % Variable Parameter User List 2
    HDR.ABF.ULEnable             = fread(HDR.FILE.FID,4,'int16');     % 3360
    HDR.ABF.ULParamToVary        = fread(HDR.FILE.FID,4,'int16');     % 3368
    HDR.ABF.ULParamValueList     = fread(HDR.FILE.FID,4*256,'uint8');  % 3376
    HDR.ABF.Unused11             = fread(HDR.FILE.FID,56,'uint8');     % 4400
    %-----------------------------------------------------------------------------
    % On-line Subtraction 2
    HDR.ABF.PNEnable             = fread(HDR.FILE.FID,2,'int16');     % 4456
    HDR.ABF.PNPolarity           = fread(HDR.FILE.FID,2,'int16');     % 4460
    HDR.ABF.PNADCNum             = fread(HDR.FILE.FID,2,'int16');     % 4464
    HDR.ABF.PNHoldingLevel       = fread(HDR.FILE.FID,2,'float');     % 4468
    HDR.ABF.Unused15             = fread(HDR.FILE.FID,36,'uint8');     % 4476
    %-----------------------------------------------------------------------------
    % Environmental Information 2
    HDR.ABF.TelegraphEnable      = fread(HDR.FILE.FID,16,'int16');     % 4512
    HDR.ABF.TelegraphInstrument  = fread(HDR.FILE.FID,16,'int16');     % 4544
    HDR.ABF.TelegraphAdditGain   = fread(HDR.FILE.FID,16,'float');     % 4576
    HDR.ABF.TelegraphFilter      = fread(HDR.FILE.FID,16,'float');     % 4640
    HDR.ABF.TelegraphMembraneCap = fread(HDR.FILE.FID,16,'float');     % 4704
    HDR.ABF.TelegraphMode        = fread(HDR.FILE.FID,16,'int16');     % 4768
    HDR.ABF.ManualTelegraphStrategy= fread(HDR.FILE.FID,16,'int16');   % 4800
    HDR.ABF.AutoAnalyseEnable    = fread(HDR.FILE.FID,1,'int16');      % 4832
    HDR.ABF.AutoAnalysisMacroName= fread(HDR.FILE.FID,64,'uint8');      % 4834
    HDR.ABF.ProtocolPath         = fread(HDR.FILE.FID,256,'uint8');     % 4898
    HDR.ABF.FileComment          = fread(HDR.FILE.FID,128,'uint8');     % 5154
    HDR.ABF.Unused6              = fread(HDR.FILE.FID,128,'uint8');     % 5282
    HDR.ABF.Unused2048           = fread(HDR.FILE.FID,734,'uint8');     % 5410
    %
    %-----------------------------------------------------------------------------
    %
    
    HDR.Cal = (HDR.ABF.ADCRange / (HDR.ABF.ADCResolution * HDR.ABF.x_AutosampleAdditGain))./ (HDR.ABF.InstrumentScaleFactor .* HDR.ABF.ADCProgrammableGain .* HDR.ABF.SignalGain);
    
    HDR.Calib = sparse([HDR.Off(1:HDR.NS)'; diag(HDR.Cal(1:HDR.NS))]);
    
    status = fseek(HDR.FILE.FID,HDR.HeadLen,'bof');
    HDR.FILE.POS = 0;
    %HDR.FILE.OPEN = 1;
    
    HDR.data = fread(HDR.FILE.FID,[HDR.NS,HDR.NRec*HDR.SPR],gdfdatatype(HDR.GDFTYP))';
    HDR.TYPE = 'native';
    fclose(HDR.FILE.FID);
  end
  