unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, StdCtrls,
  ExtCtrls, EpikTimer, BGRABitmap,BGRABitmapTypes, Math, LCLIntf, BGRAPath;

type
  RandomFlow = record
    Angle:Integer;
    Thickness:Tpoint;
  end;

  type
  ParticleFlow = record
    Enable_:Boolean;
    Visible:Boolean;
    Position:Tpoint;
    PathPosition, PathSpeed, PathLength: single;
    Angle:Extended;
    Width:integer;
    Arrow_Width:integer;
    ThickTimer_:Extended;
    ActualTime:Extended;
    RemainTime:Extended;
    FlowRatePerThick,ActualFlowRatePerThick:integer;
    SumOfFlowRate:integer;
    GiveSpeedFlowToObject:Extended;
    GiveAngleToObject:integer;
    RandomPosition:Tpoint;
    RandomSpeed:integer;
    RandomForwordPosition:integer;
    RandomAngle:integer;
    RandomPathCursorNumber: integer;
    TotalFlowLifeTime: integer;
    RandomFlowLifeTime: integer;
    ActualLife:integer;
  end;

  type
  Animation = record
    Life:Boolean;
    Visible:Boolean;
    EnableLifeTime:Boolean;
    Index:Integer;
    AnimatType:Integer;
    Frame_Speed: Integer;
    Remain_Speed:Integer;
    TotalFrame: Integer;
    Actual_Frame: Integer;
    MovingSpeed:Tpoint;
    Angle:Extended;
    Position:Tpoint;
    Flow_:RandomFlow;
    PathPosition, PathSpeed, PathLength: single;
    TotalLifeTime, ActualLifeTime, RemainLifeTime: Extended;
    Bitmap_: array of Integer;
  end;

  type
  RotageImage = record
    OrgImage: TBGRABitmap;
    Bitmap: TBGRABitmap;
    Angle:Extended;
  end;

  type
  Inform = record
    Previous: Float;
    TimePerFrame: Float;
    LinePerFrame: Integer;
    FramePerSec: Integer;
    ActualElapsed: Float;
    LineLeftover: Integer;
    Speed_frame:Extended;
  end;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Label3: TLabel;
    PaintBox2: TPaintBox;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    procedure Main_Loop();
    Function TransparentBMP_ToBuffer(filename: string): TBGRABitmap;
    Function ManualTransparentBMP_ToBuffer(filename: string; Transparent:TBGRAPixel): TBGRABitmap;
    Procedure FlowRander();
    procedure SetUpValue();
  end;

var
  Form1: TForm1;
  timer_: TEpikTimer;
  Run_:Boolean;
  Background_, bmp, bmp2: TBGRABitmap;
  Grid_:Tpoint;
  c: TBGRAPixel;
  Trect_:Trect;
  Positioning:integer;
  Information:Inform;
  ParticleObject: array of Animation;
  Flow: ParticleFlow;
  TotalParticleObject, TotalBitmapAnimation:integer;
  BitmapAnimation: array of TBGRABitmap;
  TotalParticleLife:integer;

  pts: array of TPointF;
  FPath: TBGRAPath;
  FPathCursor: TBGRAPathCursor;
  FPathPos: single;
  Style_: TSplineStyle;
  TotalPoints:integer;
  Closed_: boolean;
  Propeller:RotageImage;

implementation

{$R *.lfm}

{ TForm1 }
Procedure TForm1.SetUpValue();
var
  i,i2:integer;
begin

  c := ColorToBGRA(rgb(255,255,255));
  Propeller.OrgImage := ManualTransparentBMP_ToBuffer('PropellerSmall.png',c);
  Propeller.Bitmap := TBGRABitmap.Create(Propeller.OrgImage.Width,Propeller.OrgImage.Height);//ColorToBGRA($00CCCCCC)//clForeground //clBtnFace  //clWindow //ColorToBGRA(rgb(255,255,255))
  Propeller.Bitmap.PutImage(0,0,Propeller.OrgImage,dmDrawWithTransparency,220);
  Propeller.Angle:=0;

  FPathPos := 0;
  setlength(pts,13);
  pts[0] := PointF(72,324);
  pts[1] := pointF(117,323);
  pts[2] := pointF(188,297);
  pts[3] := pointF(188,136);
  pts[4] := pointF(188,69);
  pts[5] := pointF(240,37);
  pts[6] := pointF(281,37);
  //
  pts[7] := pointF(295,37);
  pts[8] := pointF(287,13);
  pts[9] := pointF(337,13);
  pts[10] := pointF(478,13);
  pts[11] := pointF(491,43);
  pts[12] := pointF(488,213);

  //if Inside then Style_ := ssInsideWithEnds else
  //if Crossing then Style_ := ssCrossingWithEnds else
  //if Outside then Style_ := ssOutside else
  //if Rounded then Style_ := ssRoundOutside else
  //if VertexToSide then Style_ := ssVertexToSide;
  Style_ := ssInsideWithEnds;
  Closed_:=False;
  TotalPoints := length(pts);

  if FPath = nil then
  begin
    FPath := TBGRAPath.Create;
    if Closed_ then
      FPath.closedSpline(slice(pts,TotalPoints), Style_)
    else
      FPath.openedSpline(slice(pts,TotalPoints), Style_);
  end;

  if FPathCursor = nil then
  begin
    FPathCursor := FPath.CreateCursor;
    FPathCursor.LoopPath:= true;
    FPathCursor.Position := FPathPos*FPathCursor.PathLength;
  end;


  Information.Speed_frame:=0.02;
  timer_ := TEpikTimer.Create(nil);
  //timer_.TimebaseSource:=timer_.TimebaseSource.HardwareTimebase;
  Run_:=False;

  TotalBitmapAnimation:=5;
  setlength(BitmapAnimation,TotalBitmapAnimation);
  c := ColorToBGRA(rgb(255,255,255));

  //Load your bitmap here
  for i:=0 to 3 do
    BitmapAnimation[i] := ManualTransparentBMP_ToBuffer('Fluff'+IntToStr(i+1)+'.png',c);
  BitmapAnimation[4] := ManualTransparentBMP_ToBuffer('Oxygen.png',c);

  TotalParticleObject:=4000;
  TotalParticleLife:=0;
  Randomize;
  setlength(ParticleObject,TotalParticleObject);
  for i:=0 to TotalParticleObject-1 do
  begin
    ParticleObject[i].Life:=False;
    ParticleObject[i].Visible:=True;
    ParticleObject[i].Index:=i;
    ParticleObject[i].Actual_Frame:=0;
    ParticleObject[i].AnimatType:=0;
    ParticleObject[i].Frame_Speed:=7;
    ParticleObject[i].Remain_Speed:=ParticleObject[i].Frame_Speed;
    ParticleObject[i].Position:=Point(0,0);
    ParticleObject[i].Angle:=0;
    ParticleObject[i].TotalFrame:=5;
    setlength(ParticleObject[i].Bitmap_,ParticleObject[i].TotalFrame);
    for i2:=0 to ParticleObject[i].TotalFrame-1 do
      ParticleObject[i].Bitmap_[i2] := i2;
    ParticleObject[i].PathPosition:=0;
    ParticleObject[i].PathSpeed:=3;
    ParticleObject[i].PathLength:=FPathCursor.PathLength-20;
    ParticleObject[i].Flow_.Thickness:=Point(2,2);
  end;

  Flow.ActualLife:=0;
  Flow.Enable_:=False;
  Flow.Visible:=False;
  Flow.Position:=Point(270,155);
  Flow.PathSpeed:=1;
  Flow.PathPosition:=0;
  Flow.PathLength:=FPathCursor.PathLength;
  FLow.Width:=4;
  FLow.Arrow_Width:=10;
  FLow.Angle:=0;
  Flow.ActualTime:=0;
  Flow.RemainTime:=0;
  Flow.ThickTimer_:=10/1000;  //10ms
  Flow.FlowRatePerThick:=2;
  Flow.SumOfFlowRate:=0;
  Flow.GiveSpeedFlowToObject:=0.6;
  Flow.RandomSpeed:=3;
  Flow.RandomPosition:=Point(FLow.Arrow_Width,FLow.Width);

  FPathCursor.Position:=0;

  Grid_.X:=26;
  Grid_.y:=15;

  if Grid_.X<0 then Grid_.X:=0;
  if Grid_.Y<0 then Grid_.Y:=0;

  Background_ := TBGRABitmap.Create(PaintBox2.Width,PaintBox2.Height, ColorToBGRA($00F0F0F0));//clForeground //clBtnFace  //clWindow //ColorToBGRA(rgb(255,255,255))
  bmp := TBGRABitmap.Create(PaintBox2.Width,PaintBox2.Height, ColorToBGRA($00F0F0F0));//clForeground //clBtnFace  //clWindow //ColorToBGRA(rgb(255,255,255))
  bmp2 := TBGRABitmap.Create(Round(PaintBox2.Width/(Grid_.X+1))+1,PaintBox2.Height, ColorToBGRA($00CCCCCC));//ColorToBGRA($00CCCCCC)//clForeground //clBtnFace  //clWindow //ColorToBGRA(rgb(255,255,255))
  bmp.FontName := 'Times New Roman';
  bmp.FontAntialias:= true;
  bmp.FontHeight:=12;
  bmp.FontStyle:=[fsBold];

end;

Procedure TForm1.FlowRander();
var
  pot: array of TPointF;
  pot2: array of TPointF;
  pot3: array of TPointF;
  x_,y_,t:Float;
  i:integer;
  OP,AD,DE:Extended;
  New_pt, pt:TPointF;

begin
  if Flow.Width=0 then Flow.Width:=1;

  setlength(pot,4);
  setlength(pot2,2);
  setlength(pot3,3);
  pot[0] := PointF(-round(Flow.Width/2),-2);
  pot[1] := pointF(round(Flow.Width/2),-2);
  pot[2] := pointF(round(Flow.Width/2),2);
  pot[3] := pointF(-round(Flow.Width/2),2);

  pot3[0] := PointF(round(FLow.Arrow_Width)-3,-2);
  pot3[1] := pointF(round(FLow.Arrow_Width),0);
  pot3[2] := pointF(round(FLow.Arrow_Width)-3,2);

  t := (((2*pi)/360)*(Flow.Angle+0));

  x_ :=((0)*cos(t));  //x_ :=((-FLow.Arrow_Width/2)*cos(t));
  y_ :=((0)*sin(t));  //y_ :=((-FLow.Arrow_Width/2)*sin(t));
  x_ := x_+Flow.Position.x-0;
  y_:=(-y_)+Flow.Position.y-0;
  pot2[0] := PointF(x_,y_);

  x_ :=((FLow.Arrow_Width)*cos(t));  //x_ :=((FLow.Arrow_Width/2)*cos(t));
  y_ :=((FLow.Arrow_Width)*sin(t));  //y_ :=((FLow.Arrow_Width/2)*sin(t));
  x_ := x_+Flow.Position.x+0;
  y_:=(-y_)+Flow.Position.y+0;
  pot2[1] := pointF(x_,y_);

  x_ :=((pot3[0].x)*cos(t)) - ((pot3[0].y)*sin(t));
  y_ :=((pot3[0].x)*sin(t)) + ((pot3[0].y)*cos(t));
  x_ := x_+Flow.Position.x;
  y_:=(-y_)+Flow.Position.y;
  pot3[0].x := x_;
  pot3[0].y := y_;

  x_ :=((pot3[1].x)*cos(t)) - ((pot3[1].y)*sin(t));
  y_ :=((pot3[1].x)*sin(t)) + ((pot3[1].y)*cos(t));
  x_ := x_+Flow.Position.x;
  y_:=(-y_)+Flow.Position.y;
  pot3[1].x := x_;
  pot3[1].y := y_;

  x_ :=((pot3[2].x)*cos(t)) - ((pot3[2].y)*sin(t));
  y_ :=((pot3[2].x)*sin(t)) + ((pot3[2].y)*cos(t));
  x_ := x_+Flow.Position.x;
  y_:=(-y_)+Flow.Position.y;
  pot3[2].x := x_;
  pot3[2].y := y_;

  t := (((2*pi)/360)*(Flow.Angle+90));
  x_ :=((pot[0].x)*cos(t)) - ((pot[0].y)*sin(t));
  y_ :=((pot[0].x)*sin(t)) + ((pot[0].y)*cos(t));
  x_ := x_+Flow.Position.x;
  y_:=(-y_)+Flow.Position.y;
  pot[0].x := x_;
  pot[0].y := y_;


  x_ :=((pot[1].x)*cos(t)) - ((pot[1].y)*sin(t));
  y_ :=((pot[1].x)*sin(t)) + ((pot[1].y)*cos(t));
  x_ := x_+Flow.Position.x;
  y_:=(-y_)+Flow.Position.y;
  pot[1].x := x_;
  pot[1].y := y_;

  x_ :=((pot[2].x)*cos(t)) - ((pot[2].y)*sin(t));
  y_ :=((pot[2].x)*sin(t)) + ((pot[2].y)*cos(t));
  x_ := x_+Flow.Position.x;
  y_:=(-y_)+Flow.Position.y;
  pot[2].x := x_;
  pot[2].y := y_;

  x_ :=((pot[3].x)*cos(t)) - ((pot[3].y)*sin(t));
  y_ :=((pot[3].x)*sin(t)) + ((pot[3].y)*cos(t));
  x_ := x_+Flow.Position.x;
  y_:=(-y_)+Flow.Position.y;
  pot[3].x := x_;
  pot[3].y := y_;

  for i:= 0 to TotalParticleObject-1 do
  begin
    if ParticleObject[i].Life then
    begin
      //t := (((2*pi)/360)*(ParticleObject[i].Angle));
      //
      //x_ :=((ParticleObject[i].PathPosition)*cos(t));
      //y_ :=((ParticleObject[i].PathPosition)*sin(t));
      //x_ := x_+ParticleObject[i].Position.x-0;
      //y_:=(-y_)+ParticleObject[i].Position.y-0;

      FPathCursor.Position:=ParticleObject[i].PathPosition;
      //ParticleObject[i].Position.x:=round(FPathCursor.CurrentCoordinate.x);
      //ParticleObject[i].Position.y:=round(FPathCursor.CurrentCoordinate.y);

      pt := FPathCursor.CurrentCoordinate;
      FPathCursor.MoveForward(ParticleObject[i].PathSpeed, True); //Jump = True   Not jump = False
      New_pt:= FPathCursor.CurrentCoordinate;

      OP:=0; AD:=0; DE:=0;
      OP:=pt.y-New_pt.y;
      AD:=New_pt.x-pt.x;
      DE:=(ArcTan2((OP),(AD)))*(180.0/pi);    //RadToDeg(ArcTan2((OP),(AD)));
      //if DE > 180 then
      ParticleObject[i].Angle:=DE-180;
      //else
      //ParticleObject[i].Angle:=DE;//-180;//*(-1);

      t := (((2*pi)/360)*(ParticleObject[i].Angle+0));
      x_ :=((ParticleObject[i].Position.x)*cos(t)) - ((ParticleObject[i].Position.y)*sin(t));
      y_ :=((ParticleObject[i].Position.x)*sin(t)) + ((ParticleObject[i].Position.y)*cos(t));
      x_ := x_+pt.x;
      y_:=(-y_)+pt.y;

      //x_ :=((9)*sin(t));
      //y_ :=((9)*cos(t));
      //x_ := x_+pt.x+0;
      //y_:=(-y_)+pt.y+0;

      ParticleObject[i].PathPosition:=FPathCursor.Position;



      if ParticleObject[i].Visible then
      begin
      //c := ColorToBGRA(rgb(250,50,50)); //ColorToBGRA($00CCCCCC)
      //bmp.FillEllipseAntialias(x_,y_,2,2,BGRA(192,0,0,255));
      //bmp.FillEllipseAntialias(ParticleObject[i].Position.x,ParticleObject[i].Position.y,2,2,BGRA(192,0,0,255));
      //bmp.EllipseAntialias(Ball1[i].Current_.X,Ball1[i].Current_.Y,Ball1[i].Radius,Ball1[i].Radius,BGRA(255,0,0,255),1.4);
      bmp.PutImageAngle(x_+random(ParticleObject[i].Flow_.Thickness.x),
                            y_+random(ParticleObject[i].Flow_.Thickness.y),
                            BitmapAnimation[ParticleObject[i].Bitmap_[ParticleObject[i].Actual_Frame]],
                            ParticleObject[i].Angle,
                           (BitmapAnimation[ParticleObject[i].Bitmap_[ParticleObject[i].Actual_Frame]].Width / 2),
                           (BitmapAnimation[ParticleObject[i].Bitmap_[ParticleObject[i].Actual_Frame]].Height / 2));

      end;
      //ParticleObject[i].Position.x:=round(x_);
      //ParticleObject[i].Position.y:=round(y_);
      //ParticleObject[i].PathPosition:=1;
    end;
  end;

  ////FlowRander:=TBGRABitmap.Create(Buffer.Width,Buffer.Height,BGRAPixelTransparent);       //result
  ////FlowRander.PutImage(0,0,Buffer,dmSet,255);  //FlowRander.PutImage(0,0,Buffer,dmDrawWithTransparency);
  //bmp.FillRect(Flow.Position.x-round(Flow.Width/2),Flow.Position.y-2,Flow.Position.x+round(Flow.Width/2),Flow.Position.y+2,rgb(112,146,90));


  if Flow.Visible then
  begin
    c := ColorToBGRA(rgb(250,50,50));
    bmp.FillPolyAntialias(pot,c);
    c := ColorToBGRA(rgb(50,250,50));
    bmp.DrawPolyLineAntialias(pot2,c,1);
    c := ColorToBGRA(rgb(50,50,250));
    bmp.DrawPolyLineAntialias(pot3,c,1);
  end;

  bmp.TextOut(5,(bmp.FontFullHeight*0)+5,'x/y ='+FloatToStr(Flow.Position.x)+'/'+FloatToStr(Flow.Position.y),c);
  bmp.TextOut(5,(bmp.FontFullHeight*1)+5,'Angle ='+FloatToStr(Flow.Angle),c);
  bmp.TextOut(5,(bmp.FontFullHeight*2)+5,'RemainTime ='+FloatToStr(Flow.RemainTime),c);
  bmp.TextOut(5,(bmp.FontFullHeight*3)+5,'SumOfFlowRate ='+IntToStr(Flow.SumOfFlowRate),c);
  bmp.TextOut(5,(bmp.FontFullHeight*4)+5,'TotalParticleLife ='+IntToStr(TotalParticleLife),c);

end;

Function TForm1.ManualTransparentBMP_ToBuffer(filename: string; Transparent:TBGRAPixel): TBGRABitmap;
var
  OriginalBMP: TBGRABitmap;
begin
  OriginalBMP := TBGRABitmap.Create(filename);
  OriginalBMP.ReplaceColor(Transparent,BGRAPixelTransparent);
  ManualTransparentBMP_ToBuffer := TBGRABitmap.Create(OriginalBMP.Width,OriginalBMP.Height);       //result
  ManualTransparentBMP_ToBuffer.PutImage(0,0,OriginalBMP,dmSet,255);
  OriginalBMP.Free;
end;

Function TForm1.TransparentBMP_ToBuffer(filename: string): TBGRABitmap;
var
  OriginalBMP: TBGRABitmap;
  //Trect_:Trect;
begin
  OriginalBMP := TBGRABitmap.Create(filename);
  OriginalBMP.ReplaceColor(OriginalBMP.GetPixel(0,0),BGRAPixelTransparent);
  TransparentBMP_ToBuffer := TBGRABitmap.Create(OriginalBMP.Width,OriginalBMP.Height);       //result
  TransparentBMP_ToBuffer.PutImage(0,0,OriginalBMP,dmSet,255);
  //TransparentBMP_ToBuffer.Rectangle(OriginalBMP.Width,0,OriginalBMP.Width,OriginalBMP.Height,BGRABlack,BGRA(0,0,0,64),dmDrawWithTransparency);

  //Trect_.TopLeft.x:=0;
  //Trect_.TopLeft.y:=0;
  //Trect_.BottomRight.x:=round(OriginalBMP.Width/2);
  //Trect_.BottomRight.y:=round(OriginalBMP.Height/2);
  //TransparentBMP_ToBuffer.PutImagePart(0,0,OriginalBMP,IT,dmSet,255); //TransparentBMP_ToBuffer.PutImagePart(0,0,OriginalBMP,IT,dmDrawWithTransparency);
  OriginalBMP.Free;
end;

procedure TForm1.Main_Loop();
var
  i:Integer;
  Frame_, Line_, Line_Frame:integer;
  x_,y_,t:Float;
  OP,AD,DE:Extended;
  New_pt, pt:TPointF;

begin
  if Not Run_ then
  begin
    Run_:=True;
    Information.Previous:=0;
    Frame_:=0;
    Line_:=0;
    timer_.Clear;
    timer_.Start;

    while Run_ do
    begin
      Line_Frame:=0;
      application.ProcessMessages; //Work one program only   Case 1.

      //Run your program here  => Finish up your brackground

      bmp.PutImage(0,0,Background_,dmDrawWithTransparency);
      if not Flow.Enable_ then Propeller.Angle:=Propeller.Angle+5;
      if Flow.Enable_ then Propeller.Angle:=Propeller.Angle+20;
      if Propeller.Angle >= 360*2 then Flow.Enable_:=true;
      if Propeller.Angle >= 360*2 then Propeller.Angle:=0;
      bmp.PutImageAngle(491,311,Propeller.Bitmap,Propeller.Angle,(Propeller.Bitmap.Width div 2)-0,(Propeller.Bitmap.Height div 2)+0);



      //Run your program here  => Finish up your Object
      ////bmp.ArrowEndAsClassic;
      //if Assigned(FPath) then
      //begin
      //  for i := 0 to TotalPoints-1 do
      //    bmp.FillEllipseAntialias(pts[i].x,pts[i].y,5,5,BGRA(255,100,100,100));
      //  FPath.stroke(bmp, BGRABlack, 2);
      //  //bmp.DrawPolyLineAntialiasAutocycle(FPath.ToPoints(0.1),BGRABlack,2);
      //end;


      Flow.ActualLife:=0;
      for i:= 0 to TotalParticleObject-1 do
      begin
        if (ParticleObject[i].PathPosition + ParticleObject[i].PathSpeed > (ParticleObject[i].PathLength)) and (ParticleObject[i].Life) then
        begin
          ParticleObject[i].Life:=False;
          TotalParticleLife:=TotalParticleLife-1;
        end;
        if ParticleObject[i].Life then
        begin
          if (ParticleObject[i].PathPosition + ParticleObject[i].PathSpeed >= 506) and (ParticleObject[i].PathPosition + ParticleObject[i].PathSpeed < 539) then ParticleObject[i].Visible:=False;
          if ParticleObject[i].PathPosition + ParticleObject[i].PathSpeed >= 532 then ParticleObject[i].Visible:=True;
          Flow.ActualLife:=Flow.ActualLife+1;
          ParticleObject[i].PathPosition:=ParticleObject[i].PathPosition+ParticleObject[i].PathSpeed;

          if ParticleObject[i].AnimatType = 1 then
          begin
            ParticleObject[i].Remain_Speed:=ParticleObject[i].Remain_Speed-1;
            if ParticleObject[i].Remain_Speed<=0 then
            begin
              ParticleObject[i].Remain_Speed:=ParticleObject[i].Frame_Speed;
              ParticleObject[i].Actual_Frame:=ParticleObject[i].Actual_Frame+1;
              if ParticleObject[i].Actual_Frame>ParticleObject[i].TotalFrame-1 then
              begin
                ParticleObject[i].Actual_Frame:=0;
              end;
            end;
          end;

        end;
      end;

      FlowRander();

      if Flow.Enable_ then
      begin
        FPathCursor.Position:=Flow.PathPosition;
        Flow.Position.x:=round(FPathCursor.CurrentCoordinate.x);
        Flow.Position.y:=round(FPathCursor.CurrentCoordinate.y);
        pt := FPathCursor.CurrentCoordinate;
        FPathCursor.MoveBackward(Flow.PathSpeed, True); //Jump = True   Not jump = False
        New_pt:= FPathCursor.CurrentCoordinate;
        OP:=0; AD:=0; DE:=0;
        OP:=pt.y-New_pt.y;
        AD:=New_pt.x-pt.x;
        DE:=(ArcTan2((OP),(AD)))*(180.0/pi);    //RadToDeg(ArcTan2((OP),(AD)));
        Flow.Angle:=DE-180;

      Flow.PathPosition:=FPathCursor.Position;
      if Flow.PathPosition - Flow.PathSpeed < 1 then Flow.PathPosition:=1;

        Flow.SumOfFlowRate:=Flow.SumOfFlowRate+ Flow.FlowRatePerThick;
        if (TotalParticleLife+Flow.SumOfFlowRate) >= TotalParticleObject then Flow.SumOfFlowRate:=TotalParticleObject-TotalParticleLife;
        for i:= 0 to TotalParticleObject-1 do
        begin
          if (Flow.SumOfFlowRate > 0) and (not ParticleObject[i].Life) then
          begin
            ParticleObject[i].Life:=True;
            ParticleObject[i].TotalLifeTime:=Flow.TotalFlowLifeTime;
            ParticleObject[i].PathSpeed:=Flow.GiveSpeedFlowToObject+(Random(Flow.RandomSpeed*10)/100);
            ParticleObject[i].Position:=Point(0,Random(Flow.RandomPosition.y)-(Flow.Width div 2));
            if Flow.PathPosition>1 then
            begin
              ParticleObject[i].AnimatType:=0;
              ParticleObject[i].TotalFrame:=1;
              ParticleObject[i].Actual_Frame:=4;
              ParticleObject[i].PathLength:=FPathCursor.PathLength-20;
              ParticleObject[i].Flow_.Thickness:=Point(0,0);
            end;
            if Flow.PathPosition<=1 then
            begin
              ParticleObject[i].AnimatType:=Random(2); //0 or 1
              if ParticleObject[i].AnimatType = 0 then
              begin
                ParticleObject[i].TotalFrame:=1;
                ParticleObject[i].Actual_Frame:=4;
                ParticleObject[i].PathLength:=FPathCursor.PathLength-20;
                ParticleObject[i].Flow_.Thickness:=Point(0,0);
              end;
              if ParticleObject[i].AnimatType = 1 then
              begin
                ParticleObject[i].TotalFrame:=4;
                ParticleObject[i].Actual_Frame:=0;
                ParticleObject[i].PathLength:=425;
                ParticleObject[i].Flow_.Thickness:=Point(2,2);
              end;
            end;
            ParticleObject[i].Angle:=Flow.Angle;
            ParticleObject[i].PathPosition:=Flow.PathPosition+random(FLow.Arrow_Width);
            TotalParticleLife:=TotalParticleLife+1;
            Flow.SumOfFlowRate:=Flow.SumOfFlowRate-1;
          end;
        end;
      end;

      //Any text information here  => Finish up your text status
      c := ColorToBGRA(rgb(0,105,208));
      bmp.TextOut(450,(bmp.FontFullHeight*0)+5,'Total life ='+IntToStr(Flow.ActualLife),c);
      bmp.TextOut(450,(bmp.FontFullHeight*1)+5,'Total Length ='+IntToStr(round(FPathCursor.PathLength)),c); //Raw material=423, Oxygen=825
      //Render here   => Finish up your rander
      bmp.Draw(PaintBox2.Canvas,0,0,True);

      //Clear your hardware here

      while (((timer_.Elapsed -Information.Previous) <= Information.Speed_frame) and
             (timer_.Elapsed < 1) and (Run_)) do //and (timer_.Elapsed < 1) do
      begin
        //application.ProcessMessages; //Share CUP  Case 2

        //Detect hardware here

        Line_:=Line_+1;
        Line_Frame:=Line_Frame+1;

        //Run_:=not Run_; //For run only 1 cycle
      end;

      //Other status here
      Information.TimePerFrame:=(timer_.Elapsed -Information.Previous)*1000;
      Information.Previous:=timer_.Elapsed;
      Frame_:=Frame_+1;

      if timer_.Elapsed >= 1 then
      begin
        timer_.Stop;
        Information.ActualElapsed:=timer_.Elapsed*1000;
        Information.FramePerSec:=Frame_;
        Information.LineLeftover:=Line_;
        Information.LinePerFrame:=Line_Frame;

        Information.Previous:=0;
        Frame_:=0;
        Line_:=0;
        timer_.Clear;
        timer_.Start;
        //FLow.RemainTime:=(-1)*FLow.RemainTime;
        FLow.RemainTime:=0;
      end;

      //You can move your render to here. (!It is up to you)

    end;

    If not Run_ then  timer_.Stop;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  i, i2, i3 : Integer;

begin
  SetUpValue();

  c := ColorToBGRA(rgb(190,190,190));

  i2:=Round(PaintBox2.Width/(Grid_.X+1));
  i3:=0;
  for i := 0 to Grid_.X do
  begin
    i3:=i3+i2;
    Background_.DrawPolyLineAntialias([PointF(i3,0), PointF(i3,PaintBox2.Height)],c,1);
  end;

  i2:=Round(PaintBox2.Height/(Grid_.Y+1));
  i3:=0;
  for i := 0 to Grid_.Y do
  begin
    i3:=i3+i2;
    Background_.DrawPolyLineAntialias([PointF(0,i3), PointF(PaintBox2.Width,i3)],c,1);
  end;

  c := ColorToBGRA(rgb(255,255,255));
  Background_ := ManualTransparentBMP_ToBuffer('OverView_.png',c);

  Trect_.TopLeft.x:=0;
  Trect_.TopLeft.y:=0;
  Trect_.BottomRight.x:=bmp2.Width;
  Trect_.BottomRight.y:=bmp2.Height;
  bmp2.PutImagePart(0,0,Background_,Trect_,dmDrawWithTransparency);
  //bmp2.DrawPolyLineAntialias([PointF(0,0), PointF(0,bmp2.Height)],c,1);

  Positioning:=(PaintBox2.Width mod (Trect_.BottomRight.x-1));
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  Main_Loop();
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  Information.Speed_frame:=0.02;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  Information.Speed_frame:=0.029;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  Run_:=False;
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  Information.Speed_frame:=0.1;
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  Run_:=False;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  timer_.Free;
  Background_.Free;
  bmp.Free;
  bmp2.Free;
  Propeller.OrgImage.Free;
  Propeller.Bitmap.Free;

  FreeAndNil(FPathCursor);
  FreeAndNil(FPath);
end;

end.

