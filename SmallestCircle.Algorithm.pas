unit SmallestCircle.Algorithm;

interface

// This is a Delphi port from
// https://www.nayuki.io/res/smallest-enclosing-circle/SmallestEnclosingCircle.cs
// Author Pierre Yager (pierre@levosgien.net)

uses
  System.Types, System.Generics.Collections, System.Math, System.Math.Vectors;

type
  TCircle = record
    Center: TPointF;
    Radius: Single;
    constructor Create(Center: TPointF; Radius: Single);
    class function INVALID: TCircle; static;
    function Contains(P: TPointF): Boolean;

    class operator Equal(ALeft, ARight: TCircle): Boolean;
    class operator NotEqual(ALeft, ARight: TCircle): Boolean;
  end;

function MakeCircle(points: TPolygon): TCircle;

implementation

function MakeDiameter(a, b: TPointF): TCircle;
var
  C: TPointF;
begin
	C := PointF((a.x + b.x) / 2, (a.y + b.y) / 2);
	Result := TCircle.Create(C, Max(C.Distance(a), C.Distance(b)));
end;

function MakeCircumcircle(a, b, c: TPointF): TCircle;
var
  OX, OY: Single;
  AX, AY, BX, BY, CX, CY: Single;
  D: Single;
  X, Y: Single;
  P: TPointF;
  R: Single;
begin
  // Mathematical algorithm from Wikipedia: Circumscribed circle
  OX := (Min(Min(a.x, b.x), c.x) + Max(Min(a.x, b.x), c.x)) / 2;
  OY := (Min(Min(a.y, b.y), c.y) + Max(Min(a.y, b.y), c.y)) / 2;
  AX := a.x - OX;  AY := a.y - OY;
  BX := b.x - OX;  BY := b.y - OY;
  CX := c.x - OX;  CY := c.y - OY;
  D  := (AX * (BY - CY) + BX * (CY - AY) + CX * (AY - BY)) * 2;

  if (D = 0) then
    Exit(TCircle.INVALID);

  X := ((AX*AX + AY*AY) * (BY - CY) + (BX*BX + BY*BY) * (CY - AY) + (CX*CX + CY*CY) * (AY - BY)) / D;
  Y := ((AX*AX + AY*AY) * (CX - BX) + (BX*BX + BY*BY) * (AX - CX) + (CX*CX + CY*CY) * (BX - AX)) / D;
  P := PointF(OX + X, OY + Y);
  R := Max(Max(p.Distance(a), p.Distance(b)), p.Distance(c));

  Result := TCircle.Create(P, R);
end;

// Two boundary points known
function MakeCircleTwoPoints(points: TPolygon; p, q: TPointF): TCircle;
var
  Circ, Left, Right: TCircle;
  PQ: TPointF;
  R: TPointF;
begin
  Circ  := MakeDiameter(p, q);
	Left  := TCircle.INVALID;
	Right := TCircle.INVALID;

  // For each point not in the two-point circle
	PQ := q - p;
  for R in points do
  begin
    if Circ.Contains(R) then
      Continue;

    // Form a circumcircle and classify it on left or right side
		var Cross := pq.CrossProduct(R - p);
    var C := MakeCircumcircle(p, q, R);

    if C.Radius < 0 then
      Continue
    else if (Cross > 0) and ((Left.Radius < 0) or (PQ.CrossProduct(C.Center - p) > PQ.CrossProduct(Left.Center - p))) then
      Left := C
    else if (Cross < 0) and ((Right.Radius < 0) or (PQ.CrossProduct(C.Center - p) < PQ.CrossProduct(Right.Center - p))) then
			Right := C;
  end;

  // Select which circle to return
  if (Left.Radius < 0) and (Right.Radius < 0) then
    Result := Circ
  else if (Left.Radius < 0) then
    Result := Right
  else if (Right.Radius < 0) then
    Result := Left
  else if Left.Radius <= Right.Radius then
    Result := Left
  else
    Result := Right;
end;

function MakeCircleOnePoint(points: TPolygon; p: TPointF): TCircle;
var
  I: Integer;
  q: TPointF;
  subpoly: TPolygon;
begin
  Result := TCircle.Create(p, 0);
  for I := 0 to Length(Points) - 1 do
  begin
		q := points[i];
    if not Result.Contains(q) then
      if Result.Radius = 0 then
        Result := MakeDiameter(p, q)
      else
      begin
        SetLength(subpoly, I + 1);
        TArray.Copy<TPointF>(points, subpoly, I + 1);
        Result := MakeCircleTwoPoints(subpoly, p, q);
      end;
  end;
end;

function MakeCircle(points: TPolygon): TCircle;
var
  shuffled: TPolygon;
  pts: TPolygon;
begin
  // Clone list to preserve the caller's data, do Durstenfeld shuffle
  SetLength(shuffled, Length(points));
  if Length(points) > 0 then
  begin
    TArray.Copy<TPointF>(points, shuffled, Length(points));
    for var I := Length(shuffled) - 1 downto 1 do
    begin
      var j := Random(I + 1);
      var pt := shuffled[I];
      shuffled[I] := shuffled[J];
      shuffled[J] := pt;
    end;
  end;

  // Progressively add points to circle or recompute circle
  Result := TCircle.INVALID;
  for var I := 0 to Length(shuffled) - 1 do
  begin
    var P := shuffled[I];
    if (Result.Radius < 0) or (not Result.Contains(P)) then
    begin
      SetLength(pts, I + 1);
      TArray.Copy<TPointF>(shuffled, pts, I + 1);
      Result := MakeCircleOnePoint(pts, p);
    end;
  end;
end;

{ TCircle }

constructor TCircle.Create(Center: TPointF; Radius: Single);
begin
  Self.Center := Center;
  Self.Radius := Radius;
end;

class operator TCircle.Equal(ALeft, ARight: TCircle): Boolean;
begin
  Result := (ALeft.Center = ARight.Center) and SameValue(ALeft.Radius, ARight.Radius);
end;

function TCircle.Contains(P: TPointF): Boolean;
const
  MULTIPLICATIVE_EPSILON = 1 + 1e-14;
begin
  Result := Self.Center.Distance(P) <= (Self.Radius * MULTIPLICATIVE_EPSILON);
end;

class function TCircle.INVALID: TCircle;
begin
  Result := TCircle.Create(TPointF.Zero, -1);
end;

class operator TCircle.NotEqual(ALeft, ARight: TCircle): Boolean;
begin
  Result := not (ALeft = ARight);
end;

end.
