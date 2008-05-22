unit Gui;

interface

uses
  Map, GL, GLU, GLUT, Terrain;

const
  x_Fields = 15;
  y_Fields = 12;
  FieldWidth = 32;
  BarWidth = 160; //bar width in px

  PixelWidth = 0.03125; // =1/32, i.e. 1px

  Minimap_x_Fields = 56;
  Minimap_y_Fields = 39;

  BorderWidth: Single = 0.0625; // =1/16, i.e. 2px
  BorderColour: array[0..2] of Byte = (0,0,0); //black

  cMapColour: array [TTerrainType] of array [0..2] of Byte=(
       (224, 224, 224), //ttArctic
       (32, 44, 136), //ttSea
       (80, 80, 255), //ttOpenSea (orig.: same as Sea)
       (132, 112, 80), //ttPlains
       (28, 108, 16), //ttGrassland
       (136, 140, 60), //ttPrairie
       (116, 164, 76), //ttSavannah
       (52, 72, 156), //ttMarsh
       (116, 164, 76), //ttSwamp (same as ttSavannah)
       (204, 176, 140), //ttDesert
       (184, 184, 64), //ttTundra
       (184, 184, 64), //ttBoreal (same as ttTundra)
       (52, 72, 156), //ttWetland (same as ttMarsh)
       (201, 175, 138), //ttScrubForest
       (136, 140, 60), //ttBroadleaf (same as ttPrairie)
       (130, 112, 79), //ttMixedForest (nearly same as ttPlains)
       (28, 107, 18), //ttConiferForest
       (117, 164, 77), //ttRainForest (nearly same as ttSwamp)
       (116, 164, 76), //ttTropicalForest (same as ttSavannah)
       (184, 160, 124), //ttHills
       (216, 204, 172)  //ttMountains
      );

  cWindowCaption = 'Vespucci v0.01';

  //Keys
  KEY_ESCAPE = 27;
  KEY_LEFT = 37;
  KEY_UP = 38;
  KEY_RIGHT = 39;
  KEY_DOWN = 40;

  //maybe starts with 97, maybe with 49, try it
  KEY_NUMPAD1 = 49;
  KEY_NUMPAD2 = 50;
  KEY_NUMPAD3 = 51;
  KEY_NUMPAD4 = 52;
  //KEY_NUMPAD5 = 53;
  KEY_NUMPAD6 = 54;
  KEY_NUMPAD7 = 55;
  KEY_NUMPAD8 = 56;
  KEY_NUMPAD9 = 57;

type

  TGui = class
    private
      WindowHeight, WindowWidth: Integer;
      procedure InitGLUT;
    public
      m_Map: TMap;
      OffsetX, OffsetY: Integer;
      MiniMapOffset_Y: Integer;
      constructor Create;
      destructor Destroy;
      procedure KeyFunc(Key: Byte; x, y: Longint); cdecl;
      procedure Resize(Width, Height: Longint); cdecl;
      procedure Start;
      procedure Draw; cdecl;
      procedure CenterOn(const x, y: Integer);
  end;//class TGui
  PGui = ^TGui;

var
  ptrGUI: PGui;

implementation

constructor TGui.Create;
begin
  inherited Create;
  OffsetX:= 0; OffsetY:= 0;
  MiniMapOffset_Y:= 0;
  m_Map:= TMap.Create;
  m_Map.Generate(0.7);

  ptrGui:= @self;
end;//constructor

destructor TGui.Destroy;
begin
  m_Map.Destroy;
  inherited Destroy;
end;//destructor

procedure TGui.KeyFunc(Key: Byte; x, y: LongInt); cdecl;
begin
  case UpCase(char(Key)) of
    'F': ;//fortify
    'S': ;//sentry
    ' ': ;//space skips unit
    'C': begin
           CenterOn(25, 35);//just for testing, yet
         end;
  end;
  case Key of
    KEY_LEFT, KEY_NUMPAD4: if (OffsetX>0) then OffsetX:= OffsetX-1;{Move left}
    KEY_RIGHT, KEY_NUMPAD6: if (OffsetX<cMap_X-x_Fields) then OffsetX:= OffsetX+1;{Move right}
    KEY_DOWN, KEY_NUMPAD2: if (OffsetY<cMap_y-y_Fields) then OffsetY:= OffsetY+1; {Move down}
    KEY_UP, KEY_NUMPAD8: if (OffsetY>0) then OffsetY:= OffsetY-1;

    KEY_ESCAPE: halt; {exit}
  end;
end;//proc

procedure TGui.Resize(Width, Height: Longint); cdecl;
begin
  WindowWidth:= Width;
  WindowHeight:= Height;
end;//proc

procedure TGui.InitGLUT;
begin
// DoImplementThisStuff;
  WriteLn('glEnable-like stuff');
   // Enable backface culling
  glEnable(GL_CULL_FACE);

  // Set up depth buffer
  glEnable(GL_DEPTH_TEST);
  glDepthFunc(GL_LESS);
  //Starting
  WriteLn('glutMainLoop');
  glutMainLoop;
end;//proc

procedure TGui.Start;
begin
  InitGLUT;
end;//proc Start

procedure TGui.Draw; cdecl;
var i, j: Integer;
begin
  glLoadIdentity;
  glViewport(0,0, 32*x_Fields+BarWidth, 32*y_Fields+16+16);
  glOrtho(0.0, 20.0, -0.5, 12.5, -1.0, 1.0);

  glClearColor(0.83, 0.66, 0.39,0.0);//set "wooden" color as clear color...
                                     //saves us from drawing wooden bar
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

  //draw borders
  glBegin(GL_QUADS);
    glColor3ubv(@BorderColour);
    //vertical border between map/ sidebar
    glVertex2f(x_Fields, 0.0);
    glVertex2f(x_Fields+BorderWidth, 0.0);
    glVertex2f(x_Fields+BorderWidth, y_Fields);
    glVertex2f(x_Fields, y_Fields);

    //horizontal border between map & (later to come) menu
    glVertex2f(0.0, y_Fields);
    glVertex2f(x_Fields+ BarWidth*PixelWidth, y_Fields);
    glVertex2f(x_Fields+ BarWidth*PixelWidth, y_Fields+BorderWidth);
    glVertex2f(0.0, y_Fields+BorderWidth);

    //horizontal bar between minimap & rest of bar
    glVertex2f(x_Fields, y_Fields - 2*BorderWidth -2*PixelWidth*MiniMap_y_Fields);
    glVertex2f(x_Fields, y_Fields - 3*BorderWidth -2*PixelWidth*MiniMap_y_Fields);
    glVertex2f(x_Fields+ BarWidth*PixelWidth,
               y_Fields - 3*BorderWidth -2*PixelWidth*MiniMap_y_Fields);
    glVertex2f(x_Fields+ BarWidth*PixelWidth,
               y_Fields - 2*BorderWidth -2*PixelWidth*MiniMap_y_Fields);
  glEnd;//borders

  //draw the real map
  glBegin(GL_QUADS);
    for i:= OffsetX to OffSetX +x_Fields-1 do
      for j:= OffSetY to OffsetY +y_Fields-1 do
      begin
        case m_Map.tiles[i,j].m_Type of
          ttArctic: glColor3f(1.0, 1.0, 1.0);//white
          ttSea: glColor3f(0.0, 0.0, 1.0);//blue
          ttOpenSea: glColor3f(0.3, 0.3, 1.0);//lighter blue
          ttHills, ttMountains: glColor3f(0.5, 0.0, 0.0);
        else
          glColor3f(0.3, 1.0, 0.3);//some greenish stuff
        end;//case
        glVertex2f(i-OffsetX, -j+y_Fields+OffsetY);//j: f(j)=-j+y_Fields+OffsetY
        glVertex2f(i-OffsetX, -j-1+y_Fields+OffsetY);//j+1
        glVertex2f(i-OffsetX+1, -j-1+y_Fields+OffsetY);//j+1
        glVertex2f(i-OffsetX+1, -j+y_Fields+OffsetY);//j
      end;//for
  glEnd; //map

  //draw the MiniMap

  //draw border (as a rectangle larger than minimap)
  glBegin(GL_QUADS);
    glColor3ub(157, 86, 20);
    glVertex2f(x_Fields+ 22*PixelWidth, y_Fields);
    glVertex2f(x_Fields+ 22*PixelWidth,
               y_Fields-2*BorderWidth - Minimap_y_Fields*2*PixelWidth);
    glVertex2f(x_Fields+ (BarWidth-22)*PixelWidth,
               y_Fields-2*BorderWidth - Minimap_y_Fields*2*PixelWidth);
    glVertex2f(x_Fields+ (BarWidth-22)*PixelWidth, y_Fields);
  glEnd;

  //draw the actual minimap
  glBegin(GL_QUADS);
    for i:=0 to MiniMap_x_Fields-1 do
      for j:= MiniMapOffset_Y to MiniMapOffset_Y +MiniMap_y_Fields-1 do
      begin
        glColor3ubv(@cMapColour[m_Map.tiles[i,j].m_Type,0]);
        glVertex3f(x_Fields + (24+2*i)*PixelWidth,
                   y_Fields-BorderWidth - (j-MinimapOffset_Y)*2*PixelWidth, 0.1);
        glVertex3f(x_Fields + (24+2*i)*PixelWidth,
                   y_Fields-BorderWidth - (j-MinimapOffset_Y+1)*2*PixelWidth, 0.1);
        glVertex3f(x_Fields + (26+2*i)*PixelWidth,
                   y_Fields-BorderWidth - (j-MinimapOffset_Y+1)*2*PixelWidth, 0.1);
        glVertex3f(x_Fields + (26+2*i)*PixelWidth,
                   y_Fields-BorderWidth - (j-MinimapOffset_Y)*2*PixelWidth, 0.1);
      end;//for
  glEnd;//MiniMap

  glutSwapBuffers();
end; //Draw

procedure TGui.CenterOn(const x, y: Integer);
begin
  OffSetX:= x-7;
  if OffSetX<0 then OffsetX:= 0
  else if (OffSetX>cMap_X-x_Fields) then OffsetX:= cMap_X-x_Fields;
  OffSetY:= y-6;
  if OffSetY<0 then OffsetY:= 0
  else if (OffSetY>cMap_Y-y_Fields) then OffsetY:= cMap_Y-y_Fields;

  //Move Minimap accordingly
  MiniMapOffset_Y:= y -(Minimap_y_Fields div 2);
  if MiniMapOffset_Y<0 then MiniMapOffset_Y:=0
  else if (MiniMapOffset_Y>cMap_Y-Minimap_y_fields) then
    MiniMapOffset_Y:= cMap_Y-Minimap_y_fields;
end;//proc

end.