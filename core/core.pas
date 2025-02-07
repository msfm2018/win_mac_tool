unit core;

interface

uses
  shellapi, classes, winapi.windows, Graphics, SysUtils, messages, TLHelp32,
  Vcl.Imaging.pngimage, System.IniFiles, Registry, forms, Dwmapi, u_json,
  vcl.controls, ComObj, System.Generics.Collections, utils, ConfigurationForm,
  Winapi.PsAPI, System.SyncObjs, vcl.ExtCtrls, math;

const
  WM_disActive = WM_USER + 1;
  WM_SYSDATE_MESSAGE = WM_USER + 1030;
  WM_defaultStart_MESSAGE = WM_USER + 1031;
  WM_clipboard = WM_USER + 1041;

type
  _node = class(TImage)
  public
    key: string;
    id: Integer;
    _tip: string;
    file_path: string;

    original_size: TSize;
    center_point: TPoint;
  end;

  t_node_container = record
    count: Integer;
    Nodes: array of _node;
    is_configuring: Boolean;
    node_size: Integer;
    node_gap: Integer;
  end;

  t_utils = record
  public

    procedure SetTaskbarAutoHide(autoHide: Boolean);

    procedure CopyFileToFolder(const SourceFile, DestinationFolder: string);

  public
    procedure launch_app(const Path: string; param: string = '');

    procedure auto_run;
    procedure init_background(img: TImage; obj: tform; src: string);
    function rate(a, b: double): Double;

  end;

  t_core_class = class
  public
    json: TMySettings;
    utils: t_utils;
    nodes: t_node_container;
    ImageCache: TDictionary<string, timage>;  // New cache dictionary
  private
    object_map: TDictionary<string, TObject>;
  public
    function find_object_by_name(const Name_: string): TObject;
  end;

type
  TFormPosition = (fpTop, fpBottom); // 定义枚举类型，包含顶部和底部

  TFormPositions = set of TFormPosition; // 定义一个集合类型，表示可以包含顶部、底部或二者

type
  MSLLHOOKSTRUCT = record
    pt: TPoint;  // 鼠标位置
    mouseData: DWORD;  // 鼠标按钮状态等
    flags: DWORD;  // 标志
    time: DWORD;  // 事件时间
    dwExtraInfo: ULONG_PTR;  // 附加信息
  end;

  PMSLLHOOKSTRUCT = ^MSLLHOOKSTRUCT;  // 指向 MSLLHOOKSTRUCT 的指针

const
  visible_height = 19;       // 代表可见高度
  top_snap_distance = 40;   // 吸附距离
  exptend = 60;

function BringWindowToFront(const WindowTitle: string): boolean;

procedure remove_json(Key: string);

procedure add_json(Key, image_file_name, FilePath, tool_tip: string; Is_path_valid: boolean; memory: TMemoryStream);

procedure SimulateCtrlEsc;

procedure EmptyRecycleBin;



//    天气相关
procedure StartNginx;

procedure StopNginx;

procedure RegisterDLL;

procedure UnregisterDLL;

procedure SetWindowCornerPreference(hWnd: hWnd);

var
  g_core: t_core_class;
  original_task_list: TStringList;
  task_list: TStringList;
  app_path: string;

implementation

const
  SPI_SETDESKWALLPAPER = $0014;
  SPI_GETDESKWALLPAPER = $0073;
  SPI_GETDESKPATTERN = $0020;
  SPI_SETDESKPATTERN = $0015;
  SPI_SETWORKAREA = $002F;
  SPI_GETWORKAREA = $0030;

procedure RegisterDLL;
var
  DllPath: string;
begin
  // 获取当前程序目录下的 DLL 完整路径
  DllPath := ExtractFilePath(ParamStr(0)) + 'weather\com\ep_com_host.dll';

  // 检查 DLL 文件是否存在
  if not FileExists(DllPath) then
  begin
//    ShowMessage('DLL 文件不存在: ' + DllPath);
    Exit;
  end;

  // 通过 ShellExecute 调用 regsvr32 注册 DLL
  if ShellExecute(0, 'open', 'regsvr32', PChar('/s "' + DllPath + '"'), nil, SW_HIDE) > 32 then
  begin
    TThread.CreateAnonymousThread(
      procedure
      begin

        Sleep(1000);
        dll_weather();
      end).Start;

  end;

end;

procedure UnregisterDLL;
var
  DllPath: string;
begin
  // 获取当前程序目录下的 DLL 完整路径
  DllPath := ExtractFilePath(ParamStr(0)) + 'weather\com\ep_com_host.dll';

  dll_unweather();
  // 通过 ShellExecute 调用 regsvr32 注销 DLL
  ShellExecute(0, 'open', 'regsvr32', PChar('/u /s "' + DllPath + '"'), nil, SW_HIDE);
end;

procedure StartNginx;
var
  NginxPath: string;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  Success: Boolean;
  WorkingDir: string;
  CommandLine: string;
begin
  // 设置 nginx.exe 的路径，根据实际情况修改
  NginxPath := ExtractFilePath(ParamStr(0)) + 'nginx-1.27.4\nginx.exe';
  WorkingDir := ExtractFilePath(ParamStr(0)) + 'nginx-1.27.4';

  if FileExists(NginxPath) then
  begin
    FillChar(StartupInfo, SizeOf(StartupInfo), 0);
    StartupInfo.cb := SizeOf(StartupInfo);
    FillChar(ProcessInfo, SizeOf(ProcessInfo), 0);

    // 构造命令行参数
    CommandLine := Format('"%s" -p "%s"', [NginxPath, WorkingDir]);

    // 启动 nginx.exe
    Success := CreateProcess(nil, PChar(CommandLine), nil, nil, False, 0, nil, PChar(WorkingDir), StartupInfo, ProcessInfo);
    if Success then
    begin
      // 关闭进程和线程句柄
      CloseHandle(ProcessInfo.hProcess);
      CloseHandle(ProcessInfo.hThread);
    end
    else
    begin
//      ShowMessage('无法启动 Nginx: ' + SysErrorMessage(GetLastError));
    end;
  end
  else
  begin
//    ShowMessage('Nginx 可执行文件未找到: ' + NginxPath);
  end;
end;

procedure StopNginx;
var
  SnapshotHandle: THandle;
  ProcessEntry: TProcessEntry32;
  ProcessHandle: THandle;
begin
  // 创建进程快照
  SnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if SnapshotHandle <> INVALID_HANDLE_VALUE then
  begin
    try
      // 初始化进程入口结构体
      ProcessEntry.dwSize := SizeOf(TProcessEntry32);
      // 获取第一个进程信息
      if Process32First(SnapshotHandle, ProcessEntry) then
      begin
        repeat
          // 检查进程名称是否为 nginx.exe
          if AnsiSameText(ExtractFileName(ProcessEntry.szExeFile), 'nginx.exe') then
          begin
            // 打开进程句柄
            ProcessHandle := OpenProcess(PROCESS_TERMINATE, False, ProcessEntry.th32ProcessID);
            if ProcessHandle <> 0 then
            begin
              try
                // 终止进程
                if not TerminateProcess(ProcessHandle, 0) then
                begin
//                  ShowMessage('无法终止 Nginx 进程: ' + SysErrorMessage(GetLastError));
                end;
              finally
                // 关闭进程句柄
                CloseHandle(ProcessHandle);
              end;
            end;
          end;
        until not Process32Next(SnapshotHandle, ProcessEntry);
      end;
    finally
      // 关闭进程快照句柄
      CloseHandle(SnapshotHandle);
    end;
  end;
end;

procedure SetWindowCornerPreference(hWnd: hWnd);
var
  cornerPreference: Integer;
begin
  cornerPreference := DWMWCP_ROUND;  // 设置为圆角

  // 调用 DwmSetWindowAttribute API 设置窗口的角落偏好
  if DwmSetWindowAttribute(hWnd, DWMWA_WINDOW_CORNER_PREFERENCE, @cornerPreference, SizeOf(cornerPreference)) <> S_OK then
  begin

  end;
end;

//清空回收站
procedure EmptyRecycleBin;
begin

  SHEmptyRecycleBin(0, nil, SHERB_NOCONFIRMATION or SHERB_NOPROGRESSUI or SHERB_NOSOUND);
end;

procedure SimulateCtrlEsc;
begin
  OpenStartOnMonitor();

end;

procedure t_utils.CopyFileToFolder(const SourceFile, DestinationFolder: string);
var
  DestinationFile: string;
begin
  DestinationFile := IncludeTrailingPathDelimiter(DestinationFolder) + ExtractFileName(SourceFile);

  if SourceFile <> DestinationFile then
  begin
    if not CopyFile(PChar(SourceFile), PChar(DestinationFile), False) then
    begin
      RaiseLastOSError;  // 抛出最后一个操作系统错误
    end;
  end;
end;

function BringWindowToFront(const WindowTitle: string): boolean;
var
  hWnd: thandle;
begin
  result := false;
  hWnd := FindWindow(nil, PChar(WindowTitle));

  if hWnd <> 0 then
  begin
    if IsIconic(hWnd) then
    begin
      ShowWindow(hWnd, SW_RESTORE);
    end;
    SetForegroundWindow(hWnd);
    Result := True;
  end;
end;

procedure t_utils.auto_run;
begin
  try
    var Reg := TRegistry.Create;
    try
      Reg.RootKey := HKEY_CURRENT_USER;
      if Reg.OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Run', True) then
        Reg.WriteString('winbaros', ExpandFileName(ParamStr(0)));
    finally
      Reg.Free;
    end;
  except

  end;
end;

procedure t_utils.SetTaskbarAutoHide(autoHide: Boolean);
var
  taskbar: hWnd;
  abd: APPBARDATA;
begin
  taskbar := FindWindow('Shell_TrayWnd', nil);
  if taskbar <> 0 then
  begin
    abd.cbSize := SizeOf(APPBARDATA);
//    abd.hWnd := taskbar;
    if autoHide then
      abd.lParam := ABS_AUTOHIDE
    else
      abd.lParam := ABS_ALWAYSONTOP;

    SHAppBarMessage(ABM_SETSTATE, abd);
  end;
end;

procedure t_utils.init_background(img: TImage; obj: tform; src: string);
begin
  img.Parent := obj;
  img.Align := alClient;
  img.Transparent := true;
  img.Stretch := true;
//  img.Anchors:=[akleft,akright];

  img.Picture.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'img\' + src);
end;

procedure t_utils.launch_app(const Path: string; param: string = '');
begin
  if Path.Trim = '' then
    Exit;
  if param = '' then
  begin
    if Path.Contains('https') or Path.Contains('http') or Path.Contains('.html') or Path.Contains('.htm') then
      ShellExecute(Application.Handle, nil, PChar(Path), nil, nil, SW_SHOWNORMAL)
    else
      ShellExecute(0, 'open', PChar(Path), nil, nil, SW_SHOW);
  end
  else
  begin

    ShellExecute(0, 'open', PChar(Path), PChar(param), nil, SW_SHOWNORMAL);
  end;
end;

function t_utils.rate(a, b: double): Double;
begin
  result := Exp(-sqrt(a * a + b * b) / (63.82 * 5));
end;

function t_core_class.find_object_by_name(const Name_: string): TObject;
begin
  if object_map.TryGetValue(Name_, Result) then
    Exit(Result)
  else
    Result := nil;
end;
       // 添加数据的过程

procedure add_json(Key, image_file_name, FilePath, tool_tip: string; Is_path_valid: boolean; memory: TMemoryStream);
var
  SettingItem: TSettingItem;
begin
  SettingItem.image_file_name := image_file_name;
  SettingItem.FilePath := FilePath;
  SettingItem._tip := tool_tip;
  SettingItem.Is_path_valid := Is_path_valid;
  SettingItem.memory_image := memory;

  g_core.json.Settings.AddOrSetValue(Key, SettingItem);
end;

procedure remove_json(Key: string);
var
  SettingItem: TSettingItem;
begin
  if g_core.json.Settings.ContainsKey(Key) then
  begin
    SettingItem := g_core.json.Settings[Key];
    if not SettingItem.Is_path_valid then
    begin
      if Assigned(SettingItem.memory_image) then
      begin
        SettingItem.memory_image.Free;
        SettingItem.memory_image := nil;
      end;
    end;
    g_core.json.Settings.Remove(Key);
  end;

end;

initialization
  g_core := t_core_class.Create;
  g_core.ImageCache := TDictionary<string, timage>.Create;
  app_path := ExtractFilePath(ParamStr(0));
  g_jsonobj := load_json_from_file(app_path + 'cfg.json');

  parse_json(g_jsonobj, g_core.json);

  g_core.object_map := TDictionary<string, TObject>.Create;
  g_core.object_map.AddOrSetValue('cfgForm', TCfgForm.Create(nil));

  g_core.utils.auto_run;
  original_task_list := TStringList.Create;
  task_list := TStringList.Create;

  try
    g_core.nodes.node_size := g_core.json.Config.nodesize;
  except
    g_core.nodes.node_size := 64;
  end;
  g_core.nodes.node_gap := Round(g_core.nodes.node_size / 40);


finalization
  var Key: string;

  // 释放 TDictionary 中的 TImage 对象
  for Key in g_core.ImageCache.Keys do
    g_core.ImageCache[Key].Free;

  // 释放 TDictionary 对象
  g_core.ImageCache.Free;

  g_core.object_map.Free;

  g_core.Free;
  original_task_list.free;
  task_list.free;

  g_jsonobj.Free;
  g_core.json.Settings.Free;

end.

