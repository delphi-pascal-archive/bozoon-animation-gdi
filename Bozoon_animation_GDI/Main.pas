{ BOZON by Deefaze (f0xi - www.delphi.fr)

  copyleft Deefaze 06/01/2009
}
unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, GdipApi, GdipClass;

type
  TForm1 = class(TForm)
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    fGPG : TGPGraphics;
    fGPP : TGPPen;
    fBBM : TBitmap;
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

const
  DRAWTYPE_BEZIER  = 0;
  DRAWTYPE_DBLLINE = 1;
  DRAWTYPE_POLYGON = 2;

  cDrawType  = DRAWTYPE_BEZIER;

  cMovers    = 4;
  cFollowers = 40;

  cSpeedMax : single = 0.20;
  cSpeedMin : single = 0.10;

  cColorMin = 100;
  cColorMax = 250;

  cColorIncMin = 50;
  cColorIncMax = 150;

type
  pCatchers = ^TCatchers;
  TCatchers = record
    Pos   : TGPPointF;
    Vel   : TGPPointF;
    Color : TGPColor;
    Follow: pCatchers;
  end;

  pMovers = ^TMovers;
  TMovers = record
    Pos : TGPPointF;
    Vel : TGPPointF;
  end;

var
  Catchers  : array[0..cMovers-1, 0..cFollowers-1] of TCatchers;
  Movers    : array[0..cMovers-1] of TMovers;
  LineColor : record
                Ri, Gi, Bi,
                R, G, B : single
              end;

  FPSStartTime   : LongWord = 0;
  FPSCurrentTime : LongWord = 0;
  FPSPassCounter : LongWord = 0;

  MoveXMin,
  MoveXMax,
  MoveYMin,
  MoveYMax : integer;


{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
var M,F: integer;
    SP : single;
const
  SpdInv : array[0..1] of integer = (1,-1);
begin
  { Pour generer des nombres aleatoires different a chaque lancement
  }
  Randomize;

  { Pour eviter le scintillement de l'animation
  }
  DoubleBuffered := true;

  { Pas de curseur sur la fiche
  }
  Cursor         := crNone;

  { Definition des limites de deplacement des Movers
  }
  MoveXMin := -20;
  MoveYMin := -20;
  MoveXMax := ClientWidth + 20;
  MoveYMax := ClientHeight + 20;

  { Selection d'une couleur de depart et des incrementeurs de cette
    derniere.
  }
  LineColor.Ri := ((Random(cColorIncMax)+cColorIncMin)*0.001) * SpdInv[Random(100) mod 2];
  LineColor.Gi := ((Random(cColorIncMax)+cColorIncMin)*0.001) * SpdInv[Random(100) mod 2];
  LineColor.Bi := ((Random(cColorIncMax)+cColorIncMin)*0.001) * SpdInv[Random(100) mod 2];
  LineColor.R := Random(128)+127;
  LineColor.G := Random(128)+127;
  LineColor.B := Random(128)+127;

  { Initialisation des Catchers et Movers
  }
  for M := 0 to cMovers-1 do
  begin
    { Les movers sont placé aléatoirement dans la zone definie par
      MoveXMin,MoveXMax et MoveYMin,MoveYMax.
    }
    Movers[M].Pos.X := Random(MoveXMax-20)+MoveXMin+10;
    Movers[M].Pos.Y := Random(MoveYMax-20)+MoveYMin+10;
    Movers[M].Vel.X := ((Random(525)+275)*0.01)*SpdInv[Random(100) mod 2];
    Movers[M].Vel.Y := ((Random(525)+275)*0.01)*SpdInv[Random(100) mod 2];

    { Les Catchers
    }
    for F := 0 to cFollowers-1 do
    begin
      if F > 0 then
        Catchers[M,F].Follow := @Catchers[M,F-1]
      else
        Catchers[M,F].Follow := nil;

      SP := cSpeedMin + ((cSpeedMax-cSpeedMin)/cFollowers)*(cFollowers-F);

      Catchers[M,F].Pos.X := Random(MoveXMax-60)+MoveXMin+30;
      Catchers[M,F].Pos.Y := Random(MoveYMax-60)+MoveYMin+30;
      Catchers[M,F].Vel.X := SP;
      Catchers[M,F].Vel.Y := SP;

      Catchers[M,F].Color := ARGBMake(round(200/cFollowers*(cFollowers-F)),
                                      round(LineColor.R), round(LineColor.G),
                                      round(LineColor.B));
    end;
  end;

  fGPP := TGPPen.Create(aclWhite);
  fBBM := TBitmap.Create;
  fBBM.Width  := ClientWidth;
  fBBM.Height := ClientHeight;
  fBBM.PixelFormat := pf32bit;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  fGPP.Free;
  fBBM.Free;
end;

procedure TForm1.FormResize(Sender: TObject);
var N : integer;
begin
  fBBM.Width  := ClientWidth;
  fBBM.Height := ClientHeight;

  MoveXMax := ClientWidth + 20;
  MoveYMax := ClientHeight + 20;

  for N := Low(Movers) to High(Movers) do
  begin
    Movers[N].Pos.X := ClientWidth shr 1;
    Movers[N].Pos.Y := ClientHeight shr 1;
  end;
end;


procedure TForm1.PaintBox1Paint(Sender: TObject);
var F   : integer;
    Pts : array[0..3] of TGPPointF;
begin
  { Creation des Objets GDI+
  }
  fGPG := TGPGraphics.Create(fBBM.Canvas.Handle);

  { Reglage de la qualité d'affichage
  }
  fGPG.SetCompositingQuality(CompositingQualityHighSpeed);
  fGPG.SetSmoothingMode(SmoothingModeAntiAlias);

  fGPG.Clear(aclBlack);

  { Incrementation de la couleur des Catchers
  }
  LineColor.R := LineColor.R + LineColor.Ri;
  if (LineColor.R <= cColorMin) or (LineColor.R >= cColorMax) then
    LineColor.Ri := LineColor.Ri * -1;

  LineColor.G := LineColor.G + LineColor.Gi;
  if (LineColor.G <= cColorMin) or (LineColor.G >= cColorMax) then
    LineColor.Gi := LineColor.Gi * -1;

  LineColor.B := LineColor.B + LineColor.Bi;
  if (LineColor.B <= cColorMin) or (LineColor.B >= cColorMax) then
    LineColor.Bi := LineColor.Bi * -1;

  { Dessin des Catchers, ici on utilisera des courbes de Bezier!
  }
  for F := 0 to cFollowers-1 do
  begin
    { On redefinie la couleur
    }
    Catchers[0,F].Color := ARGBMake(ARGBGetAlpha(Catchers[0,F].Color),
                                    round(LineColor.R), round(LineColor.G),
                                    round(LineColor.B));

    fGPP.SetColor(Catchers[0,F].Color);

    { On dessine les courbes
    }
    case cDrawType of
      DRAWTYPE_BEZIER  :
        fGPG.DrawBezier(fGPP, Catchers[0,F].Pos, Catchers[1,F].Pos,
                              Catchers[2,F].Pos, Catchers[3,F].Pos);
      DRAWTYPE_DBLLINE :
      begin
        fGPG.DrawLine(fGPP, Catchers[0,F].Pos, Catchers[2,F].Pos);
        fGPG.DrawLine(fGPP, Catchers[1,F].Pos, Catchers[3,F].Pos);
      end;

      DRAWTYPE_POLYGON :
      begin
        Pts[0] := Catchers[0,F].Pos;
        Pts[1] := Catchers[1,F].Pos;
        Pts[2] := Catchers[2,F].Pos;
        Pts[3] := Catchers[3,F].Pos;
        fGPG.DrawPolygon(fGPP, pGPPointF(@Pts), 4);
      end;
    end;
  end;

  { On libere les objets GDI+
  }
  fGPG.Flush;
  fGPG.Free;

  Canvas.Draw(0,0,fBBM);
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var M, F: integer;
    DX, DY, FPS : single;
begin
  { Compteur de FPS
  }
  if (FPSCurrentTime = 0) and (FPSPassCounter = 0) then
    FPSStartTime := GetTickCount;
  inc(FPSPassCounter);

  { Deplacement des Catchers et Movers
  }
  for M := 0 to cMovers-1 do
  begin
    { Les Movers evoluent dans une zone definie par
      MoveXMin, MoveXMax et MoveYMin, MoveYMax
    }
    Movers[M].Pos.X := Movers[M].Pos.X + Movers[M].Vel.X;
    if (Movers[M].Pos.X <= MoveXMin) or (Movers[M].Pos.X >= MoveXMax) then
      Movers[M].Vel.X := Movers[M].Vel.X * -1;

    Movers[M].Pos.Y := Movers[M].Pos.Y + Movers[M].Vel.Y;
    if (Movers[M].Pos.Y <= MoveYMin) or (Movers[M].Pos.Y >= MoveYMax) then
      Movers[M].Vel.Y := Movers[M].Vel.Y * -1;

    { Les premiers Catchers ( Catchers[M,0] ) doit attraper les Movers
    }
    DX := Catchers[M, 0].Vel.X*(Movers[M].Pos.X - Catchers[M, 0].Pos.X);
    if DX = 0 then
      Catchers[M, 0].Pos.X := Movers[M].Pos.X
    else
      Catchers[M, 0].Pos.X := Catchers[M, 0].Pos.X + DX;

    DY := Catchers[M, 0].Vel.Y*(Movers[M].Pos.Y - Catchers[M, 0].Pos.Y);
    if DY = 0 then
      Catchers[M, 0].Pos.Y := Movers[M].Pos.Y
    else
      Catchers[M, 0].Pos.Y := Catchers[M, 0].Pos.Y + DY;

    { Les autres Catchers ( Catchers[M, F > 0] ) doivent suivre les premiers
      Catchers
    }
    for F := 1 to cFollowers-1 do
      if Catchers[M,F].Follow <> nil then
      begin
        DX := Catchers[M,F].Vel.X*(Catchers[M,F].Follow^.Pos.X - Catchers[M,F].Pos.X);
        if DX = 0 then
          Catchers[M,F].Pos.X := Catchers[M,F].Follow^.Pos.X
        else
          Catchers[M,F].Pos.X := Catchers[M,F].Pos.X + DX;

        DY := Catchers[M,F].Vel.Y*(Catchers[M,F].Follow^.Pos.Y - Catchers[M,F].Pos.Y);
        if DY = 0 then
          Catchers[M,F].Pos.Y := Catchers[M,F].Follow^.Pos.Y
        else
          Catchers[M,F].Pos.Y := Catchers[M,F].Pos.Y + DY;
      end;
  end;

  { Compteur de FPS
  }
  FPSCurrentTime := GetTickCount-FPSStartTime;

  if FPSCurrentTime >= 1000 then
  begin
    FPS := 1000/FPSCurrentTime*FPSPassCounter;
    Caption := format('%.2n FPS',[FPS]);
    FPSPassCounter := 0;
    FPSCurrentTime := 0;
  end;

  { Demande de redessiner
  }
  Invalidate;
end;

end.
