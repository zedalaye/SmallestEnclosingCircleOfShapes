program SmallestCircle;

uses
  System.StartUpCopy,
  FMX.Forms,
  SmallestCircle.Main in 'SmallestCircle.Main.pas' {Form1},
  SmallestCircle.Algorithm in 'SmallestCircle.Algorithm.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
