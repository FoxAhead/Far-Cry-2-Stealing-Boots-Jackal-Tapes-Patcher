unit UnitFormMain;

interface

uses
  Classes,
  Controls,
  Dialogs,
  Forms,
  ShellAPI,
  StdCtrls,
  SysUtils,
  Types,
  Unit2,
  Registry,
  Windows;

type
  TForm_Main = class(TForm)
    ButtonPatch: TButton;
    EditFileName: TEdit;
    ButtonBrowse: TButton;
    OpenDialog1: TOpenDialog;
    Memo1: TMemo;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    LabelVersion: TLabel;
    LabelDebug: TLabel;
    procedure ButtonBrowseClick(Sender: TObject);
    procedure ButtonPatchClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure OpenGitHubLink(Sender: TObject);
    procedure LabelVersionClick(Sender: TObject);
  private
    { Private declarations }
    function CheckFile(FileName: string): Boolean;
    function PatchFile(FileName: string): Boolean;
    function IsReadyToPatch: Boolean;
    function SearchForPatterns(var FileBuffer: TByteDynArray): TSearchInfoDynArray;
    function BackupFile(FileName: string): string;
    function GetInstallLocation(InstallSearch: TInstallSearch): string;
    procedure SetInitialDir(OpenDialog: TOpenDialog);
    procedure SetReadyToPatch(ready: Boolean);
    procedure LoadFromFile(FileName: string; var FileBuffer: TByteDynArray);
    procedure LoadFromResource(ResourceName: TResourceName; var ResourceBuffer: TResourceBuffer);
    procedure LoadBufferFromResource(ResourceName: string; var Buffer: TByteDynArray);
    procedure Log(Text: string = ''); overload;
    procedure Log(Level: Integer; Text: string); overload;
    procedure GetCallOffsets(var MaskBuffer: TByteDynArray; var CallOffsets: TCallOffsets);
    procedure SetCallAddresses(var ResourceBuffer: TResourceBuffer; var CallAddresses: TCallAddresses);
  public
    { Public declarations }
  end;

var
  Form_Main: TForm_Main;

implementation

{$R *.dfm}

procedure TForm_Main.ButtonBrowseClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    EditFileName.Text := OpenDialog1.FileName;
    Log;
    SetReadyToPatch(CheckFile(EditFileName.Text));
    if IsReadyToPatch() then
    begin
      Log('READY TO PATCH!');
      Log('You can click ''Patch!'' now (backup file will be created).')
    end
    else
    begin
      Log('CAN NOT PATCH!');
    end;
  end;
end;

function TForm_Main.CheckFile(FileName: string): Boolean;
var
  FileBuffer: TByteDynArray;
  SearchInfo: TSearchInfoDynArray;
begin
  Result := False;
  Log(1, 'Analyzing file ' + FileName + '...');
  try
    LoadFromFile(FileName, FileBuffer);
    SearchInfo := SearchForPatterns(FileBuffer);

    if Length(SearchInfo) = 0 then
      Log('No patterns found.')
    else if Length(SearchInfo) > 1 then
      Log('Wrong file. Too much patterns found.')
    else
    begin
      case SearchInfo[0].PatternVersion of
        pvGame100:
          Log('Game version 1.00-1.02 detected. No need for patching.');
        pvGame103:
          Result := True;
        pvPatch103:
          Log('This file is already patched.');
      end;
    end;
  except
    on E: EStreamError do
    begin
      Log('File read error!');
      Log(E.Message);
    end;
    on E: EResNotFound do
    begin
      Log('Resource read error!');
      Log(E.Message);
    end;
    on E: EAccessViolation do
    begin
      Log(E.Message);
    end;
  end;
  Log(1, 'Analyzing done.');
end;

function TForm_Main.IsReadyToPatch: Boolean;
begin
  Result := ButtonPatch.Enabled;
end;

procedure TForm_Main.LoadFromFile(FileName: string; var FileBuffer: TByteDynArray);
var
  FileStream: TFileStream;
  BytesRead: Integer;
begin
  FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  Log(2, 'Allocating ' + IntToStr(FileStream.Size) + ' bytes...');
  SetLength(FileBuffer, FileStream.Size);
  Log(2, 'Allocated.');
  Log(2, 'Reading...');
  BytesRead := FileStream.Read(Pointer(FileBuffer)^, FileStream.Size);
  FileStream.Free;
  Log(2, 'Reading of ' + IntToStr(BytesRead) + ' bytes done.');
end;

procedure TForm_Main.LoadFromResource(ResourceName: TResourceName; var ResourceBuffer: TResourceBuffer);
begin
  LoadBufferFromResource(ResourceName.Pattern, ResourceBuffer.Pattern);
  LoadBufferFromResource(ResourceName.Mask, ResourceBuffer.Mask);
end;

procedure TForm_Main.LoadBufferFromResource(ResourceName: string; var Buffer: TByteDynArray);
var
  ResourceStream: TResourceStream;
  BytesRead: Integer;
begin
  ResourceStream := TResourceStream.Create(HInstance, ResourceName, RT_RCDATA);
  Log(2, 'Allocating ' + IntToStr(ResourceStream.Size) + ' bytes...');
  SetLength(Buffer, ResourceStream.Size);
  Log(2, 'Allocated.');
  Log(2, 'Reading...');
  BytesRead := ResourceStream.Read(Pointer(Buffer)^, ResourceStream.Size);
  ResourceStream.Free;
  Log(2, 'Reading of ' + IntToStr(BytesRead) + ' bytes done.');
end;

procedure TForm_Main.Log(Text: string);
begin
  Log(0, Text);
end;

procedure TForm_Main.Log(Level: Integer; Text: string);
begin
  if Text = '' then
    Memo1.Lines.Clear()
  else if Level <= DEBUG_LEVEL then
    Memo1.Lines.Append(Text);
end;

procedure TForm_Main.SetReadyToPatch(ready: Boolean);
begin
  ButtonPatch.Enabled := ready;
end;

procedure TForm_Main.ButtonPatchClick(Sender: TObject);
begin
  if MessageDlg('Apply patch?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    SetReadyToPatch(False);
    if PatchFile(EditFileName.Text) then
      Log('Patching succeed.')
    else
      Log('Patching failed.');
  end
  else
  begin
    Log('Patching canceled.');
  end;
end;

procedure TForm_Main.FormCreate(Sender: TObject);
begin
  if FindCmdLineSwitch('debug') then
    DEBUG_LEVEL := 2;
  LabelVersion.Caption := 'Version ' + Tlib.CurrentFileInfo(Application.ExeName);
  SetInitialDir(OpenDialog1);
end;

function TForm_Main.PatchFile(FileName: string): Boolean;
var
  FileBuffer: TByteDynArray;
  ResourceBuffer: TResourceBuffer;
  SearchInfo: TSearchInfoDynArray;
  FileStream: TFileStream;
  BytesRead: Integer;
begin
  Result := False;
  try
    FileStream := TFileStream.Create(FileName, fmOpenReadWrite or fmShareDenyWrite);
    Log(2, 'Allocating ' + IntToStr(FileStream.Size) + ' bytes...');
    SetLength(FileBuffer, FileStream.Size);
    Log(2, 'Allocated.');
    Log(2, 'Reading...');
    BytesRead := FileStream.Read(Pointer(FileBuffer)^, FileStream.Size);
    Log(2, 'Reading of ' + IntToStr(BytesRead) + ' bytes done.');
    SearchInfo := SearchForPatterns(FileBuffer);
    if Length(SearchInfo) = 1 then
    begin
      if (SearchInfo[0].PatternVersion <> pvPatch103) then
      begin
        LoadFromResource(ResourceNames[pvPatch103], ResourceBuffer);
        SetCallAddresses(ResourceBuffer, SearchInfo[0].CallAddresses);

        FileStream.Seek(SearchInfo[0].FileOffset, soFromBeginning);
        Log('Created backup file ''' + BackupFile(FileName) + '''');
        Log('Patching...');
        Log(2, 'Writing...');
        FileStream.Write(Pointer(ResourceBuffer.Pattern)^, Length(ResourceBuffer.Pattern));
        Log(2, 'Writing of ' + IntToStr(BytesRead) + ' bytes done.');
        FileStream.Free;
        Result := True;
      end;
    end;
  except
    on E: Exception do
      Log('Error: ' + E.Message);
  end;
end;

function TForm_Main.BackupFile(FileName: string): string;
var
  BackupFileName: string;
  FileNumber: Integer;
begin
  Result := '';
  BackupFileName := FileName + '.bakFA';
  FileNumber := 1;
  while FileExists(BackupFileName) do
  begin
    Inc(FileNumber);
    BackupFileName := FileName + '.bakFA(' + IntToStr(FileNumber) + ')';
    if FileNumber > 1000 then
      raise Exception.Create('Failed creating backup file');
  end;
  if CopyFile(PAnsiChar(FileName), PAnsiChar(BackupFileName), True) then
    Result := BackupFileName
  else
    raise Exception.Create('Failed creating backup file');
end;

procedure TForm_Main.OpenGitHubLink(Sender: TObject);
begin
  ShellExecute(Application.Handle, 'open', 'https://github.com/FoxAhead/Far-Cry-2-Stealing-Boots-Jackal-Tapes-Patcher',
    nil, nil, SW_SHOW);
end;

function TForm_Main.SearchForPatterns(var FileBuffer: TByteDynArray): TSearchInfoDynArray;
var
  ResourceBuffer: TResourceBuffer;
  CallOffsets: TCallOffsets;
  FileSize: Integer;
  PatternSize: Integer;
  p: TPatternVersion;
  i, j, k: Integer;
begin
  Result := nil;
  k := -1;
  Log(1, 'Searching...');
  FileSize := Length(FileBuffer);
  for p := Low(ResourceNames) to High(ResourceNames) do
  begin
    Log(1, 'Searching pattern ' + ResourceNames[p].Pattern + '...');
    LoadFromResource(ResourceNames[p], ResourceBuffer);
    GetCallOffsets(ResourceBuffer.Mask, CallOffsets);
    PatternSize := Length(ResourceBuffer.Pattern);
    for i := 0 to FileSize - PatternSize do
    begin
      j := 0;
      while ((FileBuffer[i + j] = ResourceBuffer.Pattern[j]) or (ResourceBuffer.Mask[j] > 0)) and (j < PatternSize) do
        Inc(j);
      if j = PatternSize then             //FOUND
      begin
        k := k + 1;
        SetLength(Result, k + 1);
        Result[k].PatternVersion := p;
        Result[k].FileOffset := i;
        Log(1, 'FOUND pattern at #' + IntToHex(i, 4) + '!');
        SetLength(Result[k].CallAddresses, Length(CallOffsets));
        for j := Low(CallOffsets) to High(CallOffsets) do
        begin
          if CallOffsets[j].AddressID > High(Result[k].CallAddresses) then
          begin
            SetLength(Result[k].CallAddresses, CallOffsets[j].AddressID + 1);
          end;
          Result[k].CallAddresses[CallOffsets[j].AddressID] := PInteger(@FileBuffer[i + CallOffsets[j].Offset])^;
        end;
      end;
    end;
  end;
  Log(1, 'Searching done.');

end;

procedure TForm_Main.GetCallOffsets(var MaskBuffer: TByteDynArray; var CallOffsets: TCallOffsets);
var
  i: Integer;
  AddressID: Byte;
begin
  CallOffsets := nil;
  i := Low(MaskBuffer);
  while i < High(MaskBuffer) do
  begin
    AddressID := MaskBuffer[i];
    if AddressID <> $00 then
    begin
      SetLength(CallOffsets, Length(CallOffsets) + 1);
      CallOffsets[High(CallOffsets)].Offset := i;
      CallOffsets[High(CallOffsets)].AddressID := AddressID - 1;
      i := i + 4;
    end
    else
    begin
      i := i + 1;
    end;
  end;
end;

procedure TForm_Main.SetCallAddresses(var ResourceBuffer: TResourceBuffer; var CallAddresses: TCallAddresses);
var
  i: Integer;
  CallOffsets: TCallOffsets;
  Offset: Integer;
begin
  GetCallOffsets(ResourceBuffer.Mask, CallOffsets);
  for i := Low(CallOffsets) to High(CallOffsets) do
  begin
    Offset := CallOffsets[i].Offset;
    if (Offset >= Low(ResourceBuffer.Pattern)) and (Offset <= High(ResourceBuffer.Pattern)) then
    begin
      PInteger(@ResourceBuffer.Pattern[Offset])^ := CallAddresses[CallOffsets[i].AddressID];
    end
    else
    begin
      raise Exception.Create('Procedure call address not found');
    end;
  end;
end;

procedure TForm_Main.LabelVersionClick(Sender: TObject);
begin
  if DEBUG_LEVEL = 0 then
  begin
    DEBUG_LEVEL := 2;
    LabelVersion.Enabled := True;
  end
  else
  begin
    DEBUG_LEVEL := 0;
    LabelVersion.Enabled := False;
  end;
  Log('DEBUG_LEVEL set to ' + IntToStr(DEBUG_LEVEL));
end;

procedure TForm_Main.SetInitialDir(OpenDialog: TOpenDialog);
var
  i: Integer;
  Path: string;
begin
  for i := Low(InstallSearchs) to High(InstallSearchs) do
  begin
    Path := GetInstallLocation(InstallSearchs[i]);
    if Path <> '' then
    begin
      OpenDialog.InitialDir := Path;
      Break;
    end;
  end;
end;

function TForm_Main.GetInstallLocation(InstallSearch: TInstallSearch): string;
var
  Registry: TRegistry;
  Path: string;
begin
  Result := '';
  Registry := TRegistry.Create(KEY_READ);
  Registry.RootKey := HKEY_LOCAL_MACHINE;
  try
    if Registry.OpenKey(InstallSearch.RKey, False) then
    begin
      Path := Registry.ReadString(InstallSearch.RValue);
      if Path <> '' then
      begin
        Path := Path + '\' + InstallSearch.Path;
        if DirectoryExists(Path) then
        begin
          Result := Path;
        end;
      end;
    end;
  finally
    Registry.Free;
  end;
end;

end.
