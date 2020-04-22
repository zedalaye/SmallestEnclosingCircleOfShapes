unit SmallestCircle.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Generics.Collections, System.Math.Vectors, System.Math,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Objects, FMX.Ani;

type
  TShape = class
    Rect: TRectF;
    Position: TPointF;
    Destination: TPointF;
    TimeToLive: Single;
    Angle: Single;

    constructor Create(ARect: TRectF);

    { Renders the concrete TShape as TPathData }
    procedure DrawPathData(P: TPathData); virtual; abstract;

    { Render rotated/positionned shapes }
    function PathData: TPathData; virtual;

    { Smallest Circle Algorithm process an array of TPointF }
    function Polygon: TPolygon;

    { Draws this shape into ACanvas where center is at Offset }
    procedure Draw(ACanvas: TCanvas; Offset: TPointF);
  end;

  TEllipse = class(TShape)
    procedure DrawPathData(P: TPathData); override;
  end;

  TRectangle = class(TShape)
    procedure DrawPathData(P: TPathData); override;
  end;

type
  TForm1 = class(TForm)
    pbCanvas: TPaintBox;
    tmrComputeFPS: TTimer;
    lbFPS: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure tmrComputeFPSTimer(Sender: TObject);
    procedure pbCanvasPaint(Sender: TObject; Canvas: TCanvas);
  private
    { Déclarations privées }
    FShapeAnimator: TAnimation;
    FFrames: Cardinal;
    procedure Process(Sender: TObject);
  public
    { Déclarations publiques }
  end;

var
  Form1: TForm1;

implementation

uses
  SmallestCircle.Algorithm;

{$R *.fmx}

type
  { Creates, destroys and move shapes around }
  TShapeAnimation = class(TAnimation)
  private
    FShapes: TObjectList<TShape>;
    FControl: TControl;
    FCircle: TCircle;
    FLastFrameTime: Single;
    procedure FindSmallestCircle;
  protected
    procedure ProcessAnimation; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Control: TControl read FControl write FControl;
    property Circle: TCircle read FCircle;
  end;

{ TShape }

constructor TShape.Create(ARect: TRectF);
begin
  inherited Create;
  Rect := ARect;
  { Center Shape Rect at (0, 0) }
  Rect.Offset(-ARect.Width / 2, -ARect.Height / 2);
  Position := TPointF.Zero;
  Destination := TPoint.Zero;
  TimeToLive := 0;
  Angle := 0;
end;

procedure TShape.Draw(ACanvas: TCanvas; Offset: TPointF);
var
  P: TPathData;
begin
  P := PathData;
  P.Translate(Offset);
  ACanvas.DrawPath(P, 1);
end;

function TShape.PathData: TPathData;
var
  M: TMatrix;
begin
  Result := TPathData.Create;
  DrawPathData(Result);
  M := TMatrix.CreateRotation(Angle);
  Result.ApplyMatrix(M);
  Result.Translate(Position);
end;

function TShape.Polygon: TPolygon;
begin
  PathData.FlattenToPolygon(Result);
end;

{ TEllipse }

procedure TEllipse.DrawPathData(P: TPathData);
begin
  P.AddEllipse(Rect);
end;

{ TRectangle }

procedure TRectangle.DrawPathData(P: TPathData);
begin
  P.AddRectangle(Rect, 0, 0, AllCorners);
end;

{ TShapeAnimation }

constructor TShapeAnimation.Create(AOwner: TComponent);
begin
  inherited;
  Loop := True;
  FShapes := TObjectList<TShape>.Create;
  FCircle := TCircle.INVALID;
end;

destructor TShapeAnimation.Destroy;
begin
  FShapes.Free;
  inherited;
end;

procedure TShapeAnimation.ProcessAnimation;
const
  LIVE = 5.0;
var
  T: Single;
  S: TShape;
  I: Integer;
begin
  if FControl = nil then
    Exit;

  T := NormalizedTime;

  if T = 0 then
    FLastFrameTime := 0;

  if (T = 0) then
  begin
    if Random > 0.5 then
      S := TRectangle.Create(RectF(0, 0, Random * 100, Random * 100))
    else
      S := TEllipse.Create(RectF(0, 0, Random * 100, Random * 100));

    var R := FControl.LocalRect;

    { Choose a destination within current Paintbox Rect }
    S.Destination := PointF(
                       Random * (R.Width - S.Rect.Width * 2),
                       Random * (R.Height - S.Rect.Height * 2)
                     ) - R.CenterPoint;

    { This Shape will live for 5 animation loops }
    S.TimeToLive := LIVE;
    FShapes.Add(S);
  end;

  for S in FShapes do
  begin
    { Time passes... }
    S.TimeToLive := S.TimeToLive - (T - FLastFrameTime);
    { Move it ! }
    S.Position := S.Destination * ((LIVE - S.TimeToLive) / LIVE);
    { Rotate it ! }
    S.Angle := 2 * Pi * ((LIVE - S.TimeToLive) / LIVE);
  end;

  I := 0;
  while I < FShapes.Count do
  begin
    if FShapes[I].TimeToLive <= 0 then
      FShapes.Delete(I)
    else
      Inc(I);
  end;

  { This is where everything happens }
  FindSmallestCircle;

  { Useful to compute offset of time between animation frames }
  FLastFrameTime := T;
end;

procedure TShapeAnimation.FindSmallestCircle;
var
  L: TList<TPointF>;
  AllPts, P: TPolygon;
  Pt: TPointF;
  I: Integer;
begin
  L := TList<TPointF>.Create;
  try

    for var S in FShapes do
    begin
      { Render shapes into rotated/positioned polygons }
      P := S.Polygon;
      { But... remove the "break point" because it's faaaar off screen }
      for Pt in P do
        if Pt <> PolygonPointBreak then
          L.Add(Pt);
    end;

    { Convert List of TPointF into array of TPointF }
    SetLength(AllPts, L.Count);
    for I := 0 to L.Count - 1 do
        AllPts[I] := L[I];

    { Find the smallest enclosing circle of all these points }
    FCircle := MakeCircle(AllPts);
  finally
    L.Free;
  end;
end;

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  FShapeAnimator := TShapeAnimation.Create(Self);
  FShapeAnimator.Parent := Self;
  FShapeAnimator.Duration := 5;
  FShapeAnimator.Interpolation := TInterpolationType.Linear;
  TShapeAnimation(FShapeAnimator).Control := pbCanvas;
  FShapeAnimator.OnProcess := Process;
  FShapeAnimator.Start;
end;

procedure TForm1.pbCanvasPaint(Sender: TObject; Canvas: TCanvas);
var
  Ani: TShapeAnimation;
  S: TShape;
  Center: TPointF;
begin
  Ani := TShapeAnimation(FShapeAnimator);

  Canvas.Stroke.Thickness := 3;
  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Color := $A0909090;

  Center := pbCanvas.LocalRect.CenterPoint;

  for S in Ani.FShapes do
    S.Draw(Canvas, Center);

  if Ani.Circle <> TCircle.INVALID then
  begin
    Canvas.Stroke.Color := $A0900000;
    Canvas.DrawArc(Ani.Circle.Center + Center, PointF(Ani.Circle.Radius, Ani.Circle.Radius), 0, 360, 1);
  end;
end;

procedure TForm1.Process(Sender: TObject);
begin
  { Redraw the whole form }
  Invalidate;
  Inc(FFrames);
end;

procedure TForm1.tmrComputeFPSTimer(Sender: TObject);
var
  FPS: Single;
begin
  { Try to compute the Frame Per Second value }
  FPS := FFrames / tmrComputeFPS.Interval * 1000;
  lbFPS.Text := Format('%.1f fps', [FPS]);
  FFrames := 0;
end;

end.
