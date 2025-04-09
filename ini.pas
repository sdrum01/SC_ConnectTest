unit Ini;

{$mode objfpc}{$H+}

interface


uses
  Classes, SysUtils, IniFiles;

type
    TIniSettings = record
      dbFile1 : string;
      dbFile2 : string;
      dbUser1 : string;
      dbUser2 : string;
      dbPw1 : string;
      dbPw2 : string;
      protocol1 : string;
      protocol2 : string;
      port1 : integer;
      port2 : integer;
      debug : integer;
      tools : string;
      sc_version : integer;
    end;

function ReadSettings:TIniSettings;
procedure WriteSettings(mySettings : TIniSettings);

implementation

const
  IniFile = 'settings.ini';


function ReadSettings:TIniSettings;
var
    Sett : TIniFile;
    dbFile  : String;
    mySettings : TIniSettings;
begin
    Sett := TIniFile.Create(IniFile);
    mySettings.dbFile1 := Sett.ReadString('Main', 'dbFile1', 'C:\Program Files (x86)\SafeControl\data\SAFECONTROL.FDB');    // (Section, Key, Default)
    mySettings.dbFile2 := Sett.ReadString('Main', 'dbFile2', 'c:\Program Files (x86)\Cenadco\data\CENADCO.FDB');
    mySettings.dbUser1 := Sett.ReadString('Main', 'dbUser1', 'BELA');
    mySettings.dbUser2 := Sett.ReadString('Main', 'dbUser2', 'SYSDBA');
    mySettings.dbPw1 := Sett.ReadString('Main', 'dbPw1', '19205300');
    mySettings.dbPw2 := Sett.ReadString('Main', 'dbPw2', 'Bl2020!?');
    mySettings.protocol1 := Sett.ReadString('Main', 'Protocol1', 'firebird-2.5');
    mySettings.protocol2 := Sett.ReadString('Main', 'Protocol2', 'firebird-3.0');
    mySettings.port1 := Sett.ReadInteger('Main', 'port', 3050);
    mySettings.port2 := Sett.ReadInteger('Main', 'port', 3051);
    mySettings.debug := Sett.ReadInteger('Main', 'debug', 0);
    mySettings.tools := Sett.ReadString('Main', 'tools', '');
    mySettings.sc_version := Sett.ReadInteger('Main', 'sc_version', 1);
    Sett.Free;
    Result := mySettings;
end;

procedure WriteSettings(mySettings : TIniSettings);
var
    Sett : TIniFile;

begin

    Sett := TIniFile.Create(IniFile);
    //Sett.WriteBool('Main', 'CheckBox', CheckBox1.Checked);
    //Sett.WriteInteger('Main', 'X', Settings.X);
    Sett.WriteString('Main', 'dbFile1', mySettings.dbFile1);
    Sett.WriteString('Main', 'dbFile2', mySettings.dbFile2);
    Sett.WriteString('Main', 'dbUser1', mySettings.dbUser1);
    Sett.WriteString('Main', 'dbUser2', mySettings.dbUser2);
    Sett.WriteString('Main', 'dbPw1', mySettings.dbPw1);
    Sett.WriteString('Main', 'dbPw2', mySettings.dbPw2);
    Sett.WriteString('Main', 'Protocol1', mySettings.protocol1);
    Sett.WriteString('Main', 'Protocol2', mySettings.protocol2);
    Sett.WriteInteger('Main', 'port1', mySettings.port1);
    Sett.WriteInteger('Main', 'port2', mySettings.port2);
    Sett.WriteInteger('Main', 'sc_version', mySettings.sc_version);
    Sett.Free;
end;


end.

