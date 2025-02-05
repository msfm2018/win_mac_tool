unit ConfigurationForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Math,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Winapi.ShellAPI, Vcl.ComCtrls, Vcl.Grids, Vcl.ValEdit, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Buttons, utils, u_json, System.IniFiles,
  Vcl.Imaging.pngimage, System.JSON, System.Generics.Collections, Vcl.Menus,
  ImgButton, winapi.UxTheme, ImgPanel, Vcl.Mask, System.Hash, System.ImageList,
  Vcl.ImgList, Vcl.Imaging.jpeg;

type
  TCfgForm = class(TForm)
    imgEdit1: TLabeledEdit;
    text_edit: TLabeledEdit;
    tip: TLabeledEdit;
    filedit: TLabeledEdit;
    ComboBox1: TComboBox;
    ImgList: TImageList;
    pinfo: TPanel;
    ScrollBox1: TScrollBox;
    pbottom: TPanel;
    CheckBox1: TCheckBox;
    ListView1: TListView;
    ImgPanel1: TImgPanel;
    ImgPanel2: TImgPanel;
    pnl_left: TPanel;
    imgboxFace: TImage;
    btnmsg_panel: TLabel;
    btnorg_panel: TLabel;
    Label1: TLabel;
    pnl_right: TPanel;
    p1: TPanel;
    p2: TPanel;
    Image2: TImage;
    p_org: TPanel;
    lblok: TImgPanel;
    pnl1: TPanel;
    Image1: TImage;
    Image3: TImage;
    btnLogin: TLabel;
    edtNickName: TLabel;
    edtSex: TLabel;
    Label2: TLabel;
    lbl_phone: TLabel;
    MlSkinLabel1: TLabel;
    MlSkinLabel2: TLabel;
    MlSkinLabel3: TLabel;
    MlSkinLabel5: TLabel;
    Image4: TImage;
    Memo1: TMemo;
    ImgPanel3: TImgPanel;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure imgEdit1DblClick(Sender: TObject);
    procedure rbtxtClick(Sender: TObject);
    procedure rbimgClick(Sender: TObject);
    procedure fileditSubLabelDblClick(Sender: TObject);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure ScrollBox1MouseEnter(Sender: TObject);
    procedure ScrollBox1MouseLeave(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ListView1DblClick(Sender: TObject);
    procedure ListView1Resize(Sender: TObject);
    procedure ImgPanel2Click(Sender: TObject);
    procedure btnmsg_panelClick(Sender: TObject);
    procedure btnorg_panelClick(Sender: TObject);
    procedure Image2MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure lblokClick(Sender: TObject);
    procedure Label1Click(Sender: TObject);
  private
    file_map: TDictionary<string, string>;
    procedure AddFileInfoToJson(const Key, ImageFileName, FilePath, ToolTip: string);
    procedure ClearInputs;
    procedure show_aapp(Path, FileName: string);
    procedure PanelMouseEnter(Sender: TObject);
    procedure PanelMouseLeave(Sender: TObject);

    procedure PanelDblClick(Sender: TObject);
    procedure Buttoaction_translatoradd(Sender: TObject);
    procedure AdjustLastColumnWidth;
    procedure translateDblClick(Sender: TObject);
    procedure msg_board_state;
    procedure org_board_state;

  public
    FShadowAlpha: Byte; // 阴影透明度 (0-255)
    FShadowColor: TColor; // 阴影颜色

//    closebtn: TImgButton;
    close1: TImgButton;
  end;

  TStartMenuApp = record
    Name: string;
    Path: string;
  end;

  TStartMenuApps = class
  public
    class function GetApps: TArray<TStartMenuApp>;
  end;

var
  xchange: Boolean = false;
  FRoundWindow: Boolean = true;
  FShadowForm: tform;

var
  Apps: TArray<TStartMenuApp>;
  App: TStartMenuApp;

implementation

{$R *.dfm}

uses
  core, System.UITypes, ApplicationMain;

function SaveAppIconAsPng(const FilePath: string): string;
var
  Icon: TIcon;
  Bitmap: TBitmap;
  Png: TPngImage;
begin
  Icon := TIcon.Create;
  Bitmap := TBitmap.Create;
  Png := TPngImage.Create;
  try
    // 获取应
    Icon.Handle := ExtractIcon(HInstance, PChar(FilePath), 0);
    // 将图标转换为位图
    Bitmap.Width := Icon.Width;
    Bitmap.Height := Icon.Height;
    Bitmap.Canvas.Draw(0, 0, Icon);

    // 将位图转换为 PNG
    Png.Assign(Bitmap);

    // 保存为 PNG 文件
    result := ExtractFilePath(ParamStr(0)) + 'img\' + ChangeFileExt(ExtractFileName(FilePath), '.png');
    Png.SaveToFile(result);

  finally
    Icon.Free;
    Bitmap.Free;
    Png.Free;
  end;
end;

procedure TCfgForm.PanelDblClick(Sender: TObject);
var
  key1, key2: string;
  Hash, imgpath: string;
begin
  key1 := SaveAppIconAsPng(TImgPanel(Sender).extendB);

  key2 := TImgPanel(Sender).extendb;

  if (key1 <> '') and (key2 <> '') then
  begin
    g_core.utils.CopyFileToFolder(key1, ExtractFilePath(ParamStr(0)) + 'img');

    Hash := THashMD5.GetHashString(ExtractFileName(key1));
    imgpath := key1;

    if file_map.TryAdd(Hash, Format('%s,%s,%s', [ExtractFileName(key1), imgpath, TImgPanel(Sender).extendA])) then
    begin
      AddFileInfoToJson(Hash, ExtractFileName(key1), key2, TImgPanel(Sender).extendA);

      with ListView1.Items.Add do
      begin
        Caption := ExtractFileName(key1);  // 文件名
        SubItems.Add(Trim(TImgPanel(Sender).extendA));  // 工具提示
      end;

      ClearInputs;
    end;

    var p: timage;
    if not g_core.ImageCache.TryGetValue(ExtractFileName(key1), p) then
    begin
      p := TImage.Create(nil);
      p.Picture.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'img\' + ExtractFileName(key1));
      g_core.ImageCache.Add(ExtractFileName(key1), p);

    end

  end;

end;

procedure TCfgForm.show_aapp(Path, FileName: string);
var
  Panel: TImgPanel;
  Image: TImage;
  Label1: TLabel;
  FileIcon: TIcon;
  FilePath: string;
begin
  FilePath := Path;

  FileIcon := TIcon.Create;
  try
    FileIcon.Handle := ExtractIcon(HInstance, PChar(FilePath), 0);

    ScrollBox1.VertScrollBar.Visible := True;  // 启用垂直滚动条

    Panel := TImgPanel.Create(Scrollbox1);
    Panel.Parent := ScrollBox1;

    Panel.Align := alTop;
    Panel.Height := 60;  // 设置Panel的高度
    Panel.BevelOuter := bvNone; // 可选，移除边框
    Panel.ParentColor := False;
    Panel.StyleElements := [seClient];
    Panel.extendA := FileName;
    Panel.extendB := Path; //
    // 创建显示图标的Image控件
    Image := TImage.Create(Self);
    Image.Parent := Panel;
    Image.Picture.Icon := FileIcon;
    Image.Width := 32;   // 设置图标的大小
    Image.Height := 32;
    Image.OnDblClick := translateDblClick;
    // 创建显示文本的Label控件
    Label1 := TLabel.Create(Self);
    Label1.Parent := Panel;
    Label1.Caption := FileName;
    Label1.AutoSize := True;
    Label1.OnDblClick := translateDblClick;

    Image.Left := 10; // (Panel.Width - Image.Width - Label1.Width - 10) div 2;  // 图标居中
    Image.Top := (Panel.Height - Image.Height) div 2;  // 图标垂直居中

    Label1.Left := Image.Left + Image.Width + 10;  // 图标和文本之间的间距
    Label1.Top := (Panel.Height - Label1.Height) div 2;  // 文本垂直居中

     // 设置鼠标事件处理程序
    Panel.OnMouseEnter := PanelMouseEnter;
    Panel.OnMouseLeave := PanelMouseLeave;
    Panel.ParentBackground := False;
    Panel.OnDblClick := PanelDblClick;
  finally
    FileIcon.Free;
  end;

end;

procedure TCfgForm.translateDblClick(Sender: TObject);
begin
  if Sender is tlabel then
    TImgPanel(TLabel(Sender).Parent).OnDblClick(TLabel(Sender).Parent)
  else if Sender is TImage then
    TImgPanel(TImage(Sender).Parent).OnDblClick(TLabel(Sender).Parent);
end;

procedure TCfgForm.PanelMouseEnter(Sender: TObject);
begin
  (Sender as TImgPanel).color := $f5f5f5;

end;

procedure TCfgForm.PanelMouseLeave(Sender: TObject);
begin

  (Sender as TImgPanel).color := clBtnFace;

end;

procedure LoadIconFromDll(const extension: string; Image: TImage);
var
  hIcon1: HICON;
begin
  hIcon1 := GetFileIcon1(PChar(extension));

  if hIcon1 <> 0 then
  begin
    Image.Picture.Icon.Handle := hIcon1;

  end

end;

class function TStartMenuApps.GetApps: TArray<TStartMenuApp>;
var
  AppsJSON: string;
  JSONArray: TJSONArray;
  JSONValue: TJSONValue;
  App: TStartMenuApp;
  AppList: TArray<TStartMenuApp>;
  I: Integer;
begin
  // Call DLL function
  AppsJSON := string(GetStartMenuApps);

  // Parse JSON string
  JSONArray := TJSONObject.ParseJSONValue(AppsJSON) as TJSONArray;
  try
    SetLength(AppList, JSONArray.Count);
    for I := 0 to JSONArray.Count - 1 do
    begin
      JSONValue := JSONArray.Items[I];
      App.Name := JSONValue.GetValue<string>('name');
      App.Path := JSONValue.GetValue<string>('path');
      AppList[I] := App;
    end;
  finally
    JSONArray.Free;
  end;

  Result := AppList;
end;

procedure TCfgForm.Buttoaction_translatoradd(Sender: TObject);
var
  key1, key2, Hash, imgpath: string;
  utf8Text, ansi_path: PAnsiChar;
begin
  if CheckBox1.Checked then
  begin
    key1 := Trim(imgEdit1.Text);
    key2 := Trim(filedit.Text);
    if (key1 <> '') and (key2 <> '') then
    begin
      g_core.utils.CopyFileToFolder(key1, ExtractFilePath(ParamStr(0)) + 'img');

      Hash := THashMD5.GetHashString(ExtractFileName(key1));
      imgpath := ExtractFilePath(ParamStr(0)) + 'img\' + ExtractFileName(key1);

      if file_map.TryAdd(Hash, Format('%s,%s,%s', [ExtractFileName(key1), imgpath, Trim(tip.Text)])) then
      begin
        AddFileInfoToJson(Hash, ExtractFileName(key1), key2, tip.Text);


        // 使用 ListView 添加数据
        with ListView1.Items.Add do
        begin
          Caption := ExtractFileName(key1);  // 文件名
          SubItems.Add(Trim(tip.Text));       // 工具提示
        end;

        ClearInputs;
      end;

      var p: timage;
      if not g_core.ImageCache.TryGetValue(ExtractFileName(key1), p) then
      begin
        p := TImage.Create(nil);
        p.Picture.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'img\' + ExtractFileName(key1));
        g_core.ImageCache.Add(ExtractFileName(key1), p);

      end

    end;
  end
  else
  begin
    if (Trim(text_edit.Text) <> '') and (Trim(filedit.Text) <> '') then
    begin
      imgpath := ExtractFilePath(ParamStr(0)) + 'img\' + FormatDateTime('yyyymmddhhnnsszzz', Now) + '.png';

      utf8Text := PAnsiChar(UTF8Encode(Trim(text_edit.Text)));

      ansi_path := PAnsiChar(UTF8Encode(imgpath));
      if ComboBox1.Text = '图标样式1' then
        write_png_with_text(ansi_path, utf8Text, 2)
      else
        write_png_with_text(ansi_path, utf8Text, 1);

      key1 := ExtractFileName(imgpath);
      Hash := THashMD5.GetHashString(key1);

      if file_map.TryAdd(Hash, Format('%s,%s,%s', [key1, imgpath, Trim(tip.Text)])) then
      begin
        AddFileInfoToJson(Hash, key1, Trim(filedit.Text), tip.Text);

         // 使用 ListView 添加数据
        with ListView1.Items.Add do
        begin
          Caption := key1;  // 文件名
          SubItems.Add(Trim(tip.Text));  // 工具提示
        end;

        ClearInputs;
      end;

      var p: timage;
      if not g_core.ImageCache.TryGetValue(key1, p) then
      begin
        p := TImage.Create(nil);
        p.Picture.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'img\' + key1);
        g_core.ImageCache.Add(key1, p);

      end

    end;
  end;

end;

procedure TCfgForm.AddFileInfoToJson(const Key, ImageFileName, FilePath, ToolTip: string);
begin
  add_json(Key, ImageFileName, FilePath, ToolTip, True, nil);
end;

procedure TCfgForm.CheckBox1Click(Sender: TObject);
begin
  if CheckBox1.Checked then
  begin
    text_edit.Enabled := false;
    imgEdit1.Enabled := True;
  end
  else
  begin
    text_edit.Enabled := True;
    imgEdit1.Enabled := false;
  end;
end;

procedure TCfgForm.ClearInputs;
begin
  imgEdit1.Text := '';
  text_edit.Text := '';
  tip.Text := '';
  filedit.Text := '';
  xchange := True;
end;

procedure TCfgForm.fileditSubLabelDblClick(Sender: TObject);
var
  OpenDlg: TFileOpenDialog;
begin
  OpenDlg := TFileOpenDialog.Create(nil);
  try
    if OpenDlg.Execute then
    begin
      filedit.Text := OpenDlg.FileName;
    end;
  finally
    OpenDlg.Free;
  end;
end;

procedure TCfgForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  form1.node_rebuilder(Screen.WorkAreaHeight);
//  FreeAndNil(closebtn);
  FreeAndNil(close1);
  g_core.nodes.is_configuring := false;
  file_map.Free;
end;

procedure TCfgForm.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  ReleaseCapture;
  SendMessage(handle, WM_SYSCOMMAND, SC_MOVE + HTCaption, 0);
end;

procedure TCfgForm.FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  if WheelDelta < 0 then
    ScrollBox1.Perform(WM_VSCROLL, SB_LINEDOWN, 0)
  else
    ScrollBox1.Perform(WM_VSCROLL, SB_LINEUP, 0);
  if ActiveControl is TComboBox then
    if not TComboBox(ActiveControl).DroppedDown then
      Handled := True;
end;

procedure TCfgForm.AdjustLastColumnWidth;
var
  TotalWidth: Integer;
  ColCount: Integer;
  I: Integer;
  UsedWidth: Integer;
begin
  // 获取 ListView 的总宽度
  TotalWidth := ListView1.ClientWidth;

  // 获取列数（假设 ListView 至少有两列）
  ColCount := ListView1.Columns.Count;

  if ColCount > 1 then
  begin
    // 计算除最后一列外所有列的宽度
    UsedWidth := 360;

    ListView1.Columns[0].Width := UsedWidth;
    // 设置最后一列的宽度为剩余的空间
    ListView1.Columns[ColCount - 1].Width := TotalWidth - UsedWidth;
  end;
end;

procedure TCfgForm.btnmsg_panelClick(Sender: TObject);
begin
  msg_board_state();
end;

procedure TCfgForm.btnorg_panelClick(Sender: TObject);
begin
  org_board_state();
end;

procedure TCfgForm.msg_board_state;
begin
  p1.Parent := p_org;
  p1.Visible := true;
  p1.Align := alClient;
  pbottom.Visible := false;
  pnl1.Visible:=False;

  btnmsg_panel.Transparent := False;
  btnorg_panel.Transparent := true;

  btnmsg_panel.refresh;
  btnorg_panel.refresh;

//  edtlookup.Clear;
//  p_org.Visible := false;
//  p_contact.Visible := True;
//
//  pnl_right_chat.Visible := True;
//  pnl_right_chat.align := alclient;
//  pnl_right_info.Visible := false;
//
//  btnmsg_panel.Transparent := False;
//  btnorg_panel.Transparent := true;
//
//  btnmsg_panel.refresh;
//  btnorg_panel.refresh;
  Label1.refresh;
//  imgboxFace.refresh;

end;

procedure TCfgForm.org_board_state;
begin
//  p1.Parent := nil;
  p1.Visible := false;
  btnorg_panel.Transparent := false;
  btnmsg_panel.Transparent := true;

  btnmsg_panel.refresh;
  btnorg_panel.refresh;
     pnl1.Visible:=False;
  pbottom.Visible := true;
end;
        procedure TCfgForm.Label1Click(Sender: TObject);
begin
//       p1.Parent := nil;
  p1.Visible := false;
  btnorg_panel.Transparent := false;
  btnmsg_panel.Transparent := false;

  btnmsg_panel.refresh;
  btnorg_panel.refresh;
     pnl1.Visible:=true;
  pbottom.Visible := False;

end;
procedure TCfgForm.FormShow(Sender: TObject);
var
  values: TArray<string>;
  v: TSettingItem;
  tmp_key: string;
begin

// 清空原有的 ListView 数据
  ListView1.Items.Clear;

  // 设置 ListView 的列
  ListView1.Columns.Clear;
  ListView1.Columns.Add;  // 第一列：文件名
  ListView1.Columns.Add;  // 第二列：工具提示

  AdjustLastColumnWidth();

  EnableNonClientDpiScaling(Handle);
  Apps := TStartMenuApps.GetApps;
  for App in Apps do

    show_aapp(App.Path, App.Name);
  filedit.Text := '';
  file_map := TDictionary<string, string>.Create;

  for tmp_key in g_core.json.Settings.keys do
  begin

    if g_core.json.Settings.TryGetValue(tmp_key, v) then
      if (v.Is_path_valid) then
      begin
        file_map.TryAdd(tmp_key, v.image_file_name + ',' + v.FilePath + ',' + v._tip);

        with ListView1.Items.Add do
        begin
          Caption := v.image_file_name; // 文件名
          SubItems.Add(v._tip);      // 工具提示
        end;
      end;
  end;

  xchange := false;

  text_edit.Text := '';
  tip.Text := '无';
  imgEdit1.Text := '';

  SetWindowCornerPreference(Handle);

//  closebtn := TImgButton.Create(self);
//  closebtn.Parent := Panel2;
//
//  closebtn.Left := filedit.Left + filedit.Width + 20;
//  closebtn.Top := tip.Top;
//  closebtn.SetBounds(closebtn.Left, closebtn.top, 48, 48);
//
//  closebtn.Image.LoadFromFile(ExtractFilePath(ParamStr(0)) + '/img/add_hover.png');
//  closebtn.Image1.LoadFromFile(ExtractFilePath(ParamStr(0)) + '/img/add.png');
//  closebtn.OnClick := Buttoaction_translatoradd;
//  closebtn.Cursor := crHandpoint;

//  close1 := TImgButton.Create(self);
//  close1.Parent := Panel3;
//  close1.Align := alRight;
//
//  close1.Width := 26;
//  close1.Height := 32;
//  close1.Image.LoadFromFile(ExtractFilePath(ParamStr(0)) + '/img/close_hover.png');
//  close1.Image1.LoadFromFile(ExtractFilePath(ParamStr(0)) + '/img/close.png');
//  close1.OnClick := closex;
//  close1.Cursor := crHandpoint;


  btnmsg_panelClick(self);
end;

procedure TCfgForm.Image2MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  ReleaseCapture;
  Perform(WM_SysCommand, $F008, 0);
end;

procedure TCfgForm.imgEdit1DblClick(Sender: TObject);
var
  OpenDlg: TFileOpenDialog;
  FileType: TFileTypeItem;
begin
  SendToBack();
  OpenDlg := TFileOpenDialog.Create(nil);
  FileType := OpenDlg.FileTypes.Add();
  OpenDlg.Title := '选择 PNG 文件';
  FileType.DisplayName := 'PNG';
  FileType.FileMask := '*.png*';
  OpenDlg.DefaultFolder := GetCurrentDir; // 设置默认文件夹


  OpenDlg.DefaultExtension := 'png'; // 设置默认扩展名

  try
    if OpenDlg.Execute then
    begin
      ImgEdit1.Text := OpenDlg.FileName;
    end;

  finally
    OpenDlg.Free;
    BringToFront;
  end;
end;

procedure TCfgForm.ImgPanel2Click(Sender: TObject);
begin
  close;
end;



procedure TCfgForm.lblokClick(Sender: TObject);
begin
Buttoaction_translatoradd(self);
end;

procedure TCfgForm.ListView1DblClick(Sender: TObject);
var
  selectedItem: TListItem;
  key1, Hash: string;
begin
  selectedItem := ListView1.Selected;
  if selectedItem = nil then
    Exit;

  key1 := selectedItem.Caption;
  Hash := THashMD5.GetHashString(key1);

  for var Key in file_map.Keys do
  begin
    if Key = Hash then
    begin
      ListView1.Items.Delete(selectedItem.Index);  // 删除该项

      file_map.Remove(Key);

      remove_json(Key);
      del_json_value('settings', Key);
      Break;
    end;
  end;

end;

procedure TCfgForm.ListView1Resize(Sender: TObject);
begin
  AdjustLastColumnWidth();
end;

procedure TCfgForm.rbimgClick(Sender: TObject);
begin
  text_edit.Enabled := false;
  imgEdit1.Enabled := True;

end;

procedure TCfgForm.rbtxtClick(Sender: TObject);
begin
  text_edit.Enabled := True;
  imgEdit1.Enabled := false;

end;

procedure TCfgForm.ScrollBox1MouseEnter(Sender: TObject);
begin
  Screen.Cursor := crHandPoint;
end;

procedure TCfgForm.ScrollBox1MouseLeave(Sender: TObject);
begin
  Screen.Cursor := crDefault;
end;

end.
