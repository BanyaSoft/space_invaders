unit UnitInterface;

interface

uses
  Windows, UnitErrorHandler, UnitVisualization, UnitGameMechanics;

procedure MenuInterface;     stdcall;
procedure MainGameInterface; stdcall;
procedure GameEndInterface;  stdcall;

var FlagEndInteraction :boolean;
    FlagCheckOneInput, FlagCheckOnePausedFrame  :boolean;

implementation

type TDifficulty = (difNone, difEasy, difMedium, difHard);

const W_KEY = $57;
      A_KEY = $41;
      S_KEY = $53;
      D_KEY = $44;

var NumberEvent, NumberRead :LongWord;
    MenuRecord :INPUT_RECORD;
    NewCursorCoord :COORD;
    TextDifficulty :byte = 0;
    CurrDifficulty :TDifficulty;


procedure MenuInteraction;
begin
  if not GetNumberOfConsoleInputEvents(hStdIn, NumberEvent) then ShowError('MENU_INTERFACE');
  if NumberEvent > 0 then
  begin
    if not ReadConsoleInput(hStdIn, MenuRecord, sizeof (INPUT_RECORD), NumberRead) then ShowError('MENU_INTERFACE');
    if (MenuRecord.EventType = KEY_EVENT) then
    begin
      if (MenuRecord.Event.KeyEvent.bKeyDown = True) then
      begin
        case MenuRecord.Event.KeyEvent.wVirtualKeyCode of
          D_KEY:
          begin
            GetCurrentScreenBufferInfo;
            NewCursorCoord.X := ScreenBufferInfo.dwCursorPosition.X + 1;
            NewCursorCoord.Y := ScreenBufferInfo.dwCursorPosition.Y;
            if NewCursorCoord.X <= FrameRight then
              if not SetConsoleCursorPosition(hStdOut, NewCursorCoord) then ShowError('MENU_INTERFACE');
          end;
          A_KEY:
          begin
            GetCurrentScreenBufferInfo;
            NewCursorCoord.X := ScreenBufferInfo.dwCursorPosition.X - 1;
            NewCursorCoord.Y := ScreenBufferInfo.dwCursorPosition.Y;
            if NewCursorCoord.X >= FrameLeft then
              if not SetConsoleCursorPosition(hStdOut, NewCursorCoord) then ShowError('MENU_INTERFACE');
          end;
          W_KEY:
          begin
            GetCurrentScreenBufferInfo;
            NewCursorCoord.X := ScreenBufferInfo.dwCursorPosition.X;
            NewCursorCoord.Y := ScreenBufferInfo.dwCursorPosition.Y - 1;
            if NewCursorCoord.Y >= FrameTop then
              if not SetConsoleCursorPosition(hStdOut, NewCursorCoord) then ShowError('MENU_INTERFACE');
          end;
          S_KEY:
          begin
            GetCurrentScreenBufferInfo;
            NewCursorCoord.X := ScreenBufferInfo.dwCursorPosition.X;
            NewCursorCoord.Y := ScreenBufferInfo.dwCursorPosition.Y + 1;
            if NewCursorCoord.Y <= FrameBottom then
              if not SetConsoleCursorPosition(hStdOut, NewCursorCoord) then ShowError('MENU_INTERFACE');
          end;
          VK_RETURN:
          begin
            GetCurrentScreenBufferInfo;
            case ScreenBufferInfo.dwCursorPosition.Y of
              10:
              begin
                CurrDifficulty := difEasy;
                TextDifficulty := 1;
              end;
              11:
              begin
                CurrDifficulty := difMedium;
                TextDifficulty := 2;
              end;
              12:
              begin
                CurrDifficulty := difHard;
                TextDifficulty := 3;
              end;
              16: if (CurrDifficulty <> difNone) then FlagEndInteraction := True;
            end;
            if not FlagEndInteraction then MenuNewFrame(TextDifficulty);
          end;
          VK_ESCAPE: FreeConsole;
        end;
      end;
    end
    //else if (MenuRecord.EventType = WINDOW_BUFFER_SIZE_EVENT) then ShowError('DON''T_RESIZE_WINDOW_YOU,_SILLY_QA_!_!_!')
    else sleep(100);
  end;
end;

procedure MenuInterface;
begin
  MenuInitialization;
  MenuStartingFrame;
  CurrDifficulty := difNone;
  TextDifficulty := 0;
  FlagEndInteraction := False;
  FlushConsoleInputBuffer(hStdIn);

  while not FlagEndInteraction do
  begin
    MenuInteraction;
  end;
end;

procedure MainGameInteraction;
begin
  if not GetNumberOfConsoleInputEvents(hStdIn, NumberEvent) then ShowError('MAIN_GAME_INTERFACE');
  if NumberEvent > 0 then
  begin
    if not ReadConsoleInput(hStdIn, MenuRecord, sizeof (INPUT_RECORD), NumberRead) then ShowError('MAIN_GAME_INTERFACE');
    if (MenuRecord.EventType = KEY_EVENT) and (MenuRecord.Event.KeyEvent.bKeyDown = True) then
    begin
      begin
        case MenuRecord.Event.KeyEvent.wVirtualKeyCode of
          D_KEY:
          begin
            SpaceShipDirection := dirRight;
            FlagCheckOneInput  := True;
          end;
          A_KEY:
          begin
            SpaceShipDirection := dirLeft;
            FlagCheckOneInput  := True;
          end;
          VK_SPACE:
          begin
            FlagShoot := True;
            FlagCheckOneInput := True;
          end;
          VK_ESCAPE: FreeConsole;
        end;
      end;
    end;
    //if not (MenuRecord.EventType = WINDOW_BUFFER_SIZE_EVENT) then ShowError('DON''T_RESIZE_WINDOW_YOU,_SILLY_QA_!_!_!');
  end;
end;

procedure MainGameInterface;
begin
  if hStdOut = 0 then GetHandle;

  case CurrDifficulty of
    difEasy:   EnemySpeed := 40;
    difMedium: EnemySpeed := 20;
    difHard:   EnemySpeed := 10;
  end;

  GameStartingValues;
  MainGameInitialization;
  MainGameNewFrame;
  FlagEndInteraction := False;
  FlagCheckOneInput  := False;


  while not FlagEndInteraction do
  begin
    if TickCount mod FrameSpeed = FrameSpeed-1 then
    begin
      FlagCheckOneInput       := False;
      FlagCheckOnePausedframe := False;
      ClearScreenAttribute;

      MoveSpaceShip;
      MoveProjectile;

      if FlagShoot and (ProjectileCharge = chReady) then CreateProjectile;
      if (ProjectileCharge <> chReady) and (FrameCount mod ChargeSpeed = ChargeSpeed-1) then ProjectileCharge := Succ(ProjectileCharge);
      CheckHit;

      If FrameCount mod EnemySpeed = EnemySpeed-1 then MoveEnemy;
      if EnemyCount <= 6 then CreateEnemy;
      CheckHit;

      CheckDefeat;
      CheckWin;
      if FlagWin or FlagDefeat then FlagEndInteraction := True;

      if not FlagEndInteraction then
      begin
        MainGameNewFrame;
        //FlushConsoleInputBuffer(hStdIn);
        TickCount := 0;
        Inc(FrameCount);
      end;
    end
    else
    begin
      if not FlagCheckOneInput then MainGameInteraction;
      Sleep(10);
      Inc(TickCount);
    end
  end;
end;

procedure GameEndInterface;
begin
  GameEndInitialization;
  GameEndStartingFrame;
end;

end.

