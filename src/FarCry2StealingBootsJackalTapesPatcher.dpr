program FarCry2StealingBootsJackalTapesPatcher;

{$R 'patterns.res' 'patterns.rc'}

uses
  Forms,
  UnitFormMain in 'UnitFormMain.pas' {Form_Main},
  Unit2 in 'Unit2.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Far Cry 2 Stealing Boots Jackal Tapes Patcher';
  Application.CreateForm(TForm_Main, Form_Main);
  //Application.CreateForm(TFormInfo, FormInfo);
  Application.Run;
end.
