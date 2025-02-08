unit utils;

interface
 uses
  Winapi.Windows;
const
  dllName = './Project7.dll';
  mousehook = './Project3.dll';
  injectName = './global-inject.dll';

function SystemShutdown(reboot: Boolean): boolean; stdcall; external dllName;

         //开始按钮
function OpenStartOnMonitor(): boolean; stdcall; external dllName;

         //窗口钩子
function SetCBTHook(h: THandle): boolean; stdcall; external dllName;

function HideFromTaskbarAndAltTab(hwnd: thandle): boolean; stdcall; external dllName;

     //生成圆形png
procedure write_png_with_text(const filename: pansichar; const text: pansichar;cmode:integer); stdcall; external dllName;



  //    server for system time
function dllmaincpp(): Integer; stdcall; external injectName;

function HandleNewProcessesExport(): Integer; stdcall; external injectName;

procedure InstallMouseHook(); stdcall; external mousehook;

procedure UninstallMouseHook(); stdcall; external mousehook;
   ///应用程序图标
function GetFileIcon1(const extension: pchar): HICON; stdcall; external './startMenuApps.dll';

//得到应用程序
function GetStartMenuApps: pchar; cdecl; external './startMenuApps.dll';

procedure takeappico; cdecl; external './startMenuApps.dll';

// 天气预报

 procedure dll_weather; stdcall; external './weather/ConsoleApplication5.dll';

procedure dll_unweather; stdcall; external './weather/ConsoleApplication5.dll';

procedure weather_show; stdcall; external './weather/ConsoleApplication5.dll';

procedure weather_hide; stdcall; external './weather/ConsoleApplication5.dll';


 function RegisterCOM:boolean; stdcall; external './weather/ConsoleApplication5.dll';
// function UnregisterCOM:boolean; stdcall; external './weather/ConsoleApplication5.dll';



implementation

end.

