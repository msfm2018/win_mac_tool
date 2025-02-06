unit ApplicationMain;

interface

uses
//记得 保留  Winapi.GDIPAPI, Winapi.GDIPOBJ 程序中没有使用这部分 奇怪了  少了运行报错

  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Registry, Winapi.Dwmapi, core, Dialogs, ExtCtrls, Generics.Collections,
  Vcl.Imaging.pngimage, Winapi.ShellAPI, inifiles, Vcl.Imaging.jpeg, ComObj,
  PsAPI, utils, Winapi.GDIPAPI, Winapi.GDIPOBJ, System.SyncObjs, System.Math,
  System.JSON, u_json, ConfigurationForm, Vcl.Menus, InfoBarForm,
  System.Generics.Collections, plug, TaskbarList, PopupMenuManager, event,
  Vcl.StdCtrls;

type
  TForm1 = class(TForm)
    Label1: TLabel;
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);

  private
    node_at_cursor: _node;

    gdraw_text: string;
    procedure node_click(Sender: TObject);
    procedure wndproc(var Msg: tmessage); override;

  private
    main_background: timage;

    procedure node_mouse_enter(Sender: TObject);

    procedure node_mouse_move(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure node_mouse_leave(Sender: TObject);
    procedure CalculateAndPositionNodes();
    procedure img_bgMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure move_windows(h: thandle);

    procedure Initialize_form;

  public
    procedure ConfigureLayout;
  private
    ScaleFactor: double;

    procedure smooth_layout_adjustment(Sender: TObject); inline;
    procedure form_mouse_wheel(WheelMsg: TWMMouseWheel);

    procedure AdjustNodeSize(Node: _node; Rate: Double);
  public
    procedure node_rebuilder(screenHeight: integer);
    procedure adjust_node_layout(screenHeight: integer);

    procedure nodeimgload;
    procedure show_side_form;

    procedure PureCalculateAndPositionNodes;

  end;

var
  Form1: TForm1;
  label_top, label_left: integer;

var
  FormPosition: TFormPositions;
  hoverLabel: Boolean = false;

var
  hMouseHook: HHOOK;
  hwndMonitor: HWND;
  heventHook: THandle;
  RunOnce: Boolean = true;
  finish_layout: Boolean = false;

var
  LastReposTime: TDateTime;

implementation

{$R *.dfm}

const
  kGetPreferredBrightnessRegKey = 'Software\Microsoft\Windows\CurrentVersion\Themes\Personalize';
  kGetPreferredBrightnessRegValue = 'AppsUseLightTheme';

procedure UpdateTheme(hWnd: hWnd);
var
  Reg: TRegistry;
  LightMode: DWORD;
  EnableDarkMode: BOOL;
begin
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKeyReadOnly(kGetPreferredBrightnessRegKey) then
    begin
      if Reg.ValueExists(kGetPreferredBrightnessRegValue) then
      begin
        LightMode := Reg.ReadInteger(kGetPreferredBrightnessRegValue);
        EnableDarkMode := LightMode = 0;
        DwmSetWindowAttribute(hWnd, DWMWA_USE_IMMERSIVE_DARK_MODE, @EnableDarkMode, SizeOf(EnableDarkMode));
      end;
    end;
  finally
    Reg.Free;
  end;
end;

procedure TForm1.nodeimgload();
var
  kys: TDictionary<string, TSettingItem>;
begin

  kys := g_core.json.Settings;

  var keys := kys.keys;
  for var Key in keys do
  begin
    var MValue := kys.Items[Key];
    var p: timage;
    if not g_core.ImageCache.TryGetValue(MValue.image_file_name, p) then
    begin
      p := TImage.Create(nil);
      p.Picture.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'img\' + MValue.image_file_name);
      g_core.ImageCache.Add(MValue.image_file_name, p);

    end

  end;

end;



// 计算和定位节点的逻辑
            //重新设计 把图片预存到 内存中 不每次再文件中加载

procedure TForm1.CalculateAndPositionNodes();
var
  Node: _node;
  I, NodeCount, NodeSize, NodeGap: Integer;
  v: TSettingItem;
  ClientCenterY: Integer;
  kys: TDictionary<string, TSettingItem>;
begin

  NodeSize := g_core.nodes.node_size;
  NodeGap := g_core.nodes.node_gap;
  NodeCount := g_core.json.Settings.Count;
  kys := g_core.json.Settings;

  ClientCenterY := Round((Self.ClientHeight - NodeSize * ScaleFactor)) div 2;

  try
    try

      g_core.nodes.count := NodeCount;

      if g_core.nodes.Nodes <> nil then
        for Node in g_core.nodes.Nodes do
        begin
          kys.TryGetValue(Node.key, v);
          if not v.Is_path_valid then
            FreeAndNil(v.memory_image);
          FreeAndNil(Node);
        end;

      Form1.height := NodeSize + NodeSize div 2 + 130;

      setlength(g_core.nodes.Nodes, NodeCount);
      I := 0;
      var keys := kys.keys;
      for var Key in keys do
      begin
        var MValue := kys.Items[Key];
        Node := _node.Create(self);
        g_core.nodes.Nodes[I] := Node;
        Node.Width := Round(NodeSize * ScaleFactor);
        Node.Height := Round(NodeSize * ScaleFactor);

        if I = 0 then
          Node.Left := NodeGap + exptend
        else
          Node.Left := g_core.nodes.Nodes[I - 1].Left + NodeGap + Node.Width;

        with Node do
        begin

          id := I;
          name := 'node' + I.ToString;
          Top := ClientCenterY;
          Center := true;

          Transparent := true;
          Parent := self;
          file_path := MValue.FilePath;
          _tip := MValue._tip;

          if MValue.Is_path_valid then
          begin
            var p: timage;
            if not g_core.ImageCache.TryGetValue(MValue.image_file_name, p) then
            begin

              Node.Picture.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'img\' + MValue.image_file_name);

            end
            else
            begin

              Node.Picture.Assign(p.Picture);

            end;
          end
          else
          begin
            MValue.memory_image.Position := 0;
            Picture.LoadFromStream(MValue.memory_image);
          end;

          Stretch := true;
          OnMouseLeave := node_mouse_leave;
          OnMouseMove := node_mouse_move;
          OnMouseDown := FormMouseDown;
          OnClick := node_click;

          OnMouseEnter := node_mouse_enter;

          original_size.cx := Node.Width;
          original_size.cy := Node.height;
          center_point.x := Node.Left + Node.Width div 2;
          center_point.y := Node.top + Node.height div 2;

        end;
        Inc(I)
      end;

      if NodeCount > 0 then
        Self.Width := g_core.nodes.Nodes[NodeCount - 1].Left + g_core.nodes.Nodes[NodeCount - 1].Width + NodeGap + exptend;

    except

    end;
  finally

  end;

end;

procedure TForm1.node_mouse_enter(Sender: TObject);
var
  Node: _node;
begin
  Node := Sender as _node;

  gdraw_text := Node._tip;

  label_top := Node.Top - 65;
  label_left := Node.Left + (Node.Width div 2);

  hoverLabel := true;
  RunOnce := False;
end;

procedure TForm1.node_mouse_leave(Sender: TObject);
begin

  restore_state;
  RunOnce := true;
end;

procedure TForm1.node_mouse_move(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  rate: double;
  a, b: integer;
  I: Integer;
  NewWidth, NewHeight: Integer;
  Rate11: double;
  Current_node: _node;
  lp: tpoint;
begin
  if g_core.nodes.is_configuring then
    exit;

  if (EventDef.isLeftClick) then
  begin
    if (X <> EventDef.X) or (Y <> EventDef.Y) then
    begin
      EventDef.X := X;
      EventDef.Y := Y;

      move_windows(Handle);
    end
    else
      timage(Sender).OnClick(self);
  end
  else
  begin

    var Node := _node(Sender);
    if hoverLabel then
    begin
      label_top := Node.Top - 35;
      label_left := Node.Left + (Node.Width div 4); //- (hoverLabel.Width div 2);
    end;

    GetCursorPos(lp);

    node_at_cursor := _node(Sender);

    if g_core.json.Config.style = 'style-2' then
    begin

        // 调整当前节点
      Current_node := node_at_cursor;

//    var GC := (X mod (Current_node.original_size.cx * 2)) / (Current_node.original_size.cx * 2);
//
//  // 使用 Sin 函数生成 0-1-0 的变化率
//    var Rate11 := Sin(GC * Pi);


      if X > Current_node.original_size.cx div 2 then
      begin

        var NodeCenterX := Current_node.original_size.cx;
        var SymmetricX := Abs(X - NodeCenterX);
        var GC := (SymmetricX mod (Current_node.original_size.cx * 2)) / (Current_node.original_size.cx * 2);
        Rate11 := Sin(GC * Pi);
      end
      else
      begin
        var GC := (X mod (Current_node.original_size.cx * 2)) / (Current_node.original_size.cx * 2);

        Rate11 := Sin(GC * Pi);
      end;
//        Rate11  := 0.5 * (1 - Cos(Pi * Rate11));
      AdjustNodeSize(Current_node, Rate11);
    end
    else if g_core.json.Config.style = 'style-1' then
    begin

      for I := 0 to g_core.nodes.count - 1 do
      begin
        Current_node := g_core.nodes.Nodes[I];
//           if Node= Current_node then
//             Continue;


        a := Current_node.Left - ScreenToClient(lp).X + Current_node.Width div 2;
        b := Current_node.Top - ScreenToClient(lp).Y + Current_node.Height div 4;

        rate := g_core.utils.rate(a, b);
        rate := Min(Max(rate, 0.5), 1);
        if Node = Current_node then
          rate := rate - 0.1;

        NewWidth := Round(Current_node.original_size.cx * 2 * rate);
        NewHeight := Round(Current_node.original_size.cy * 2 * rate);

        var maxValue: Integer := 128;

        NewWidth := Min(NewWidth, maxValue);
        NewHeight := Min(NewHeight, maxValue);

        Current_node.center_point.x := Current_node.Left + Current_node.Width div 2;
        Current_node.center_point.y := Current_node.Top + Current_node.Height div 2;

        if top < top_snap_distance + 100 then
        begin

          Current_node.Width := Floor(Current_node.original_size.cx * 2 * rate);
          Current_node.height := Floor(Current_node.original_size.cx * 2 * rate);
          Current_node.Left := Current_node.Left - Floor((Current_node.Width - Current_node.original_size.cx) * rate) - 6;
        end
        else
        begin

      // 调整顶部位置而不改变底部位置
          var newTop := Current_node.Top - (NewHeight - Current_node.Height);

          Current_node.SetBounds(Current_node.center_point.x - NewWidth div 2, newTop, NewWidth, NewHeight);
        end;


//    中间往外凸显
//       Current_node.SetBounds(Current_node.center_x - NewWidth div 2, Current_node.center_y - NewHeight div 2, NewWidth, NewHeight);

      end;
    end;
    smooth_layout_adjustment(Self);

  end;
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if g_core.nodes.is_configuring then
    exit;
  if Button = mbleft then
  begin
    EventDef.isLeftClick := true;
    EventDef.Y := Y;
    EventDef.X := X;
  end;

end;

var
  oldNode: string = '';

procedure TForm1.node_click(Sender: TObject);
begin
  if _node(Sender).file_path = '' then
    Exit;

  if (oldNode = _node(Sender).Name) and (_node(Sender)._tip <> '开始菜单') then
    Exit;
  oldNode := _node(Sender).Name;

  if _node(Sender)._tip = '开始菜单' then
  begin
//    if bottomForm.Caption = 'selfdefinestartmenu' then
    PostMessage(handle, WM_USER + 1031, 0, 0)
//    else
//      SimulateCtrlEsc();

  end
  else if _node(Sender)._tip = '' then
    g_core.utils.launch_app(_node(Sender).file_path)
  else if not BringWindowToFront(_node(Sender)._tip) then
    g_core.utils.launch_app(_node(Sender).file_path)
  else
    g_core.utils.launch_app(_node(Sender).file_path);

  EventDef.isLeftClick := False;

end;

procedure tform1.Initialize_form();
begin
  Font.Name := Screen.Fonts.Text;
  Font.Size := 9;

  DoubleBuffered := True;
  BorderStyle := bsNone;

  if main_background = nil then
    main_background := timage.Create(self);
  main_background.OnMouseDown := img_bgMouseDown;
  main_background.Width := Width;
  g_core.utils.init_background(main_background, self, 'bg.png');

  left := g_core.json.Config.Left;
  top := g_core.json.Config.Top;

  RegisterHotKey(Handle, 119, MOD_CONTROL, Ord('B'));

end;

function FindWindowByProcessId(dwProcessId: DWORD): hWnd;
var
  hWnd1: hWnd;
  dwPid: DWORD;
begin
  Result := 0;
  hWnd1 := GetTopWindow(0); // Get the first window

  // Enumerate all windows to find the one with the matching process ID
  while hWnd1 <> 0 do
  begin
    GetWindowThreadProcessId(hWnd1, @dwPid);
    if dwPid = dwProcessId then
    begin
      Result := hWnd1;
      Break;
    end;
    hWnd1 := GetNextWindow(hWnd1, GW_HWNDNEXT);
  end;
end;

procedure TForm1.wndproc(var Msg: tmessage);
var
  lp: TPoint;
  reducedRect: TRect;
var
  Monitor: HMONITOR;
  DpiX, DpiY: UINT;
  SuggestedRect: PRect;
begin
  inherited;
  case Msg.Msg of
    wm_paint:
      begin
        if (hoverLabel) then
        begin
          label1.Visible := true;

          label1.Caption := gdraw_text;
          label1.Left := label_left - 1;
          label1.Top := label_top - 1;
          label1.ParentColor := false;
          label1.Color := $000EADEE;

        end;
      end;
    WM_HOTKEY:
      begin
        if Msg.WParam = 119 then
        begin
          var v := get_json_value('config', 'shortcut');

          ShellExecute(0, 'open', PChar(v), nil, nil, SW_SHOW);
        end;
      end;
    WM_LBUTTON_MESSAGE:
      begin
        ShellExecute(0, 'open', PChar('https://www.bing.com/search?q=%E6%97%A5%E5%8E%86'), nil, nil, SW_SHOWNORMAL);
      end;

    WM_defaultStart_MESSAGE:
      begin
      //尝试使用 flutter
        var param := ExtractFilePath(ParamStr(0)) + 'img\app';
        var exepath := ExtractFilePath(ParamStr(0)) + 'startx\flutter_application_1.exe';

        var StartupInfo: TStartupInfo;
        var ProcessInfo: TProcessInformation;
        var FilePath: string;
        var Params: string;
        begin
          FilePath := exepath; // Path to your Flutter executable
          Params := param; // Parameters to pass

          FillChar(StartupInfo, SizeOf(StartupInfo), 0);
          StartupInfo.cb := SizeOf(StartupInfo);
          if CreateProcess(nil, PChar(FilePath + ' ' + Params), nil, nil, False, 0, nil, nil, StartupInfo, ProcessInfo) then
          begin
            CloseHandle(ProcessInfo.hProcess);
            CloseHandle(ProcessInfo.hThread);
          end
          else
          begin
            ShowMessage('Failed to start process');
          end;

        end;

      end;

    WM_clipboard:
      begin
  // Retrieve the current mouse position
        var mousePos: TPoint;
        GetCursorPos(mousePos);

  // Adjust the position to be 10 units to the right and 10 units down from the mouse cursor
        mousePos.X := mousePos.X + 10;
        mousePos.Y := mousePos.Y - 54;

  // Path to your Flutter executable
        var exepath := ExtractFilePath(ParamStr(0)) + 'clipboard\flutter_application_1.exe';

        var StartupInfo: TStartupInfo;
        var ProcessInfo: TProcessInformation;
        var FilePath: string;

        FilePath := exepath; // Path to your Flutter executable

        FillChar(StartupInfo, SizeOf(StartupInfo), 0);
        StartupInfo.cb := SizeOf(StartupInfo);

  // Create the process
        if CreateProcess(nil, PChar(FilePath), nil, nil, False, 0, nil, nil, StartupInfo, ProcessInfo) then
        begin
    // Wait a moment for the process to create its window
          Sleep(500); // Give it a brief time to initialize (you may adjust this as needed)

    // Now find the window of the process using the ProcessID
          var hwnd: hwnd;
//    hwnd := FindWindowByProcessId(ProcessInfo.dwProcessId);
          hwnd := FindWindow('FLUTTER_RUNNER_WIN32_WINDOW', 'clipform');
    // If the window is found, move it to the desired position
          if hwnd <> 0 then
          begin
            SetWindowPos(hwnd, 0, mousePos.X, mousePos.Y, 0, 0, SWP_NOSIZE or SWP_NOZORDER);
          end;

    // Close the handles to the process and thread
          CloseHandle(ProcessInfo.hProcess);
          CloseHandle(ProcessInfo.hThread);
        end
        else
        begin
          ShowMessage('Failed to start process');
        end;
      end;

    WM_disActive:   //去掉 利大于弊 如果当前激活的窗口不是目标窗口，则向目标窗口发送消息（PostMessage） 不在最前端的时候
      begin
//
//        reducedRect := Rect(form1.BoundsRect.Left, form1.BoundsRect.Top, form1.BoundsRect.Right, form1.BoundsRect.Bottom - 64);
//        GetCursorPos(lp);
//        if not PtInRect(reducedRect, lp) then
//        begin
//          if (LastReposTime > 0) and (Now - LastReposTime < (2 / 86400)) then
//            Exit;
//
//          LastReposTime := Now;
//
//          repos(Screen.WorkAreaHeight);
//        end;

      end;
      //深色 浅色  选择主题颜色 会拦截
    WM_DWMCOLORIZATIONCOLORCHANGED:
      begin
        UpdateTheme(Handle);
      end;
    WM_DPICHANGED:
      begin
        DpiX := LOWORD(Msg.wParam);
        DpiY := HIWORD(Msg.wParam);

        // 计算缩放比例
        ScaleFactor := DpiX / 96.0;

        node_rebuilder(Screen.WorkAreaHeight);
        show_side_form();
      end;
    WM_MOUSEWHEEL:
      form_mouse_wheel(TWMMouseWheel(Msg));
    WM_MOVE:
      begin

        FormPosition := [];

      end;

  end;
end;

procedure TForm1.node_rebuilder(screenHeight: integer);
begin
  if finish_layout then
  begin
    try
      finish_layout := false;
      if hoverLabel then
      begin
        hoverLabel := false;
        label1.Visible := false;
      end;
    // 计算和定位节点
      form1.CalculateAndPositionNodes();

    // 窗体水平居中屏幕
      form1.Left := Screen.Width div 2 - form1.Width div 2;

    //顶部
      if form1.Top < top_snap_distance then
      begin
        form1.Top := -(form1.Height - visible_height) + 50;

        form1.Left := Screen.Width div 2 - form1.Width div 2;
        restore_state();
        FormPosition := [fpTop];
        g_core.utils.SetTaskbarAutoHide(false);
      end
    //底部
      else if form1.top + form1.height > screenHeight then
      begin
        g_core.utils.SetTaskbarAutoHide(true);
        form1.Top := screenHeight - form1.Height + 130;
        form1.Left := Screen.Width div 2 - form1.Width div 2;
        FormPosition := [fpBottom]; // 设置位置为底部
      end
      //中间
      else
      begin
        FormPosition := [];

        g_core.utils.SetTaskbarAutoHide(false);              //隐藏任务栏
      end;
    finally
      finish_layout := true;
    end;

  end;
end;

function LowLevelMouseProc(nCode: Integer; wParam: wParam; lParam: lParam): LRESULT; stdcall;
var
  lp: TPoint;
  reducedRect: TRect;
  mouseStruct: PMSLLHOOKSTRUCT;
  screenHeight: Integer;
  wheelDelta: integer;
begin
  if (nCode = HC_ACTION) then
  begin
    mouseStruct := PMSLLHOOKSTRUCT(lParam);
    if mouseStruct <> nil then
    begin
      if (wParam = WM_MOUSEMOVE) then
      begin

        lp := mouseStruct^.pt;

        screenHeight := Screen.WorkAreaHeight;

        reducedRect := Rect(form1.BoundsRect.Left, form1.BoundsRect.Top, form1.BoundsRect.Right, form1.BoundsRect.Bottom - 64);

        if PtInRect(reducedRect, lp) then
        begin

          form1.FormStyle := fsStayOnTop;
        end
        else
        begin

          form1.FormStyle := fsNormal;
        end;

        if not PtInRect(reducedRect, lp) then
        begin

          if RunOnce then
          begin
            RunOnce := false;
            form1.adjust_node_layout(screenHeight);
          end;
        end
        else
        begin

          if FormPosition = [] then
          begin

          end
          else if fpTop in FormPosition then
          begin

            if form1.Top < top_snap_distance then
              form1.Top := -56;
          end
          else if fpBottom in FormPosition then
          begin

            form1.Top := screenHeight - form1.Height + 80;
          end;
        end;
      end

    end;
  end;

  Result := CallNextHookEx(hMouseHook, nCode, wParam, lParam);
end;

procedure WinEventProc(hook: THandle; event: DWORD; hwnd: hwnd; idObject, idChild: LONG; idEventThread, time: DWORD); stdcall;
var
  rc: TRect;
begin
  // 检查是否是我们想要的窗口和事件
  if (hwnd = hwndMonitor) and (idObject = OBJID_WINDOW) and (idChild = CHILDID_SELF) and (event = EVENT_OBJECT_LOCATIONCHANGE) then
  begin
    // 获取窗口的位置
    if GetWindowRect(hwndMonitor, rc) then
    begin
      // 输出窗口的位置
//      Debug.Show(Format('Window rect is (%d,%d)-(%d,%d)', [rc.Left, rc.Top, rc.Right, rc.Bottom]));

    end;
  end;
end;

procedure global_hook(hwnd: hwnd; uMsg, idEvent: UINT; dwTime: DWORD); stdcall;
begin
  HandleNewProcessesExport();
end;

procedure TForm1.show_side_form();
begin
  if bottomForm <> nil then
    FreeAndNil(bottomForm);

  bottomForm := TbottomForm.Create(self);

  bottomForm.show;
end;

procedure TForm1.PureCalculateAndPositionNodes();
var
  Node: _node;
  I, NodeCount, NodeSize, NodeGap: Integer;
  v: TSettingItem;
  ClientCenterY: Integer;
  kys: TDictionary<string, TSettingItem>;
  keys: TArray<string>;
begin

  NodeSize := g_core.nodes.node_size;
  NodeGap := g_core.nodes.node_gap;
  NodeCount := g_core.json.Settings.Count;
  kys := g_core.json.Settings;

  Form1.height := NodeSize + NodeSize div 2 + 130;
  keys := kys.Keys.ToArray; // 将键集合转换为数组
  ClientCenterY := Round((Self.ClientHeight - NodeSize * ScaleFactor)) div 2;
  for I := 0 to NodeCount - 1 do
  begin
    var Key := keys[I];       // 通过索引获取键
    var MValue := kys[Key];   // 通过键从字典中取值
    if (I < Length(g_core.nodes.Nodes)) and (g_core.nodes.Nodes[I] <> nil) then
    begin
      Node := g_core.nodes.Nodes[I];

      Node.Width := Round(NodeSize * ScaleFactor);
      Node.Height := Round(NodeSize * ScaleFactor);

      if I = 0 then
        Node.Left := NodeGap + exptend
      else
        Node.Left := g_core.nodes.Nodes[I - 1].Left + NodeGap + Node.Width;

      with Node do
      begin
        Top := ClientCenterY;
        Center := true;
        Transparent := true;
        Stretch := true;

        original_size.cx := Node.Width;
        original_size.cy := Node.height;
        center_point.x := Node.Left + Node.Width div 2;
        center_point.y := Node.top + Node.height div 2;

      end;

    end;
  end;
  if NodeCount > 0 then
    Self.Width := g_core.nodes.Nodes[NodeCount - 1].Left + g_core.nodes.Nodes[NodeCount - 1].Width + NodeGap + exptend;

end;

procedure TForm1.adjust_node_layout(screenHeight: integer);
begin
  if finish_layout then
  begin
    try
      finish_layout := false;
      if hoverLabel then
      begin
        hoverLabel := false;
        label1.Visible := false;
      end;
    // 计算和定位节点
      form1.PureCalculateAndPositionNodes();

    // 窗体水平居中屏幕
      form1.Left := Screen.Width div 2 - form1.Width div 2;

    //顶部
      if form1.Top < top_snap_distance then
      begin
        form1.Top := -(form1.Height - visible_height) + 50;

        form1.Left := Screen.Width div 2 - form1.Width div 2;
        restore_state();
        FormPosition := [fpTop];
        g_core.utils.SetTaskbarAutoHide(false);
      end
    //底部
      else if form1.top + form1.height > screenHeight then
      begin
        g_core.utils.SetTaskbarAutoHide(true);
        form1.Top := screenHeight - form1.Height + 130;
        form1.Left := Screen.Width div 2 - form1.Width div 2;
        FormPosition := [fpBottom]; // 设置位置为底部
      end
      //中间
      else
      begin
        FormPosition := [];

        g_core.utils.SetTaskbarAutoHide(false);              //隐藏任务栏
      end;
    finally
      finish_layout := true;
    end;

  end;
end;

procedure TForm1.FormShow(Sender: TObject);
begin

  ScaleFactor := 1.0;
  UpdateTheme(Handle);
  takeappico();

  load_plug();
  Initialize_form();

  HideFromTaskbarAndAltTab(Handle);

  nodeimgload();
  ConfigureLayout();

  add_json('startx', 'Start Button.png', 'startx', '开始菜单', True, nil);

  show_side_form();

  hwndMonitor := Handle;
  hMouseHook := SetWindowsHookEx(WH_MOUSE_LL, @LowLevelMouseProc, 0, 0);

  finish_layout := true;
  //   监控 窗口创建   焦点
  SetCBTHook(Handle);

  var processId: DWORD;
  //监控 窗口发生变化
  GetWindowThreadProcessId(hwndMonitor, processId);
  heventHook := SetWinEventHook(EVENT_OBJECT_LOCATIONCHANGE, EVENT_OBJECT_LOCATIONCHANGE, 0, @WinEventProc, processId, 0, WINEVENT_OUTOFCONTEXT);
  SetWindowCornerPreference(Handle);

  SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);

  dllmaincpp();

  SetTimer(Handle, 1101, 2000, @global_hook);

  InstallMouseHook();

  adjust_node_layout(Screen.WorkAreaHeight);
end;

procedure TForm1.smooth_layout_adjustment(Sender: TObject);
var
  NewFormWidth: Integer;
  j: Integer;
  Delta: Integer;
  ExpDelta: Double;
  rate: Double;
begin
  var count := g_core.nodes.count;
  var tnodes := g_core.nodes.Nodes;
  var node_gap := g_core.nodes.node_gap;
  NewFormWidth := tnodes[count - 1].Left + tnodes[count - 1].Width + node_gap + exptend;
  // 计算移动的增量
  Delta := NewFormWidth - Width;

  if node_at_cursor <> nil then
  begin
     // 调整 rate 的值以控制缓动效果的强度
    rate := 0.1;  // 值越小，缓动越慢

    // 使用指数函数计算 ExpDelta
    ExpDelta := Delta * (1 - Exp(-rate));

    SetBounds(Left - Round(ExpDelta) div 2, Top, Width + Round(ExpDelta), Height);

    for j := 0 to count - 1 do
    begin
      var inner_node := tnodes[j];
      if j = 0 then
        inner_node.Left := +exptend
      else
        inner_node.Left := tnodes[j - 1].Left + tnodes[j - 1].Width + node_gap;
    end;
  end;
end;

procedure TForm1.AdjustNodeSize(Node: _node; Rate: Double);
var
  NewWidth, NewHeight: Integer;
begin
  if Node = nil then
    exit;
//        Rate := 0.5 * (1 - Cos(Pi * Rate));
  NewWidth := Round(Node.Original_Size.cx * (1 + Rate));
  NewHeight := Round(Node.Original_Size.cy * (1 + Rate));

  Node.center_point.x := Node.Left + Node.Width div 2;
  Node.center_point.y := Node.Top + Node.Height div 2;
//
//// 设置当前节点的新尺寸和位置，保持中心点不变
//  Node.SetBounds(Node.center_point.x - NewWidth div 2, Node.center_point.y - NewHeight div 2, NewWidth, NewHeight);


  if top < top_snap_distance + 100 then
  begin

    Node.Width := NewWidth; // Floor(Node.original_size.cx * 1 );
    Node.height := NewHeight; // Floor(Node.original_size.cx * 1 );
    Node.Left := Node.Left - Floor((Node.Width - Node.original_size.cx) * Rate) - 6; //:= Node.Left ;

  end
  else
  begin

      // 调整顶部位置而不改变底部位置
    var newTop := Node.Top - (NewHeight - Node.Height);

    Node.SetBounds(Node.center_point.x - NewWidth div 2, newTop, NewWidth, NewHeight);
  end;

end;

procedure TForm1.FormCreate(Sender: TObject);
begin
          //目的 前端窗口是不是它

  SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) or WS_EX_LAYERED);

  SetLayeredWindowAttributes(Handle, $000EADEE, 0, LWA_COLORKEY);

end;

procedure RemoveMouseHook;
begin
  if hMouseHook <> 0 then
  begin
    UnhookWindowsHookEx(hMouseHook);
    hMouseHook := 0;
  end;
  if heventHook <> 0 then
  begin

    UnhookWinEvent(heventHook);
    heventHook := 0;
  end;

end;

procedure TForm1.FormDestroy(Sender: TObject);
var
  v: TSettingItem;
  SettingsObj: TJSONObject;
begin
  RemoveMouseHook();
  UninstallMouseHook();

  SettingsObj := g_jsonobj.GetValue('settings') as TJSONObject;
  if SettingsObj = nil then
    Exit;

  for var KeyValuePair in g_core.json.Settings do
  begin
    if (SettingsObj.GetValue(KeyValuePair.key) = nil) then
    begin
      if (KeyValuePair.Value.Is_path_valid) then
        add_or_update(SettingsObj, KeyValuePair.key, KeyValuePair.Value.image_file_name, KeyValuePair.Value.FilePath, KeyValuePair.Value._tip);
    end;

  end;

  if g_core.nodes.Nodes <> nil then
    for var Node in g_core.nodes.Nodes do
    begin

      FreeAndNil(Node);
    end;
  set_json_value('config', 'left', left.ToString);

  set_json_value('config', 'top', top.ToString);

  main_background.Free;
  UnregisterHotKey(Handle, 119);
  try
    SaveJSONToFile(ExtractFilePath(ParamStr(0)) + 'cfg.json', g_jsonobj);
  except

  end;
end;

procedure TForm1.form_mouse_wheel(WheelMsg: TWMMouseWheel);
begin
  if g_core.nodes.is_configuring then
    Exit;
  var i1 := g_core.json.Config.nodesize;

  if WheelMsg.WheelDelta > 0 then
    i1 := round(1.1 * i1)
  else
    i1 := round(i1 * 0.9);
  g_core.nodes.node_size := i1;
  set_nodesize_value(g_core.json, i1);
  ConfigureLayout();

end;

procedure TForm1.img_bgMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbLeft) then
    move_windows(Handle);

end;

procedure TForm1.move_windows(h: thandle);
begin

  ReleaseCapture;
  SendMessage(h, WM_SYSCOMMAND, SC_MOVE + HTCaption, 0);

end;

procedure TForm1.ConfigureLayout();
begin
  g_core.nodes.is_configuring := False;

  CalculateAndPositionNodes();
  var PrimaryMonitorHeight := Screen.monitors[0].height;

  if Form1.top > PrimaryMonitorHeight then
    Form1.top := 0;

  restore_state();

end;

end.

