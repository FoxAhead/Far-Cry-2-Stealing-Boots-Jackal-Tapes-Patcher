unit Unit2;

interface

uses
  Types;
type
  TLib = class
  public
    class function CurrentFileInfo(NameApp: string): string;
  end;

var
  DEBUG_LEVEL: Integer = 0;

type
  TSearchDirection = (sdDown, sdUp);

  TCallOffset = record
    Offset: Integer;
    AddressID: Integer;
  end;

  TCallOffsets = array of TCallOffset;

  TCallAddresses = TIntegerDynArray;

  TResourceBuffer = record
    Pattern: TByteDynArray;
    Mask: TByteDynArray;
  end;

  TPatternVersion = (pvGame100, pvGame103, pvPatch103);
  TSearchInfo = record
    PatternVersion: TPatternVersion;
    FileOffset: Integer;
    CallAddresses: TCallAddresses;
  end;

  TSearchInfoDynArray = array of TSearchInfo;

  TResourceName = record
    Pattern: string;
    Mask: string;
  end;

  TResourceNameArray = array[TPatternVersion] of TResourceName;

  TInstallSearch = record
    RKey: string;
    RValue: string;
    Path: string;
  end;
  TInstallSearchs = array[0..5] of TInstallSearch;
const
  ResourceNames: TResourceNameArray = (
    (Pattern: 'Game100'; Mask: 'Game100102Mask'),
    (Pattern: 'Game103'; Mask: 'Game103Mask'),
    (Pattern: 'Patch103'; Mask: 'Game103Mask')
    );
  InstallSearchs: TInstallSearchs = ((
    RKey: '\SOFTWARE\Ubisoft\Far Cry 2';
    RValue: 'InstallDir';
    Path: 'bin';
    ), (
    RKey: '\SOFTWARE\Wow6432Node\Ubisoft\Far Cry 2';
    RValue: 'InstallDir';
    Path: 'bin';
    ), (
    RKey: '\SOFTWARE\Valve\Steam';
    RValue: 'InstallPath';
    Path: 'steamapps\common\far cry 2\bin';
    ), (
    RKey: '\SOFTWARE\Wow6432Node\Valve\Steam';
    RValue: 'InstallPath';
    Path: 'steamapps\common\far cry 2\bin';
    ), (
    RKey: '\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 19900';
    RValue: 'InstallDir';
    Path: 'bin';
    ), (
    RKey: '\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 19900';
    RValue: 'InstallDir';
    Path: 'bin';
    ));

implementation

uses
  Windows,
  SysUtils;

class function TLib.CurrentFileInfo(NameApp: string): string;
var
  dump: DWORD;
  size: Integer;
  buffer: PChar;
  VersionPointer, TransBuffer: PChar;
  Temp: Integer;
  CalcLangCharSet: string;
begin
  size := GetFileVersionInfoSize(PChar(NameApp), dump);
  buffer := StrAlloc(size + 1);
  try
    GetFileVersionInfo(PChar(NameApp), 0, size, buffer);

    VerQueryValue(buffer, '\VarFileInfo\Translation', pointer(TransBuffer), dump);
    if dump >= 4 then
    begin
      Temp := 0;
      StrLCopy(@Temp, TransBuffer, 2);
      CalcLangCharSet := IntToHex(Temp, 4);
      StrLCopy(@Temp, TransBuffer + 2, 2);
      CalcLangCharSet := CalcLangCharSet + IntToHex(Temp, 4);
    end;

    VerQueryValue(buffer, PChar('\StringFileInfo\' + CalcLangCharSet + '\' + 'FileVersion'), pointer(VersionPointer), dump);
    if (dump > 1) then
    begin
      SetLength(Result, dump);
      StrLCopy(PChar(Result), VersionPointer, dump);
    end
    else
      Result := '0.0.0.0';
  finally
    StrDispose(buffer);
  end;
end;

end.
