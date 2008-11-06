unit Callbacks;

interface

uses
  Units, Map, Data, Colony, Goods, Nation;

const
  CBT_ANY = 0;
  CBT_EXIT = 1;
  CBT_LANDFALL = 2;
  CBT_BUILD_COLONY = 3;
  CBT_SAVE_GAME = 4;
  CBT_LOAD_GAME = 5;
  CBT_JOB_CHANGE = 6;
  CBT_EURO_PORT_UNIT = 7;
  CBT_EURO_PORT_BUY = 8;
  CBT_EURO_PORT_TRAIN = 9;
  CBT_RENAME_COLONY = 10;
  CBT_ABANDON_COLONY = 11;

type
  TExitCallback = procedure (const option: Integer);
  TLandfallCallback = function (const option: Integer; AShip: TUnit; const AType: TUnitType; const x,y: Byte; AMap: TMap): Boolean;

  TLandfallData = record
                    cbLandfall: TLandfallCallback;
                    Ship: TUnit;
                    UType: TUnitType;
                    x,y: Byte;
                    AMap: TMap;
                  end;//rec
  TBuildColonyData = record
                        x,y: Byte;
                        //ColName: ShortString; //delivered through input text
                        num_nation: Byte;
                        founder: TUnit;
                        AMap: TMap;
                        AData: TData;
                      end;//rec
  TSaveGameData = record
                    AData: TData;
                  end;//rec
  TLoadGameData = record
                    AData: TData;
                  end;//rec
  TJobChangeData = record
                     x_shift, y_shift: ShortInt;
                     AColony: TColony;
                   end;//rec
  TEuroPortUnitData = record
                        AUnit: TUnit;
                        EuroNat: TEuropeanNation;
                      end;//rec
  TEuroBuyData = record
                   AData: TData;
                   EuroNat: TEuropeanNation;
                 end;//rec
  TEuroTrainData = record
                     AData: TData;
                     EuroNat: TEuropeanNation;
                   end;//rec
  TRenameColonyData = record
                        AColony: TColony;
                      end;//rec
  TAbandonColonyData = record
                         AColony: TColony;
                         AData: TData;
                       end;//rec

  TCallbackRec = record
                   option: Integer;
                   inputText: ShortString;
                   _type: LongInt;
                   case LongInt of
                     0: (Data: Pointer);
                     1: (cbExit: TExitCallback);
                     2: (Landfall: TLandfallData);
                     3: (BuildColony: TBuildColonyData);
                     4: (SaveGame: TSaveGameData);
                     5: (LoadGame: TLoadGameData);
                     6: (JobChange: TJobChangeData);
                     7: (EuroPort: TEuroPortUnitData);
                     8: (EuroBuy: TEuroBuyData);
                     9: (EuroTrain: TEuroTrainData);
                     10: (RenameColony: TRenameColonyData);
                     11: (AbandonColony: TAbandonColonyData);
                 end;//rec

const
  cEmptyCallback: TCallbackRec =(option: 0; inputText: ''; _type: CBT_ANY; Data: nil);

  procedure CBF_Exit(const option: Integer);
  function CBF_Landfall(const option: Integer; AShip: TUnit; const AType: TUnitType; const x,y: Byte; AMap: TMap): Boolean;

  function HandleCallback(const cbRec: TCallbackRec): Boolean;

implementation

procedure CBF_Exit(const option: Integer);
begin
  if option=1 then halt;
end;//func

function CBF_Landfall(const option: Integer; AShip: TUnit; const AType: TUnitType; const x,y: Byte; AMap: TMap): Boolean;
begin
  if ((option=1) and (AShip<>nil)) then Result:= AShip.UnloadUnit(AType, x,y, AMap)
  else Result:= False;
end;//func

function CBF_BuildColony(const x,y: Byte; const num_nation: Byte; ColName: ShortString; founder: TUnit; AMap: TMap; AData: TData): Boolean;
begin
  Result:= False;
  if ((ColName='') or (founder=nil) or (AMap=nil) or (AData=nil) or (x>=cMap_X-1)
      or (y>=cMap_Y-1) or (x=0) or (y=0)) then Exit;
  if founder.WarpToXY(x,y, AMap) then
  begin
    (AData.NewColony(x,y, num_nation, ColName)).SetUnitInField(-1, -1, founder);
    //founder.SetLocation(ulInColony);
    AMap.tiles[x,y].CreateRoad;
    Result:= True;
  end;//if
end;//func

function CBF_SaveGame(const option: Integer; AData: TData): Boolean;
var err_str: string;
begin
  err_str:= 'not saved.';
  if (option>0) and (option<65536) then
  begin
    if (AData<>nil) then
    begin
      Result:= AData.SaveData(option, err_str);
    end//if
    else Result:= False;
  end//if
  else Result:= False;
  WriteLn('SaveGame errors: '+err_str);
end;//func

function CBF_LoadGame(const option: Integer; AData: TData): Boolean;
var err_str: string;
begin
  err_str:= 'not loaded.';
  if ((option>0) and (option<65536) and (AData<>nil)) then
  begin
    Result:= AData.LoadData(option, err_str);
  end//if
  else Result:= False;
  WriteLn('LoadGame errors: '+err_str);
end;//if

function CBF_JobChange(const option: Integer; const cbRec: TCallbackRec): Boolean;
var new_good: TGoodType;
begin
  Result:= False;
  if ((abs(cbRec.JobChange.x_shift)>1) or (abs(cbRec.JobChange.y_shift)>1)
     or (cbRec.JobChange.AColony=nil)) then Exit;
  if cbRec.JobChange.AColony.GetUnitInField(cbRec.JobChange.x_shift, cbRec.JobChange.y_shift)=nil then Exit;
  case option of
    0: new_good:= gtFood;
    1: new_good:= gtSugar;
    2: new_good:= gtTobacco;
    3: new_good:= gtCotton;
    4: new_good:= gtFur;
    5: new_good:= gtWood;
    6: new_good:= gtOre;
    7: new_good:= gtSilver;
  else //should not happen
    new_good:= gtFood;
  end;//case
  cbRec.JobChange.AColony.SetUnitInField(cbRec.JobChange.x_shift, cbRec.JobChange.y_shift,
        cbRec.JobChange.AColony.GetUnitInField(cbRec.JobChange.x_shift, cbRec.JobChange.y_shift), new_good);
  Result:= True;
end;//func

function CBF_EuroPortUnit(const option: Integer; AUnit: TUnit; EuroNat: TEuropeanNation): Boolean;
begin
  Result:= False;
  if ((AUnit=nil) or (EuroNat=nil)) then Exit;
  case option of
    0: begin //ship
         if (AUnit.GetState=usWaitingForShip) then AUnit.SetState(usNormal)
         else AUnit.SetState(usWaitingForShip);
       end;
    1: //muskets
       if not EuroNat.IsBoycotted(gtMusket) then
       begin
         if (AUnit.HasMuskets) then
         begin
           EuroNat.SellGood(gtMusket, 50);
           AUnit.GiveMuskets(False);
         end//if
         else begin
           if EuroNat.GetGold>EuroNat.GetPrice(gtMusket, False)*50 then
           begin
             EuroNat.BuyGood(gtMusket, 50);
             AUnit.GiveMuskets(True);
           end;//if
         end;//if
       end; //if
    2: //horses
       if not EuroNat.IsBoycotted(gtHorses) then
       begin
         if (AUnit.HasHorses) then
         begin
           EuroNat.SellGood(gtHorses, 50);
           AUnit.GiveHorses(False);
         end//if
         else begin
           if EuroNat.GetGold>EuroNat.GetPrice(gtHorses, False)*50 then
           begin
             EuroNat.BuyGood(gtHorses, 50);
             AUnit.GiveHorses(True);
           end;//if
         end;//if
       end; //if
    3: begin//tools
         if not EuroNat.IsBoycotted(gtTool) then
         begin
           if (AUnit.GetToolAmount>0) then
           begin
             EuroNat.SellGood(gtTool, AUnit.GetToolAmount);
             AUnit.GiveTools(0);
           end//if
           else begin
             if (EuroNat.GetGold>EuroNat.GetPrice(gtTool, False)*(100-AUnit.GetToolAmount)) then
             begin
               EuroNat.BuyGood(gtTool, 100-AUnit.GetToolAmount);
               AUnit.GiveTools(100);
             end;//if
           end;//if
         end;//if no boycott
       end;//3 (tools)
    4: ;//no changes at all
  end;//case
  Result:= True;
end;//func

function CBF_EuroPortBuy(const option: Integer; AData: TData; EuroNat: TEuropeanNation): Boolean;
var buy_unit: TUnitType;
    new_unit: TUnit;
    start_x, start_y: Byte;
begin
  Result:= (option=0);
  if (EuroNat=nil) or (AData=nil) or (option=0) then Exit;
  case option of
    1: buy_unit:= utCaravel;
    2: buy_unit:= utTradingShip;
    3: buy_unit:= utGalleon;
    4: buy_unit:= utPrivateer;
    5: buy_unit:= utFrigate;
  else buy_unit:= utCriminal;//should not happen
  end;//case
  if buy_unit=utCriminal then Exit;
  //buy it
  If EuroNat.GetGold>=cShipPrices[buy_unit] then
  begin
    if length(AData.GetAllShipsInEurope(EuroNat.GetCount))>0 then
    begin
      new_unit:= AData.GetAllShipsInEurope(EuroNat.GetCount)[0];
      start_x:= new_unit.GetPosX;
      start_y:= new_unit.GetPosY;
    end//if
    else begin
      start_x:= cMap_X-1;
      start_y:= cMap_Y div 2;
    end;//else
    new_unit:= AData.NewUnit(buy_unit, EuroNat.GetCount, start_x, start_y);
    new_unit.SetLocation(ulEurope);
    EuroNat.DecreaseGold(cShipPrices[buy_unit]);
    Result:= True;
  end;//if
end;//func

function CBF_EuroPortTrain(const option: Integer; AData: TData; EuroNat: TEuropeanNation): Boolean;
var train_unit: TUnitType;
    new_unit: TUnit;
begin
  Result:= False;
  if (EuroNat=nil) or (AData=nil) or (option=0) then Exit;
  case option of
    1: train_unit:= utFarmer;
    2: train_unit:= utFisher;
    3: train_unit:= utSilverMiner;
    4: train_unit:= utWoodcutter;
    5: train_unit:= utOreMiner;
    6: train_unit:= utPreacher;
    7: train_unit:= utStatesman;
    8: train_unit:= utCarpenter;
    9: train_unit:= utDistiller;
    10: train_unit:= utWeaver;
    11: train_unit:= utTobacconist;
    12: train_unit:= utFurTrader;
    13: train_unit:= utSmith;
    14: train_unit:= utWeaponSmith;
    15: train_unit:= utPioneer;
    16: train_unit:= utMissionary;
    17: train_unit:= utRegular;
  else train_unit:= utCriminal;//should not happen here
  end;//case
  if train_unit=utCriminal then Exit;
  if EuroNat.GetGold>cUnitPrices[train_unit] then
  begin
    new_unit:= AData.NewUnit(train_unit, EuroNat.GetCount, cMap_X-1, cMap_Y div 2);
    new_unit.SetLocation(ulEurope);
    new_unit.SetState(usWaitingForShip);
    EuroNat.DecreaseGold(cUnitPrices[train_unit]);
    Result:= True;
  end;//if
end;//func

function CBF_RenameColony(const ACol: TColony; const NewName: ShortString): Boolean;
begin
  if (ACol=nil) then
  begin
    Result:= False;
    Exit;
  end;//if
  ACol.SetName(NewName);
  Result:= True;
end;//func

function CBF_AbandonColony(const option: Integer; ACol: TColony; AData: TData): Boolean;
begin
  Result:= False;
  if ((ACol=nil) or (AData=nil)) then Exit;
  if option=1 then
  begin
    Result:= AData.DeleteColony(ACol.GetPosX, ACol.GetPosY);
  end;//if
end;//func

function HandleCallback(const cbRec: TCallbackRec): Boolean;
begin
  case cbRec._type of
    CBT_ANY: Result:=True; //do nothing here
    CBT_EXIT: begin
                cbRec.cbExit(cbRec.option);
                Result:= True;
              end;
    CBT_LANDFALL: Result:= cbRec.Landfall.cbLandfall(cbRec.option, cbRec.Landfall.Ship,
                    cbRec.Landfall.UType, cbRec.Landfall.x, cbRec.Landfall.y,
                    cbRec.Landfall.AMap);
    CBT_BUILD_COLONY: Result:= CBF_BuildColony(cbRec.BuildColony.x, cbRec.BuildColony.y,
                        cbRec.BuildColony.num_nation, cbRec.inputText,
                        cbRec.BuildColony.founder, cbRec.BuildColony.AMap,
                        cbRec.BuildColony.AData);
    CBT_SAVE_GAME: Result:= CBF_SaveGame(cbRec.option, cbRec.SaveGame.AData);
    CBT_LOAD_GAME: Result:= CBF_LoadGame(cbRec.option, cbRec.LoadGame.AData);
    CBT_JOB_CHANGE: Result:= CBF_JobChange(cbRec.option, cbRec);
    CBT_EURO_PORT_UNIT: Result:= CBF_EuroPortUnit(cbRec.option, cbRec.EuroPort.AUnit, cbRec.EuroPort.EuroNat);
    CBT_EURO_PORT_BUY: Result:= CBF_EuroPortBuy(cbRec.option, cbRec.EuroBuy.AData, cbRec.EuroBuy.EuroNat);
    CBT_EURO_PORT_TRAIN: Result:= CBF_EuroPortTrain(cbRec.option, cbRec.EuroTrain.AData, cbRec.EuroTrain.EuroNat);
    CBT_RENAME_COLONY: Result:= CBF_RenameColony(cbRec.RenameColony.AColony, cbRec.inputText);
    CBT_ABANDON_COLONY: Result:= CBF_AbandonColony(cbRec.option, cbRec.AbandonColony.AColony, cbRec.AbandonColony.AData);
  else
    Result:= False; //unknown callback type or type not supported/ implemented
  end;//case
end;//proc

end.
