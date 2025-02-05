program StartX;

uses
  Forms,
  windows,
  core in 'core\core.pas',
  event in 'core\event.pas',
  u_json in 'core\u_json.pas',

  PopupMenuManager in 'core\PopupMenuManager.pas',
  ApplicationMain in 'src\ApplicationMain.pas' {Form1},
  ConfigurationForm in 'src\ConfigurationForm.pas' {CfgForm},
  InfoBarForm in 'src\InfoBarForm.pas' {bottomForm},
  plug in 'core\plug.pas',
  utils in 'core\utils.pas',
  TaskbarList in 'core\TaskbarList.pas';

//  u_debug in 'core\u_debug.pas';

{$R *.res}

begin


  Application.Initialize;
  Application.MainFormOnTaskbar := true;

  Application.CreateForm(TForm1, Form1);
  Application.Run;




end.
