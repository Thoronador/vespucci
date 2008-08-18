unit Data;

interface

uses
  Nation, Language, Units;

const
{$IFDEF Win32}
  path_delimiter = '\';
{$ELSE}
  path_delimiter = '/';
{$ENDIF}
  data_path = 'data' + path_delimiter;
  america_map_path = data_path +'america'+path_delimiter+'america.vmd';
  img_path = data_path+'img'+path_delimiter;
  good_img_path = img_path+'goods'+path_delimiter;
  terrain_img_path = img_path+'terrain'+path_delimiter;
  unit_img_path = img_path+'units'+path_delimiter;

type
  TData = class
            private
              Year: Integer;
              Autumn: Boolean;
              Nations: array [cMin_Nations..cMaxIndian] of TNation;
              //the units
              m_Units: array of TUnit;
              Unit_length: Integer;
              Unit_max: Integer;
            public
              player_nation: Integer;
              constructor Create(var aLang: TLanguage);
              destructor Destroy;
              function GetYear: Integer;
              function IsAutumn: Boolean;
              function GetNation(const count: Integer): TNation;
              function GetNationPointer(const count: Integer): PNation;
              procedure AdvanceYear;
              function NewUnit(const TypeOfUnit: TUnitType; const ANation: Integer; X: Integer=1; Y: Integer=1): TUnit;
              function GetFirstUnitInXY(const x, y: Integer): TUnit;
              function GetFirstLazyUnit(const num_Nation: Integer): TUnit;
              procedure NewRound(const num_Nation: Integer);
          end;//class

implementation

constructor TData.Create(var aLang: TLanguage);
var i: Integer;
begin
  player_nation:= cNationEngland;
  Year:= 1492;
  Autumn:= False;
  Nations[cNationEngland]:= TEuropeanNation.Create(cNationEngland, aLang.GetNationName(cNationEngland), 'Walter Raleigh');
  Nations[cNationFrance]:= TEuropeanNation.Create(cNationFrance, aLang.GetNationName(cNationFrance), 'Jacques Cartier');
  Nations[cNationSpain]:= TEuropeanNation.Create(cNationSpain, aLang.GetNationName(cNationSpain), 'Christoph Columbus');
  Nations[cNationHolland]:= TEuropeanNation.Create(cNationHolland, aLang.GetNationName(cNationHolland), 'Michiel De Ruyter');
  for i:= cMinIndian to cMaxIndian do
      Nations[i]:= TIndianNation.Create(i, aLang.GetNationName(i));

  //units
  Unit_length:= 0;
  SetLength(m_Units, Unit_length);
  Unit_max:= -1;
end;//construc

destructor TData.Destroy;
var i: Integer;
begin
  for i:= cMin_Nations to cMaxIndian do
    if Nations[i]<>nil then Nations[i].Destroy;
  for i:=Unit_max downto 0 do
    if m_Units[i]<>nil then m_Units[i].Destroy;
end;//destruc

function TData.GetYear: Integer;
begin
  Result:= Year;
end;//func

function TData.IsAutumn: Boolean;
begin
  Result:= Autumn;
end;//func

procedure TData.AdvanceYear;
begin
  if Year<1600 then Year:= Year+1
  else begin
    if Autumn then
    begin
      //if we have autumn, start next year and set season to spring
      Year:= Year+1;
      Autumn:= False;
    end
    else Autumn:= True;
  end;//else
end;//proc

function TData.GetNation(const count: Integer): TNation;
begin
  if ((count>cMaxIndian) or (count<cMin_Nations)) then
    Result:= nil
  else
    Result:= Nations[count];
end;//func

function TData.GetNationPointer(const count: Integer): PNation;
begin
  if ((count>cMaxIndian) or (count<cMin_Nations)) then
    Result:= nil
  else
    Result:= @Nations[count];
end;//func

function TData.NewUnit(const TypeOfUnit: TUnitType; const ANation: Integer; X: Integer=1; Y: Integer=1): TUnit;
var i: Integer;
begin
  if (Unit_max+2>Unit_length) then
  begin
    SetLength(m_Units, Unit_length+4);
    Unit_length:= Unit_length+4;
    //"initialize" new units
    for i:=1 to 4 do
      m_Units[Unit_length-i]:= nil;
  end;//if
  m_Units[Unit_max+1]:= TUnit.Create(TypeOfUnit, GetNationPointer(ANation), X, Y);
  Unit_max:= Unit_max+1;
  Result:= m_Units[Unit_max+1];
end;//proc

function TData.GetFirstUnitInXY(const x, y: Integer): TUnit;
var i: Integer;
begin
  Result:= nil;
  for i:= 0 to Unit_max do
    if ((m_Units[i].GetPosX=x) and (m_Units[i].GetPosY=y)) then
    begin
      Result:= m_Units[i];
      break;
    end;//if
end;//func

function TData.GetFirstLazyUnit(const num_Nation: Integer): TUnit;
var i: Integer;
begin
  Result:= nil;
  for i:= 0 to Unit_max do
    if m_Units[i]<>nil then
    begin
      if ((m_Units[i].MovesLeft>0) and (m_Units[i].GetNation^.GetCount=num_Nation)) then
      begin
        Result:= m_Units[i];
        break;
      end;//if
    end;//if
end;//func

procedure TData.NewRound(const num_Nation: Integer);
var i: Integer;
begin
  //call NewRound method for every unit of that nation
  for i:= 0 to Unit_max do
    if m_Units[i]<>nil then
      if (m_Units[i].GetNation^.GetCount=num_Nation) then
        m_Units[i].NewRound;
end;//func

end.