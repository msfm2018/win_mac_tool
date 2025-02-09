unit InfoBarForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Winapi.ShellAPI, Vcl.ComCtrls, ActiveX, shlobj, u_json, ImgPanel,
  System.Generics.Collections, ImgButton, System.JSON, comobj, Vcl.ImgList,
  Vcl.Menus, System.ImageList, utils, Vcl.StdCtrls;

type
  TActionMap = TDictionary<string, TProc>;

type
  TbottomForm = class(TForm)
    procedure FormShow(Sender: TObject);

    procedure LVexeinfoMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure wndproc(var Msg: tmessage); override;
  private
    into_snap_windows: Boolean;
    ScaleFactor: double;
    procedure snap_top_windows;

    procedure show_aapp(Path, FileName, f1, f2: string);
    procedure PanelDblClick(Sender: TObject);

  end;

var
  bottomForm: TbottomForm;
  closebtn: TImgButton;
  resetbtn: TImgButton;
  oldcolor: tcolor;

var
  ActionMap: TActionMap;

var
  pnls: TList<TImgPanel>;

implementation

{$R *.dfm}

uses
  core, ConfigurationForm;

procedure sort_layout(hwnd: hwnd; uMsg, idEvent: UINT; dwTime: DWORD); stdcall;
begin
  bottomForm.snap_top_windows();
end;

procedure TbottomForm.snap_top_windows();
var
  lp: tpoint;
begin
  if g_core.nodes.is_configuring then
    exit;

  SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);

  GetCursorPos(lp);
  if not PtInRect(self.BoundsRect, lp) and not into_snap_windows then
  begin
    into_snap_windows := true;

    if g_core.json.Config.layout = 'left' then
    begin
      bottomForm.Left := -bottomForm.Width + 4;
    end
    else
    begin

      if left < Screen.WorkAreaWidth - bottomForm.Width then
      begin
        top := 0;
        Left := Screen.WorkAreaWidth - bottomForm.Width + 40;

      end;
    end;

    into_snap_windows := false;

  end
  else if g_core.json.Config.layout = 'left' then
  begin
    bottomForm.Left := 0;
  end
  else
    Left := Screen.WorkAreaWidth - bottomForm.Width;

end;
   procedure TbottomForm.wndproc(var Msg: TMessage);
var
  DpiX, DpiY: UINT;
begin
  case Msg.Msg of
    WM_DPICHANGED:
      begin
        DpiX := LOWORD(Msg.WParam);
        DpiY := HIWORD(Msg.WParam);
        ScaleFactor := DpiX / 96.0;

        Height := 6;
        for var Panel in pnls do
          Height := Height + Round(Panel.Height * ScaleFactor);

        Top := (Screen.WorkAreaHeight - Height) div 2;
      end;
  else
    inherited;
  end;
end;

procedure TbottomForm.show_aapp(Path, FileName, f1, f2: string);
var
  Panel: TImgPanel;
  Image: TImgButton;
  i: Integer;
begin
  try
    Panel := TImgPanel.Create(self);
    Panel.Parent := self;
    Panel.Align := alTop;
    Panel.Height := Round(60 * ScaleFactor);
    Panel.BevelOuter := bvNone;
    Panel.ParentColor := False;
    Panel.Color := $00E5E5E5;
    Panel.StyleElements := [seClient];
    Panel.extendA := FileName;
    Panel.extendB := Path;
    oldcolor := Panel.Color;

    Image := TImgButton.Create(Panel);
    Image.Parent := Panel;
    Image.Image.LoadFromFile(f1);
    Image.Image1.LoadFromFile(f2);
    Image.Width := round(46 * ScaleFactor);
    Image.Height := round(46 * ScaleFactor);

    Image.Name := FileName;
    Image.Cursor := crHandPoint;
    Image.Left := (Panel.Width - Image.Width) div 2;
    Image.Top := (Panel.Height - Image.Height) div 2;

    Image.OnClick := PanelDblClick;
    Panel.OnClick := PanelDblClick;

    pnls.Add(Panel);


  finally
  end;
end;

procedure TbottomForm.PanelDblClick(Sender: TObject);
var
  Identifier: string;
begin
  if Sender is TImgButton then
    Identifier := TImgButton(Sender).Name;

  if ActionMap.ContainsKey(Identifier) then
    ActionMap[Identifier]();
end;



procedure TbottomForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  KillTimer(Handle, 10);
end;

procedure TbottomForm.FormShow(Sender: TObject);
var
  MainFormCenter: TPoint;
begin

  ScaleFactor := 1.0;
  SetWindowCornerPreference(Handle);
  width := round(70 * ScaleFactor);
  caption := 'selfdefinestartmenu';

  DoubleBuffered := true;
  into_snap_windows := false;
  KillTimer(Handle, 10);
  SetTimer(Handle, 10, 100, @sort_layout);

  // **动态添加按钮，窗体高度自动计算**
  show_aapp(ExtractFilePath(ParamStr(0)) + '/imgapp/close_hover.png', '关机', ExtractFilePath(ParamStr(0)) + '/imgapp/close.png', ExtractFilePath(ParamStr(0)) + '/imgapp/close_hover.png');
  show_aapp(ExtractFilePath(ParamStr(0)) + '/imgapp/reset_hover.png', '重启', ExtractFilePath(ParamStr(0)) + '/imgapp/reset_hover.png', ExtractFilePath(ParamStr(0)) + '/imgapp/reset.png');
  show_aapp(ExtractFilePath(ParamStr(0)) + '/imgapp/icons8-esc-40.png', '退出', ExtractFilePath(ParamStr(0)) + '/imgapp/icons8-esc-100.png', ExtractFilePath(ParamStr(0)) + '/imgapp/icons8-esc-40.png');
  show_aapp(ExtractFilePath(ParamStr(0)) + '/imgapp/icons8-ergonomic-keyboard-100.png', '快捷', ExtractFilePath(ParamStr(0)) + '/imgapp/icons8-ergonomic-keyboard-100-hover.png', ExtractFilePath(ParamStr(0)) + '/imgapp/icons8-ergonomic-keyboard-100.png');
  show_aapp(ExtractFilePath(ParamStr(0)) + '/imgapp/cfg.png', '配置', ExtractFilePath(ParamStr(0)) + '/imgapp/icons8-settings-100.png', ExtractFilePath(ParamStr(0)) + '/imgapp/cfg.png');
  show_aapp(ExtractFilePath(ParamStr(0)) + '/imgapp/icons8-translation-64.png', '翻译', ExtractFilePath(ParamStr(0)) + '/imgapp/icons8-translation-64.png', ExtractFilePath(ParamStr(0)) + '/imgapp/icons8-google-translate-100.png');



 var TotalHeight := 6;
  for var p in pnls do
    TotalHeight := TotalHeight + p.Height;

  Height := TotalHeight;



  Top := (Screen.WorkAreaHeight - Height) div 2;
end;

procedure TbottomForm.LVexeinfoMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  ReleaseCapture;
  SendMessage(handle, WM_SYSCOMMAND, SC_MOVE + HTCaption, 0);
end;

initialization
  pnls := TList<TImgPanel>.Create;

  ActionMap := TActionMap.Create;
  ActionMap.Add('关机',
    procedure
    begin
      SystemShutdown(False);
    end);
  ActionMap.Add('重启',
    procedure
    begin
      SystemShutdown(True);
    end);
  ActionMap.Add('翻译',
    procedure
    begin
      g_core.utils.launch_app(g_core.json.Config.translator);
    end);
  ActionMap.Add('快捷',
    procedure
    var
      OpenDlg: TFileOpenDialog;
    begin
      OpenDlg := TFileOpenDialog.Create(nil);
      try
        if OpenDlg.Execute then
          set_json_value('config', 'shortcut', OpenDlg.FileName);
      finally
        OpenDlg.Free;
      end;
    end);
  ActionMap.Add('配置',
    procedure
    var
      vobj: TObject;
    begin
      vobj := g_core.find_object_by_name('cfgForm');
      g_core.nodes.is_configuring := true;
      SetWindowPos(TCfgForm(vobj).Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
      TCfgForm(vobj).Show;
    end);
  ActionMap.Add('退出',
    procedure
    begin
      Application.Terminate;
    end);


finalization
  ActionMap.Free;
  pnls.Free;

end.

