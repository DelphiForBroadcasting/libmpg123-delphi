program Project1;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.TypInfo,
  fmt123 in '..\..\Include\fmt123.pas',
  libmpg123 in '..\..\Include\libmpg123.pas';

const
  INPUT_BUFF_SIZE = 16384 * 2 * 2;
  OUT_BUFF_SIZE = 32768;


var
  lSourceFile       : string;
  lDumpFile         : string;
  lSourceStream     : TFileStream;
  lDumpStream       : TFileStream;
  lInputBuff        : PByte;
  lOutputBuff       : PByte;
  lReadBytes        : Cardinal;
  lOutputBytes      : Cardinal;

  lErrorCode        : integer;
  lHandle           : pMpg123_handle;

  lRate             : LongInt;
  lChannels         : integer;
  lEnc              : integer;
begin
  try

    ReportMemoryLeaksOnShutdown := true;

    if not FindCmdLineSwitch('i', lSourceFile, True) then
    begin
      writeln(format('Usage: %s -i [MP2_FILE] -dump [RAW_PCM_DATA]', [System.IOUtils.TPath.GetFileName(ParamStr(0))]));
      exit;
    end;
    lSourceFile := TPath.GetFullPath(TPath.Combine(System.IOUtils.TPath.GetDirectoryName(ParamStr(0)), lSourceFile));

    if not FindCmdLineSwitch('dump', lDumpFile, True) then
    begin
      writeln(format('Usage: %s -i [MP2_FILE] -dump [RAW_PCM_DATA]', [System.IOUtils.TPath.GetFileName(ParamStr(0))]));
      exit;
    end;
    lDumpFile := TPath.GetFullPath(TPath.Combine(System.IOUtils.TPath.GetDirectoryName(ParamStr(0)), lDumpFile));

    lErrorCode := mpg123_init();
    if lErrorCode <> Integer(MPG123_OK) then
      WriteLn(mpg123_plain_strerror(lErrorCode));

    lHandle := mpg123_new(nil, lErrorCode);
    if lErrorCode <> Integer(MPG123_OK) then
      WriteLn(Format('Unable to create mpg123 handle: %s', [mpg123_plain_strerror(lErrorCode)]));

    lErrorCode := mpg123_param(lHandle, TMpg123_parms.MPG123_VERBOSE, 2, 0);
    if lErrorCode <> Integer(MPG123_OK) then
      WriteLn(mpg123_plain_strerror(lErrorCode));

    (* Now mpg123 is being prepared for feeding. The main loop will read chunks from stdin and feed them to mpg123;
       then take decoded data as available to write to stdout. *)
	  lErrorCode := mpg123_open_feed(lHandle);
    if lErrorCode <> Integer(MPG123_OK) then
      WriteLn(Format('Unable open feed: %s', [mpg123_plain_strerror(lErrorCode)]));

    GetMem(lInputBuff, INPUT_BUFF_SIZE);
    GetMem(lOutputBuff, OUT_BUFF_SIZE);
    try
      writeLn(Format('* Start Decode MP2 file: %s', [lSourceFile]));
      lDumpStream := TFileStream.Create(lDumpFile, System.Classes.fmCreate);
      try
        lSourceStream := TFileStream.Create(lSourceFile, fmOpenRead);
        try
          while lSourceStream.Position < (lSourceStream.Size) do
          begin
            // progress
            write('*');
            lReadBytes:= lSourceStream.ReadData(lInputBuff, INPUT_BUFF_SIZE);

            (* Feed input chunk and get first chunk of decoded audio. *)
            lErrorCode := mpg123_decode(lHandle, lInputBuff, lReadBytes, lOutputBuff, OUT_BUFF_SIZE, lOutputBytes);
            if(lErrorCode = Integer(MPG123_NEW_FORMAT)) then
            begin
                mpg123_getformat(lHandle, lRate, lChannels, lEnc);
                writeLn(Format('New format: %d Hz, %d channels, encoding value %d', [lRate, lChannels, lEnc]));
            end;
            lDumpStream.WriteBuffer(lOutputBuff^, lOutputBytes);

            while ((lErrorCode <> Integer(MPG123_ERR)) and (lErrorCode <> Integer(MPG123_NEED_MORE))) do
            begin
              lErrorCode := mpg123_decode(lHandle, nil, 0, lOutputBuff, OUT_BUFF_SIZE, lOutputBytes);
              lDumpStream.WriteBuffer(lOutputBuff^, lOutputBytes);
            end;

            if (lErrorCode = Integer(MPG123_ERR)) then
            begin
              writeLn(Format('Error: %s', [mpg123_strerror(lHandle)]));
              break;
            end;
          end;
        finally
          FreeAndNil(lSourceStream);
        end;
      finally
        FreeAndNil(lDumpStream);
      end;
    finally
      FreeMem(lInputBuff);
      FreeMem(lOutputBuff);
    end;

    mpg123_delete(lHandle);
  	mpg123_exit();

    writeLn('');
    writeLn(Format('* Finish Decode MP2 file. %s', [lDumpFile]));


  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

  writeLn;
  write('Press Enter to exit...');
  readln;

end.
