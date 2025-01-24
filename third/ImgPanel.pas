unit ImgPanel;

interface

uses
    Types, ExtCtrls, Windows, Messages, Graphics, Controls, Classes, SysUtils;
type
     ttimenotify = procedure of object;
    TImgPanel = class(TCustomPanel)
    private
           FPic: TPicture;
    FHotPic: TPicture;
    FTmpPic: TPicture;
           ftnotify: ttimenotify;
        FTransparent : Boolean;
        FAutoSize : Boolean;
        FCaptionPosX: Integer;
        FCaptionPosY: Integer;

        FLastDrawCaptionRect : TRect;
        FStretch: boolean;
        FTitleBar: boolean;
             G_Buf : TBitmap;
        procedure ApplyAutoSize();
        procedure ApplyTransparent();
        procedure SetPicture(const Value: TPicture);
        procedure SetAutoSize(const Value: Boolean); reintroduce;
        procedure SetCaptionPosX(const Value: Integer);
        procedure SetCaptionPosY(const Value: Integer);
        procedure CMTEXTCHANGED(var Msg : TMessage); message CM_TEXTCHANGED;
        procedure WMERASEBKGND(var Msg : TMessage); message WM_ERASEBKGND;
        procedure SetStretch(const Value: boolean);
        procedure SetTitleBar(const Value: boolean);
    procedure SetHotPic(const Value: TPicture);

      private
         Fchanged: Boolean;
          procedure CMMouseEnter(var message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var message: TMessage); message CM_MOUSELEAVE;
    protected
        procedure Paint(); override;
        procedure ClearPanel(); virtual;
        procedure RepaintText(Rect : TRect); virtual;
        procedure PictureChanged(Sender: TObject); virtual;
        procedure SetTransparent(const Value: Boolean); virtual;
        procedure Resize(); override;

        procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;

    public
         extendA,extendB:string;
        constructor Create(AOwner: TComponent); override;
        destructor Destroy(); override;
        property CaptionPosX : Integer read FCaptionPosX write SetCaptionPosX;
        property CaptionPosY : Integer read FCaptionPosY write SetCaptionPosY;
        private
    FTransColor: TColor;
           procedure SetTransColor(const Value: TColor);
    procedure setftime(v: ttimenotify);
     published
    property ontnotify: ttimenotify read ftnotify write setftime;
        property TransColor: TColor read FTransColor write SetTransColor;
        property BevelOuter;
        property BevelInner;
        property BiDiMode;
        property BorderWidth;
        property Anchors;

    property Pic: TPicture read FPic write SetPicture;
    property HotPic: TPicture read FHotPic write SetHotPic;
        property Transparent : Boolean Read FTransparent Write SetTransparent default false;
        property AutoSize : Boolean Read FAutoSize Write SetAutoSize;
        property Stretch :boolean read FStretch write SetStretch;
        property Parentfont;
        property Alignment;
        property Align;
        property Font;
        property TabStop;
        property TabOrder;
        property Caption;
        property Color;
        property Visible;
        property PopupMenu;

         property OnMouseLeave;
    property OnMouseEnter;

        property ParentColor;
        property OnCanResize;
        property OnClick;
        property OnConstrainedResize;
        property OnDockDrop;
        property OnDockOver;
        property OnDblClick;
        property OnDragDrop;
        property OnDragOver;
        property OnEndDock;
        property OnEndDrag;
        property OnEnter;
        property OnExit;
        property OnGetSiteInfo;
        property OnMouseDown;
        property OnMouseMove;
        property OnMouseUp;
        property OnResize;
        property OnStartDock;
        property OnStartDrag;
        property OnUnDock;
        property TitleBar :boolean read FTitleBar write SetTitleBar;

    end;

implementation

{ TsuiCustomPanel }
procedure DoTrans(Canvas : TCanvas; Control : TWinControl);
var
    DC : HDC;
    SaveIndex : HDC;
    Position: TPoint;
begin
    if Control.Parent <> nil then
    begin
{$R-}
        DC := Canvas.Handle;
        SaveIndex := SaveDC(DC);
        GetViewportOrgEx(DC, Position);
        SetViewportOrgEx(DC, Position.X - Control.Left, Position.Y - Control.Top, nil);
        IntersectClipRect(DC, 0, 0, Control.Parent.ClientWidth, Control.Parent.ClientHeight);
        Control.Parent.Perform(WM_ERASEBKGND, DC, 0);
        Control.Parent.Perform(WM_PAINT, DC, 0);
        RestoreDC(DC, SaveIndex);
{$R+}
    end;
end;
  procedure TImgPanel.SetHotPic(const Value: TPicture);
begin
  FHotPic.Assign(Value);
end;
procedure TImgPanel.ApplyAutoSize;
begin
    if FAutoSize then
    begin
        if (
            (Align <> alTop) and
            (Align <> alBottom) and
            (Align <> alClient)
        ) then
            Width := FPic.Width;

        if (
            (Align <> alLeft) and
            (Align <> alRight) and
            (Align <> alClient)
        ) then
            Height := FPic.Height;
    end;
end;

procedure TImgPanel.ApplyTransparent;
begin
    if FPic.Graphic.Transparent <> FTransparent then
        FPic.Graphic.Transparent := FTransparent;
end;

procedure TImgPanel.ClearPanel;
begin
    Canvas.Brush.Color := Color;

    if ParentWindow <> 0 then
        Canvas.FillRect(ClientRect);
end;

procedure TImgPanel.CMMouseEnter(var message: TMessage);
begin
   try
    if Not(csDesigning in ComponentState) then
    begin
      if Assigned(OnMouseEnter) then
        OnMouseEnter(self);

      if FPic.Graphic <> nil then
      begin
        FTmpPic.Assign(FPic);
        Fchanged := false;
        if HotPic.Graphic <> nil then
          Pic.Assign(HotPic);
      end;
    end;
  except
  end;

end;

procedure TImgPanel.CMMouseLeave(var message: TMessage);
begin
    try
    if Not(csDesigning in ComponentState) then
    begin
      if Assigned(OnMouseLeave) then
        OnMouseLeave(self);

      if FTmpPic.Graphic <> nil then
        Pic.Assign(FTmpPic);
    end;
  except
  end;

end;

procedure TImgPanel.CMTEXTCHANGED(var Msg: TMessage);
begin
    RepaintText(FLastDrawCaptionRect);
    Repaint();
end;

constructor TImgPanel.Create(AOwner: TComponent);
begin
    inherited Create(AOwner);
   DoubleBuffered:=true;

    FPic := TPicture.Create();
  FHotPic := TPicture.Create;
  FTmpPic := TPicture.Create;

    ASSERT(FPic <> nil);

    FPic.OnChange := PictureChanged;
    FCaptionPosX := -1;
    FCaptionPosY := -1;

    BevelInner := bvNone;
    BevelOuter := bvNone;

      Fchanged := false;
  G_Buf := TBitmap.Create;
//    Repaint();

end;

destructor TImgPanel.Destroy;
begin
 if FPic <> nil then
    FreeAndNil(FPic);

  if FHotPic <> nil then
    FreeAndNil(FHotPic);
  if FTmpPic <> nil then
    FreeAndNil(FTmpPic);
    if G_Buf<>nil then
    FreeAndNil(G_Buf);
  G_Buf.Free;;

    inherited;
end;

procedure TImgPanel.Paint;
var
    uDrawTextFlag : Cardinal;
    Rect : TRect;
 var

  Rgn: HRGN;
begin

    g_Buf.Height := Height;
    g_Buf.Width := Width;

    if FTransparent then
        DoTrans(g_Buf.Canvas, self);

    if Assigned(FPic.Graphic) then
    begin
        if Stretch then
            g_Buf.Canvas.StretchDraw(ClientRect, FPic.Graphic)
        else
            g_Buf.Canvas.Draw(0, 0, FPic.Graphic);
    end
    else if not FTransparent then
    begin
        g_Buf.Canvas.Brush.Color := Color;
        g_Buf.Canvas.FillRect(ClientRect);
    end;

    g_Buf.Canvas.Brush.Style := bsClear;

    if Trim(Caption) <> '' then
    begin
        g_Buf.Canvas.Font := Font;

        if (FCaptionPosX <> -1) and (FCaptionPosY <> -1) then
        begin
            g_Buf.Canvas.TextOut(FCaptionPosX, FCaptionPosY, Caption);
            FLastDrawCaptionRect := Classes.Rect(
                FCaptionPosX,
                FCaptionPosY,
                FCaptionPosX + g_Buf.Canvas.TextWidth(Caption),
                FCaptionPosY + g_Buf.Canvas.TextWidth(Caption)
            );
        end
        else
        begin
            Rect := ClientRect;
            uDrawTextFlag := DT_CENTER;
            if Alignment = taRightJustify then
                uDrawTextFlag := DT_RIGHT
            else if Alignment = taLeftJustify then
                uDrawTextFlag := DT_LEFT;
            DrawText(g_Buf.Canvas.Handle, PChar(Caption), -1, Rect, uDrawTextFlag or DT_SINGLELINE or DT_VCENTER);
            FLastDrawCaptionRect := Rect;
        end;
    end;

    BitBlt(Canvas.Handle, 0, 0, Width, Height, g_Buf.Canvas.Handle, 0, 0, SRCCOPY);

end;

procedure TImgPanel.PictureChanged(Sender: TObject);
begin
    if FPic.Graphic <> nil then
    begin
        if FAutoSize then
            ApplyAutoSize();
        ApplyTransparent();
    end;

    ClearPanel();
    RePaint();
end;

procedure TImgPanel.RepaintText(Rect: TRect);
begin
    // not implete
end;

procedure TImgPanel.Resize;
begin
    inherited;

    Repaint();
end;

procedure TImgPanel.SetAutoSize(const Value: Boolean);
begin
    FAutoSize := Value;

    if FPic.Graphic <> nil then
        ApplyAutoSize();
end;

procedure TImgPanel.SetCaptionPosX(const Value: Integer);
begin
    FCaptionPosX := Value;

    RePaint();
end;

procedure TImgPanel.SetCaptionPosY(const Value: Integer);
begin
    FCaptionPosY := Value;

    RePaint();
end;

procedure TImgPanel.SetPicture(const Value: TPicture);
begin
    FPic.Assign(Value);

    ClearPanel();
    Repaint();
end;
    procedure TImgPanel.setftime(v: ttimenotify);
begin
  ftnotify := v;
end;
procedure TImgPanel.SetStretch(const Value: boolean);
begin
  FStretch := Value;
end;

procedure TImgPanel.SetTitleBar(const Value: boolean);
begin
  FTitleBar := Value;
end;

procedure TImgPanel.SetTransColor(const Value: TColor);
begin
     FTransColor := Value;
end;

procedure TImgPanel.SetTransparent(const Value: Boolean);
begin
    FTransparent := Value;

    if FPic.Graphic <> nil then
        ApplyTransparent();
    Repaint();
end;

procedure TImgPanel.WMERASEBKGND(var Msg: TMessage);
begin
     Msg.Result := 1
end;

procedure TImgPanel.WMNCHitTest(var Message: TWMNCHitTest);
var
    pt:tpoint;
    pt1:tpoint;
begin
  inherited;
    {if FTitleBar then
    begin
        pt.X:=Message.XPos;
        pt.Y:=Message.YPos;
        pt:=ScreenToClient(pt);

        if ptInRect(ClientRect,pt) then
        begin
            Message.result:=HTCAPTION ;
        end;
    end;  }

end;

end.