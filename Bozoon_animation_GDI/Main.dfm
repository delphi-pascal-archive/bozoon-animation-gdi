object Form1: TForm1
  Left = 226
  Top = 125
  Width = 808
  Height = 634
  Caption = 'Bozoon animation GDI'
  Color = clBlack
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnPaint = PaintBox1Paint
  OnResize = FormResize
  PixelsPerInch = 120
  TextHeight = 16
  object Timer1: TTimer
    Interval = 30
    OnTimer = Timer1Timer
    Left = 84
    Top = 84
  end
end
