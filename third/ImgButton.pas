unit ImgButton;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls,
  Vcl.Imaging.GIFImg, Dialogs, Buttons, Vcl.Imaging.pngImage;  // Ensure to include the pngImage unit

type
  TImgButton = class(TGraphicControl)
  private
    FBmp: TPngImage;              // Explicitly use TPngImage for PNG images
    FBmp1: TPngImage;             // Another TPngImage for hover state
    FMouseInControl: Boolean;
    FDown: boolean;
    FFreeImage: boolean;
    procedure OnMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure OnMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure SetImage(const Value: TPngImage);  // Set PNG image
    procedure SetImage1(const Value: TPngImage); // Set PNG image for hover effect
    procedure SetFreeImage(const Value: boolean);

  protected
    procedure Paint; override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property Image: TPngImage read FBmp write SetImage;
    property Image1: TPngImage read FBmp1 write SetImage1;
  published
    property FreeImage: boolean read FFreeImage write SetFreeImage;
    property Anchors;
    property OnClick;
  end;

procedure Register;
implementation

{ TImgButton }


procedure Register;
begin
  RegisterComponents('Samples', [TImgButton]);
end;


constructor TImgButton.Create(AOwner: TComponent);
begin
  inherited;
  FreeImage := false;
  FBmp := TPngImage.Create;  // Create a new instance for image
  FBmp1 := TPngImage.Create; // Create a second instance for hover image
end;

destructor TImgButton.Destroy;
begin
  if FFreeImage then
  begin
    FBmp.Free;   // Free the image if FreeImage is true
    FBmp1.Free;  // Free the second image
  end;
  inherited;
end;

procedure TImgButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Button = mbLeft then
  begin
    FDown := true;
    Invalidate;
  end;
end;

procedure TImgButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Button = mbLeft then
  begin
    FDown := false;
    Invalidate;
  end;
end;

procedure TImgButton.OnMouseEnter(var Msg: TMessage);
begin
  if not FMouseInControl and Enabled then
  begin
    FMouseInControl := True;
    Repaint;
  end;
end;

procedure TImgButton.OnMouseLeave(var Msg: TMessage);
begin
  if FMouseInControl and Enabled then
  begin
    FMouseInControl := False;
    Invalidate;
  end;
end;

//procedure TImgButton.Paint;
//var
//  x, y: integer;
//begin
//  inherited;
//  if csDesigning in ComponentState then
//  begin
//    with Canvas do
//    begin
//      Pen.Style := psDash;
//      Brush.Style := bsClear;
//      Rectangle(0, 0, Width, Height);
//    end;
//  end;
//
//  x := 0;
//  y := 0;
//
//  if FDown then
//  begin
//    x := 1;
//    y := 1;
//  end;
//
//  Canvas.Lock;
//  if (FBmp <> nil) and (FBmp1 <> nil) then
//  begin
//    if FMouseInControl then
//      Canvas.Draw(x, y, FBmp)
//    else
//      Canvas.Draw(x, y, FBmp1);
//  end;
//  Canvas.Unlock;
//end;

procedure TImgButton.Paint;
var
  x, y: integer;
begin
  inherited;
  if csDesigning in ComponentState then
  begin
    with Canvas do
    begin
      Pen.Style := psDash;
      Brush.Style := bsClear;
      Rectangle(0, 0, Width, Height);
    end;
  end;

  x := 0;
  y := 0;

  if FDown then
  begin
    x := 1;
    y := 1;
  end;

  Canvas.Lock;
  if (FBmp <> nil) and (FBmp1 <> nil) then
  begin
    if FMouseInControl then
      Canvas.StretchDraw(Rect(x, y, Width, Height), FBmp)  // ʹ�� StretchDraw ������ͼƬ
    else
      Canvas.StretchDraw(Rect(x, y, Width, Height), FBmp1); // ʹ�� StretchDraw ������ͼƬ
  end;
  Canvas.Unlock;
end;


procedure TImgButton.SetFreeImage(const Value: boolean);
begin
  FFreeImage := Value;
end;

procedure TImgButton.SetImage(const Value: TPngImage);
begin
  if FFreeImage and (FBmp <> nil) then
    FBmp.Free;
  FBmp := Value;
  Invalidate;
end;

procedure TImgButton.SetImage1(const Value: TPngImage);
begin
  if FFreeImage and (FBmp1 <> nil) then
    FBmp1.Free;
  FBmp1 := Value;
  Invalidate;
end;

end.

