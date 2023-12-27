unit UnitGameMechanics;

interface

uses
  Windows, System.SysUtils, UnitErrorHandler;

type TObject         = array[1..2] of integer;
     TArrayOfObjects = array of TObject;
     TSprite         = array[0..3, 0..3] of byte;
     TDirection      = (dirNone, dirRight, dirLeft);
     TCharge         = (chNaN, chZero, chHalf, chReady);

var FieldLength, FieldWidth, EnemyCount, ProjectileCount, EnemySpeed, FrameSpeed, ChargeSpeed, CurrentScore, ScoreGoal :byte;
    TickCount, ProjectileMade :cardinal;
    ProjectileHit, EnemyHit, FrameCount :integer;
    ProjectileCharge :TCharge;
    SpaceShip :TObject;
    Projectile, Enemy :TArrayOfObjects;
    SpaceShipSprite, EnemySprite, ProjectileSprite, EmptyTile :TSprite;
    SpaceShipDirection :TDirection;
    FlagShoot, FlagHit, FlagWin, FlagDefeat :boolean;
    SpaceShipColour, EnemyColour1, EnemyColour2, ProjectileColour :word;
    ChargeColour :array [1..3] of word;


procedure GameStartingValues; stdcall;
procedure CreateProjectile;   stdcall;
procedure MoveSpaceShip;      stdcall;
procedure MoveProjectile;     stdcall;
procedure CreateEnemy;        stdcall;
procedure MoveEnemy;          stdcall;
procedure CheckHit;           stdcall;
procedure CheckDefeat;        stdcall;
procedure CheckWin;           stdcall;
procedure GameEndingValues;   stdcall;

implementation

procedure DefineSprites;
const
SpaceShipBasicSprite: TSprite =
  ((0,0,0,0),
   (1,2,2,1),
   (0,1,1,0),
   (1,0,0,1));
EnemyBasicSprite: TSprite =
  ((2,0,0,1),
   (0,1,2,0),
   (0,2,1,0),
   (1,0,0,2));
ProjectileBasicSprite: TSprite =
  ((0,0,1,0),
   (0,1,0,0),
   (0,0,1,0),
   (0,1,0,0));
EmptyBasicTile: TSprite =
  ((0,0,0,0),
   (0,0,0,0),
   (0,0,0,0),
   (0,0,0,0));
begin
  SpaceShipSprite  := SpaceShipBasicSprite;
  EnemySprite      := EnemyBasicSprite;
  ProjectileSprite := ProjectileBasicSprite;
  EmptyTile        := EmptyBasicTile;
end;

procedure GameStartingValues;
begin
  FlagShoot     := False;
  FlagWin       := False;
  FlagDefeat    := False;
  FlagHit       := False;

  FieldLength      := 12;
  FieldWidth       := 8;
  FrameSpeed       := 10;
  ChargeSpeed      := 1;

  EnemyCount       := 0;
  ProjectileCount  := 0;
  ProjectileCharge := chReady;
  ProjectileMade   := 0;
  TickCount        := 0;
  CurrentScore     := 0;
  ScoreGoal        := 100;
  ProjectileHit    := -1;
  EnemyHit         := -1;

  SpaceShip[1] := FieldLength div 2;;
  SpaceShip[2] := FieldWidth - 1;
  SpaceShipDirection := dirNone;

  SpaceShipColour  := BACKGROUND_BLUE;
  EnemyColour1     := BACKGROUND_RED or BACKGROUND_BLUE;
  EnemyColour2     := BACKGROUND_RED or BACKGROUND_BLUE or BACKGROUND_INTENSITY;
  ProjectileColour := BACKGROUND_RED;
  ChargeColour[1]  := BACKGROUND_RED;
  ChargeColour[2]  := BACKGROUND_RED or BACKGROUND_GREEN;
  ChargeColour[3]  := BACKGROUND_GREEN;

  DefineSprites;
end;

procedure CreateProjectile;
begin
  FlagShoot        := False;
  ProjectileCharge := chNaN;
  Inc(ProjectileCount);
  Inc(ProjectileMade);
  SetLength(Projectile, ProjectileCount);
  Projectile[ProjectileCount-1, 1] := SpaceShip[1];
  Projectile[ProjectileCount-1, 2] := SpaceShip[2] - 1;
end;

procedure MoveSpaceShip;
begin
  case SpaceShipDirection of
    dirRight: if SpaceShip[1] <> FieldLength then Inc(SpaceShip[1]);
    dirLeft:  if SpaceShip[1] <> 1           then Dec(SpaceShip[1]);
  end;
  SpaceShipDirection := dirNone;
end;

procedure MoveProjectile;
var CounterA, CounterB :byte;
begin
  CounterA := 0;
  while CounterA <= ProjectileCount-1 do
  begin
    Dec(Projectile[CounterA, 2]);
    if Projectile[CounterA, 2] = 0 then
    begin
      Dec(ProjectileCount);
      for CounterB := CounterA to ProjectileCount-1 do Projectile[CounterB] := Projectile[CounterB + 1];
      SetLength(Projectile, ProjectileCount);
    end
    else Inc(CounterA);
  end;
end;

procedure CreateEnemy;
var FlagError :boolean;
    CounterA :byte;
begin
  Randomize;
  Inc(EnemyCount);
  SetLength(Enemy, EnemyCount);
  Enemy[EnemyCount-1, 2] := 2;
  repeat
    FlagError := False;
    Enemy[EnemyCount-1, 1] := Random(FieldLength) + 1;
    if EnemyCount > 1 then for CounterA := 0 to EnemyCount-2 do if Enemy[CounterA, 1] = Enemy[EnemyCount-1, 1] then FlagError := True;
  until not FlagError;
end;

procedure MoveEnemy;
var CounterA :byte;
begin
  if EnemyCount <> 0 then for CounterA := 0 to EnemyCount-1 do Inc(Enemy[CounterA, 2]);
end;

procedure RegHit;
var CounterA, CounterB :byte;
begin
  Dec(ProjectileCount);
  Dec(EnemyCount);
  for CounterA := ProjectileHit to ProjectileCount-1 do Projectile[CounterA] := Projectile[CounterA + 1];
  for CounterB := EnemyHit      to EnemyCount-1      do Enemy[CounterB]       := Enemy[CounterB + 1];
  SetLength(Projectile, ProjectileCount);
  SetLength(Enemy, EnemyCount);
  ProjectileHit := -1;
  EnemyHit      := -1;
end;

procedure CheckHit;
var CounterA, CounterB :byte;
    FlagInsufficientCount :boolean;
begin
  FlagInsufficientCount := (ProjectileCount = 0) or (EnemyCount = 0);
  if not FlagInsufficientCount then
  begin
    CounterA := 0;
    while (CounterA <= ProjectileCount-1) and not FlagInsufficientCount do
    begin
      CounterB := 0;
      while (CounterB <= EnemyCount-1) and not FlagInsufficientCount do
      begin
        if (Projectile[CounterA, 2] = Enemy[CounterB, 2]) and (Projectile[CounterA, 1] = Enemy[CounterB, 1]) then
        begin
          FlagHit       := True;
          ProjectileHit := CounterA;
          EnemyHit      := CounterB;
          Inc(CurrentScore);
          RegHit;
          FlagInsufficientCount := (ProjectileCount = 0) or (EnemyCount = 0);
        end
        else Inc(CounterB);
      end;
      if FlagHit then FlagHit := False
      else Inc(CounterA);
    end;
  end;
end;

procedure CheckDefeat;
var CounterA :byte;
begin
  for CounterA := 0 to EnemyCount-1 do if Enemy[CounterA, 2] = (FieldWidth - 1) then FlagDefeat := True;
end;

procedure CheckWin;
begin
  if CurrentScore = ScoreGoal then FlagWin := True;
end;

procedure GameEndingValues;
begin
  SetLength(Projectile, 0);
  SetLength(Enemy, 0);
end;

end.
