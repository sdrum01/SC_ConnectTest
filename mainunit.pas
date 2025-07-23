unit mainunit;

{$mode objfpc}{$H+}

interface

uses
  Classes, Windows, SysUtils, DB, Forms, Controls, Graphics, Dialogs, StdCtrls, DBCtrls,
  DBGrids, ExtCtrls,  ZConnection, ZDataset, tools, DateUtils;

{
type
    TIniSettings = record
      dbFile : string;
      test : integer;
    end;
}

type

  { TMainForm }

  TMainForm = class(TForm)
    b_fachvw: TButton;
    b_defaultpw1: TButton;
    b_defaultpw2: TButton;
    b_resetSC11User: TButton;
    b_exportTable: TButton;
    B_where: TButton;
    Button3: TButton;
    b_chooseSrc: TButton;
    b_refresh: TButton;
    b_chooseDst: TButton;
    b_setHostName: TButton;
    B_SQLExec: TButton;
    b_tools: TButton;
    DataSource1: TDataSource;
    DataSource2: TDataSource;
    DBGrid1: TDBGrid;
    DBGrid2: TDBGrid;
    DBNavigator1: TDBNavigator;
    DBNavigator2: TDBNavigator;
    e_pw1: TEdit;
    Edit_filter2: TEdit;
    Edit_qs: TEdit;
    Edit_filter: TEdit;
    e_pw2: TEdit;
    e_SQLQuery: TEdit;
    l_filter1: TLabel;
    l_filter2: TLabel;
    ListBox_tables2: TListBox;
    l_genid: TLabel;
    Label_qs: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    ListBox_tables1: TListBox;
    OpenDialog1: TOpenDialog;
    rg_scVersion: TRadioGroup;
    TB_2DB: TToggleBox;
    ZConnection1: TZConnection;
    ZConnection2: TZConnection;
    ZQuery1: TZQuery;
    ZQuery2: TZQuery;
    procedure b_defaultpw1Click(Sender: TObject);
    procedure b_defaultpw2Click(Sender: TObject);
    procedure b_exportTableClick(Sender: TObject);
    procedure b_fachvwClick(Sender: TObject);
    procedure b_resetSC11UserClick(Sender: TObject);
    procedure b_toolsMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure B_whereClick(Sender: TObject);

    procedure b_chooseSrcClick(Sender: TObject);
    procedure b_refreshClick(Sender: TObject);
    procedure b_setHostNameClick(Sender: TObject);
    procedure b_toolsClick(Sender: TObject);

    procedure DBGrid1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);

    procedure DBGrid2MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Edit_filter2Change(Sender: TObject);
    procedure Edit_filter2Click(Sender: TObject);

    procedure Edit_filterChange(Sender: TObject);
    procedure Edit_filterClick(Sender: TObject);
    procedure e_pw1Change(Sender: TObject);
    procedure e_pw2Change(Sender: TObject);

    procedure e_SQLQueryKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);

    procedure FormDestroy(Sender: TObject);

    procedure helper_createHostname(HostName : string);
    procedure b_chooseDstClick(Sender: TObject);
    procedure ListBox_tables2Click(Sender: TObject);
    procedure rg_scVersionClick(Sender: TObject);
    procedure setHostName;
    procedure B_SQLExecClick(Sender: TObject);
    procedure repaint_FormElements;

    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure getAllTables(dbId:integer);
    procedure ListBox_tables1Click(Sender: TObject);
    procedure MainFormSizeConstraintsChange(Sender: TObject);
    procedure showTable(tableName:string);
    procedure selectTable(tableName:string);
    procedure SqlExecShow(s:string);
    function getQuersumme:integer;
    procedure TB_2DBChange(Sender: TObject);
    procedure FilterListbox(const FilterText: string);
    procedure getGeneratorValue(table:string);
    function openDatabase(conn:TZConnection; dbId:integer):boolean;
    procedure SqlExecute(s:string);
    procedure SC_resetDefaultUser;
    procedure exportTable(table:string);
    procedure exportTableCen(table:string);
    procedure refreshConnection1;
    procedure log_common(s:string);
    procedure markEditor(dbId:integer);
    function get_boxDepth(s:string):string;
    //Procedure WriteLog(s, LogFile : String);
    procedure exportFachVW(AFileName: string);

  private

  public
    //Settings: TIniSettings;
    actualTable : string;
    qs_recalc : integer;
    isEnableTools : bool;
    selected_dbId : integer;
  end;

var
  MainForm: TMainForm;
  FormTools: Tform_tools;

implementation

{$R *.lfm}

uses Ini;

{ TMainForm }

var iniSettings : TIniSettings;
    TableList1,TableList2:TStringlist;


function getHostName():string;
var
  Buffer: array[0..MAX_COMPUTERNAME_LENGTH + 1] of Char;
  Size: DWORD;
  HostName : string;
begin
  // Puffergröße initialisieren
  Size := MAX_COMPUTERNAME_LENGTH + 1;

  // Hostnamen ermitteln
  if GetComputerName(Buffer, Size) then
    HostName := string(Buffer)
  else
    Hostname := '';
    result := HostName;
end;


Procedure WriteLog(s, LogFile : String);
Var
F1 : TextFile;
begin
 DateSeparator := '.';
 ShortDateFormat := 'dd/mm/yy';
 ShortTimeFormat := 'hh/mm/ss';
 //LogFile := Log;
 If Not FileExists(LogFile) then
 begin
  try
   AssignFile(F1,LogFile);
   ReWrite(F1);
   WriteLn(F1,DateToStr(now)+'-'+TimeToStr(now)+';'+ #$9 + s);
   CloseFile(F1);
  finally
   //CloseFile(F1);
  end;
 end else
 begin
   try
        AssignFile(F1,LogFile);
        Append(F1);

        WriteLn(F1,DateToStr(now)+'-'+TimeToStr(now)+';'+ #$9 + s);
        CloseFile(F1);
   except
     on E:Exception do ShowMessage(E.Message) ;
   end
 end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var i : integer;
begin
  // Form Tools erzeugen
  isEnableTools := false;
  FormTools := Tform_tools.Create(Self);
  actualTable := '';
  TableList1 := TStringlist.Create;
  TableList2 := TStringlist.Create;
  selected_dbId := 1;
  try
    iniSettings := ReadSettings;
    rg_scVersion.ItemIndex:=iniSettings.sc_version;
    if (fileExists(iniSettings.dbFile1)) then
    begin
      //ZConnection1.Database:=iniSettings.dbFile1;
      openDatabase(ZConnection1,1);
      Label2.Caption:=iniSettings.dbFile1;
      e_pw1.Text:=iniSettings.dbPw1;
      e_pw2.Text:=iniSettings.dbPw2;
      getAllTables(selected_dbId);
      Edit_qs.Text := intToStr(getQuersumme);
    end else Label2.Caption:='File not found:'+iniSettings.dbFile1;
    // if iniSettings.tools = 'export' then b_tools.Visible:=true;

  finally

  end;
  {
  // Parameter
  for i := 1 to ParamCount do
  begin
    if(ParamStr(i) = '-enableTools') then
      begin
        isEnableTools := true;
      end;
  end;
  }
  // Parameter überschreiben
  isEnableTools := true;

  if isEnableTools then b_tools.Visible:=true;
  log_common('App gestartet, Tools: '+boolToStr(isEnableTools));

end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  repaint_FormElements;
end;


procedure TMainForm.FilterListbox(const FilterText: string);
var
  i: integer;
begin

  if(selected_dbId = 1)then
  begin
    ListBox_tables1.Items.Clear;
    for i := 0 to TableList1.count - 1 do
    begin
      if ((pos(lowercase(FilterText), lowercase(TableList1.strings[i]) ) > 0)or(FilterText = '')) then
      begin
        ListBox_tables1.Items.Add(TableList1[i]);
      end;
    end;
  end;

  if(selected_dbId = 2)then
  begin
    ListBox_tables2.Items.Clear;
    for i := 0 to TableList2.count - 1 do
    begin
      if ((pos(lowercase(FilterText), lowercase(TableList2.strings[i]) ) > 0)or(FilterText = '')) then
      begin
        ListBox_tables2.Items.Add(TableList2[i]);
      end;
    end;
  end;


end;


procedure TMainForm.selectTable(tableName:string);
begin
  ListBox_tables1.ItemIndex := ListBox_tables1.Items.IndexOf(tableName);
  showTable(tableName);
end;

procedure TMainForm.showTable(tableName:string);
begin
  if(selected_dbId = 1) then
  begin
    if(TableList1.IndexOf(tableName) > -1 ) then
    begin
      getGeneratorValue(tableName);
      Edit_qs.Text := intToStr(getQuersumme);
      SqlExecShow('SELECT * FROM ' + tableName);
    end;
  end;

  if(selected_dbId = 2) then
  begin
    if(TableList2.IndexOf(tableName) > -1 ) then
    begin
      //getGeneratorValue(tableName);
      //Edit_qs.Text := intToStr(getQuersumme);
      SqlExecShow('SELECT * FROM ' + tableName);
    end;
  end;



  //DBGrid1.DataSource := Datasource1;
  //if TB_2DB.Checked then DBGrid2.DataSource := Datasource2;


end;

procedure TMainForm.SqlExecute(s:string);
begin
  DBGrid1.DataSource := Datasource1;
  Datasource1.DataSet := ZQuery1;
  Datasource2.DataSet := ZQuery2;

  if(selected_dbId =  1)then
  begin

    ZQuery1.SQL.Text:= s;
    ZQuery1.Open;
  end;
  if(selected_dbId =  2)then
  begin

    ZQuery2.SQL.Text:= s;
    ZQuery2.Open;
  end;


end;


procedure TMainForm.B_SQLExecClick(Sender: TObject);
begin
  SqlExecute(e_SQLQuery.Text);
end;

procedure TMainForm.setHostName;
var
  mySelectedTable, HostName : string;
  Confirmation: TModalResult;
begin

  HostName := GetHostName;
  if(HostName <> '')then
  begin
    mySelectedTable := 'COMPUTER';
    selectTable(mySelectedTable);
    Confirmation := MessageDlg('Der Rechnername '+HostName+' wird nun in die Tabelle COMPUTER eingetragen.'+#10#13+' Möchten Sie fortfahren?', mtConfirmation, [mbYes, mbNo], 0);
    if Confirmation = mrYes then
    begin
      helper_createHostname(HostName);
      selectTable(mySelectedTable);
    end;
  end else showMessage('Hostname konnte nicht ermittelt werden');

end;

procedure TMainForm.SC_resetDefaultUser;
var
  _name, _vorname1, _vorname2, _password1, _password2, bedienerid : string;
  Confirmation: TModalResult;
  sql:string;
  Query1: TZQuery;
begin
  _name := 'EI@BFHDJLNBI@JCBOOAJLIE@BOK@EMNE';
  _vorname1 := 'OFJFFOCJLLFJGFNH';
  _vorname2 := 'GDIINBJBEFKDEJLC';
  _password1 := 'DMNDHHOHM@@@OLKA';
  _password2 := _password1;

  Confirmation := MessageDlg('Reset user 0001 and 0002 ?', mtConfirmation, [mbYes, mbNo], 0);

  if Confirmation = mrYes then
  begin
    Query1 := TZQuery.Create(nil);
    Query1.Connection := ZConnection1;

    // Code 1 holen
    sql := 'SELECT * FROM CODEHIST WHERE BEDIENERID = :BEDIENERID';
    Query1.SQL.Text:= sql;
    Query1.ParamByName('BEDIENERID').AsString := '10000001';
    Query1.Open;
    if(Query1.RecordCount > 0)then
    begin
      _password1 := Query1.Fields.FieldByName('CODE').AsString;

      log_common('CODE1'+ _password1);
    end;
    // Code 1 holen
    sql := 'SELECT * FROM CODEHIST WHERE BEDIENERID = :BEDIENERID';
    Query1.SQL.Text:= sql;
    Query1.ParamByName('BEDIENERID').AsString := '10000002';
    Query1.Open;
    if(Query1.RecordCount > 0)then
    begin
      _password2 := Query1.Fields.FieldByName('CODE').AsString;

      log_common('CODE2'+ _password2);
    end;

    sql := 'SELECT * FROM BDATEN WHERE id = :id';
    Query1.SQL.Text:= sql;
    Query1.ParamByName('id').AsString := '10000001';
    Query1.Open;

    if(Query1.RecordCount = 0)then
    begin
      sql := 'INSERT INTO BDATEN (NAME, VORNAME, KURZBEZEICHNUNG, BEDIENERCODE)VALUES(:name, :vorname, :kurzbezeichnung, :bedienercode)';
      Query1.SQL.Text:= sql;
      Query1.ParamByName('name').AsString := _name;
      Query1.ParamByName('vorname').AsString  := _vorname1;
      Query1.ParamByName('kurzbezeichnung').AsString  := 'ABC';
      Query1.ParamByName('bedienercode').AsString  := _password1;
      Query1.ExecSQL;

    end else
    begin
      //sql := 'UPDATE BDATEN SET NAME = :name, VORNAME = :vorname, KURZBEZEICHNUNG = :kurzbezeichnung, BEDIENERCODE = :bedienercode WHERE ID = 10000001';
      sql := 'UPDATE BDATEN SET BEDIENERCODE = :bedienercode WHERE ID = 10000001';
      Query1.SQL.Text:= sql;
      //Query1.ParamByName('name').AsString := _name;
      //Query1.ParamByName('vorname').AsString  := _vorname1;
      //Query1.ParamByName('kurzbezeichnung').AsString  := 'ABC';
      Query1.ParamByName('bedienercode').AsString  := _password1;
      Query1.ExecSQL;

    end;

    sql := 'SELECT * FROM BDATEN WHERE id = :id';
    Query1.SQL.Text:= sql;
    Query1.ParamByName('id').AsString := '10000002';
    Query1.Open;
    if(Query1.RecordCount = 0)then
    begin
      sql := 'UPDATE BDATEN SET BEDIENERCODE = :bedienercode WHERE ID = 10000002';
      Query1.SQL.Text:= sql;
      //Query1.ParamByName('name').AsString := _name;
      //Query1.ParamByName('vorname').AsString  := _vorname2;
      //Query1.ParamByName('kurzbezeichnung').AsString  := 'ABC';
      Query1.ParamByName('bedienercode').AsString  := _password2;
      Query1.ExecSQL;

    end else
    begin
      //sql := 'UPDATE BDATEN SET NAME = :name, VORNAME = :vorname, KURZBEZEICHNUNG = :kurzbezeichnung, BEDIENERCODE = :bedienercode WHERE ID = 10000002';
      sql := 'UPDATE BDATEN SET NAME = :name, VORNAME = :vorname, KURZBEZEICHNUNG = :kurzbezeichnung, BEDIENERCODE = :bedienercode WHERE ID = 10000002';
      Query1.SQL.Text:= sql;
      Query1.ParamByName('name').AsString := _name;
      Query1.ParamByName('vorname').AsString  := _vorname2;
      Query1.ParamByName('kurzbezeichnung').AsString  := 'ABC';
      Query1.ParamByName('bedienercode').AsString  := _password2;
      Query1.ExecSQL;

    end;

    sql := 'UPDATE BEDIENER SET FALSCHEINGABEN = 0, SPERRDATUM = NULL, SPERRZEIT = NULL, SPERREID = NULL, SPERRE = 0 WHERE ID = 10000001 OR ID = 10000002';
    Query1.SQL.Text:= sql;
    //Query1.ParamByName('sperrdatum').AsString := NIL;
    Query1.ExecSQL;

    Query1.Free;
  end;
  refreshConnection1;
end;



procedure TMainForm.helper_createHostname(HostName : string);
var sql:string;
  Query1: TZQuery;
  maxNummer : integer;
begin
  Query1 := TZQuery.Create(nil);
  Query1.Connection := ZConnection1;
  // Auf Hostname überprüfen
  sql := 'SELECT * FROM COMPUTER WHERE BEZEICHNUNG = :hostname';
  Query1.SQL.Text:= sql;
  Query1.ParamByName('hostname').AsString := HostName;
  Query1.Open;
  if(Query1.RecordCount = 0)then
  begin
    sql := 'SELECT MAX(NUMMER) FROM COMPUTER';
    Query1.SQL.Text:= sql;
    Query1.Open;
    maxNummer := Query1.Fields[0].asInteger;

    sql := 'INSERT INTO COMPUTER (BEZEICHNUNG,NUMMER)VALUES(:hostname,:number)';
    Query1.SQL.Text:= sql;
    Query1.ParamByName('hostname').AsString := HostName;
    Query1.ParamByName('number').AsInteger  := maxNummer + 1;

    Query1.ExecSQL;
    Query1.Free;
  end else showMessage('Der Host "'+HostName+'" ist bereits eingetragen');
  {
  while not Query1.EOF do
    begin

      for i := 0 to Query1.FieldCount - 1 do
        writeLn(Query1.Fields[i].AsString);
      Query1.Next;

      writeLn(Query1.FieldValues['BEZEICHNUNG']);
    end;

  end;
  }




end;

procedure TMainForm.b_setHostNameClick(Sender: TObject);
begin
  setHostName;
end;

// Export im SC11-Format
// Exportieren der Export-SQL-Statements für das Updatescript
procedure TMainForm.exportTable(table:string);
var
  s, values, new_anlagennummer, sql, groessenbezeichnung_tempDb: string;
  groessenhoehe_tempDb, groessenbreite_tempDb, s_groessenid_new : string;
  scRow, groessenRow: integer;
  groessenid_tempDb, groessenid_new : integer;
  new_groesse_inserted: bool;
begin
  FormTools.memo1.lines.Clear;
  //FormTools.Memo_export.lines.Clear;
  FormTools.SynEdit_export.lines.Clear;

  new_anlagennummer := FormTools.e_anlagennummer.Text;
  new_groesse_inserted := false;

  s := 'DELETE FROM ANLAGE WHERE ANLAGENNUMMER = '+new_anlagennummer + ';';

  //FormTools.Memo_export.lines.Add(s);
  FormTools.SynEdit_export.lines.Add(s);

  /////////////////////////////////////////////////////
  ///// ANLAGEN-Tabelle ///////////
  // Anlagentabelle der neuen Db durchlaufen und die Werte in ein SQL übertragen
  sql := 'SELECT * FROM ANLAGE WHERE ANLAGENNUMMER = '+ FormTools.e_anlagennummeralt.Text;
  ZQuery1.SQL.Text:= sql;
  //log_common(sql);
  try
    ZQuery1.Open;
    //FormTools.Memo_export.Lines.BeginUpdate;
    FormTools.SynEdit_export.BeginUpdate(true);
    while not ZQuery1.EOF do
    begin
      //for i := 0 to ZQuery1.FieldCount - 1 do
      //TableList.Add(ZQuery1.Fields[i].AsString);
      //if ZQuery1.Fields.FieldByName('ANLAGENNUMMER').AsString = FormTools.e_anlagennummeralt.Text then
      //begin
        values := new_anlagennummer + ',';
        values += ZQuery1.Fields.FieldByName('GESCHAEFTSTELLE').AsString + ',';
        values += ZQuery1.Fields.FieldByName('BLOCK').AsString + ',';
        values += ZQuery1.Fields.FieldByName('X1').AsString + ',';
        values += ZQuery1.Fields.FieldByName('Y1').AsString + ',';
        values += ZQuery1.Fields.FieldByName('X2').AsString + ',';
        values += ZQuery1.Fields.FieldByName('Y2').AsString + ',';
        values += ZQuery1.Fields.FieldByName('X3').AsString + ',';
        values += ZQuery1.Fields.FieldByName('Y3').AsString + ',';
        values += ZQuery1.Fields.FieldByName('X4').AsString + ',';
        values += ZQuery1.Fields.FieldByName('Y4').AsString + ',';
        values += ZQuery1.Fields.FieldByName('FACHSTART').AsString + ',';
        values += ZQuery1.Fields.FieldByName('FACHSTOP').AsString + ',';
        values += ZQuery1.Fields.FieldByName('DOPPELBLOCK').AsString;

        s := 'INSERT INTO ANLAGE (ANLAGENNUMMER, GESCHAEFTSTELLE, BLOCK, X1, Y1, X2, Y2, X3, Y3, X4, Y4, FACHSTART, FACHSTOP, DOPPELBLOCK) VALUES ('+values+');';
        //FormTools.Memo_export.lines.Add(s);
        FormTools.SynEdit_export.lines.Add(s);
      //end;


      ZQuery1.Next;
    end;
    //FormTools.Memo_export.Lines.EndUpdate;
    FormTools.SynEdit_export.EndUpdate;
  except
    on E: Exception do
    begin
      log_common(E.Message);
    end;
  end;

  /////////////////////////////////////////////////////
  ///// GROESSEN-Tabelle ////////////////
  // BEISPIEL
  // UPDATE OR INSERT INTO GROESSEN (ID, HOEHE, BREITE, BEZEICHNUNG, ANLAGENNUMMER, GESCHAEFTSTELLE, VOLUMEINDEX) VALUES (11, 175, 300, '175x300x400', 1, 1, 0) MATCHING (ID);
  // SET GENERATOR GROESSEN_ID_GEN TO 11;
  // newGroessenListe := groessenListe;



  for groessenRow := 1 to FormTools.sg_groessen.RowCount - 1 do
  begin
    groessenid_tempDb := StrToIntDef(FormTools.sg_groessen.Cells[0, groessenRow],0);
    groessenid_new := StrToIntDef(FormTools.sg_groessen.Cells[1, groessenRow],0);

    groessenhoehe_tempDb := FormTools.sg_groessen.Cells[2, groessenRow];
    groessenbreite_tempDb := FormTools.sg_groessen.Cells[3, groessenRow];
    groessenbezeichnung_tempDb := FormTools.sg_groessen.Cells[4, groessenRow];
    if (groessenid_new < 0) then
    begin
      s_groessenid_new := IntToStr(-groessenid_new);
      s := 'UPDATE OR INSERT INTO GROESSEN (ID, HOEHE, BREITE, BEZEICHNUNG, ANLAGENNUMMER, GESCHAEFTSTELLE, VOLUMEINDEX) VALUES ('+s_groessenid_new+', '+groessenhoehe_tempDb+', '+groessenbreite_tempDb+', '''+groessenbezeichnung_tempDb+''', '+new_anlagennummer+', 1, 0) MATCHING (ID, ANLAGENNUMMER);';
      FormTools.SynEdit_export.Lines.Add(s);
      new_groesse_inserted := true;
    end;

  end;

  // Wenn Größen ergänzt werden müssen, muss der Generator manuell hochgezählt werden
  if new_groesse_inserted then
  begin
    s := 'SET GENERATOR GROESSEN_ID_GEN TO '+intToStr(FormTools.lastGroessenId+1)+';';
    FormTools.SynEdit_export.Lines.Add(s);
  end;
  /////////////////////////////////////////////////////
  ///// FACH-Tabelle ///////////


  sql := 'SELECT ANLAGENNUMMER, GESCHAEFTSTELLE,  FACHNUMMER, GROESSENID, ANZEIGHOEHE, ANZEIGBREITE,FACHART,SPERRE,RESERVIERUNG,ATTRAPPE,BELEGT,SELBSTANMIETUNG,UEBERWACHUNG,RUNDUM,POSTSPERRE,VERSICHID,ABRECHNUNGSART,WAEHRUNG,BERECHNUNGSZEIT,ANZAHLOEFF,T1ZEIT,T2ZEIT,T3ZEIT,LAGE,BLOCK,PREISGRUPPEINDEX from FACH where fachnummer >= ' + FormTools.e_fromBox.Text + ' AND fachnummer <= '+ FormTools.e_toBox.Text +' AND  ANLAGENNUMMER = ' + FormTools.e_anlagennummeralt.Text +' order by fachnummer';
  ZQuery1.SQL.Text:= sql;
  //log_common(sql);
  try
    //FormTools.Memo_export.Lines.BeginUpdate;
    FormTools.SynEdit_export.Lines.BeginUpdate;
    ZQuery1.Open;
    while not ZQuery1.EOF do
    begin
      //for i := 0 to ZQuery1.FieldCount - 1 do
      //TableList.Add(ZQuery1.Fields[i].AsString);
      if ZQuery1.Fields.FieldByName('ANLAGENNUMMER').AsString = FormTools.e_anlagennummeralt.Text then
      begin
        //values := new_anlagennummer + ',';
        if(FormTools.ckb_onlyBlock.Checked) then
        begin
          s := 'UPDATE OR INSERT INTO FACH (ANLAGENNUMMER, GESCHAEFTSTELLE, FACHNUMMER, GROESSENID, ANZEIGHOEHE, ANZEIGBREITE, FACHART, ATTRAPPE, LAGE, BLOCK) VALUES ';
          s +='('+new_anlagennummer+', ';                          //ANLAGENNUMMER
          s += ZQuery1.Fields.FieldByName('GESCHAEFTSTELLE').AsString+', ';
          s += ZQuery1.Fields.FieldByName('FACHNUMMER').AsString+', ';
          s += IntToStr(Abs(StrToIntDef(FormTools.sg_groessen.Cells[1,ZQuery1.Fields.FieldByName('GROESSENID').AsInteger],0))) +', ';
          s += ZQuery1.Fields.FieldByName('ANZEIGHOEHE').AsString+', ';
          s += ZQuery1.Fields.FieldByName('ANZEIGBREITE').AsString+', ';
          s += ZQuery1.Fields.FieldByName('FACHART').AsString+', ';
          s += ZQuery1.Fields.FieldByName('ATTRAPPE').AsString+', ';
          s += ZQuery1.Fields.FieldByName('LAGE').AsString+', ';
          s += ZQuery1.Fields.FieldByName('BLOCK').AsString;
          s += ') MATCHING (ANLAGENNUMMER, FACHNUMMER);';
        end else
        begin
          s := 'UPDATE OR INSERT INTO FACH (ANLAGENNUMMER, GESCHAEFTSTELLE, FACHNUMMER, GROESSENID, ANZEIGHOEHE, ANZEIGBREITE, FACHART, SPERRE, RESERVIERUNG, ATTRAPPE, BELEGT, SELBSTANMIETUNG, UEBERWACHUNG, RUNDUM, POSTSPERRE, VERSICHID, ABRECHNUNGSART, WAEHRUNG, BERECHNUNGSZEIT, ANZAHLOEFF, T1ZEIT, T2ZEIT, T3ZEIT, LAGE, BLOCK, PREISGRUPPEINDEX) VALUES ';
          s +='('+new_anlagennummer+', ';                          //ANLAGENNUMMER
          s += ZQuery1.Fields.FieldByName('GESCHAEFTSTELLE').AsString+', ';
          s += ZQuery1.Fields.FieldByName('FACHNUMMER').AsString+', ';
          s += IntToStr(Abs(StrToIntDef(FormTools.sg_groessen.Cells[1,ZQuery1.Fields.FieldByName('GROESSENID').AsInteger],0))) +', ';
          s += ZQuery1.Fields.FieldByName('ANZEIGHOEHE').AsString+', ';
          s += ZQuery1.Fields.FieldByName('ANZEIGBREITE').AsString+', ';
          s += ZQuery1.Fields.FieldByName('FACHART').AsString+', ';
          s += ZQuery1.Fields.FieldByName('SPERRE').AsString+', ';
          s += ZQuery1.Fields.FieldByName('RESERVIERUNG').AsString+', ';
          s += ZQuery1.Fields.FieldByName('ATTRAPPE').AsString+', ';
          s += ZQuery1.Fields.FieldByName('BELEGT').AsString+', ';
          s += ZQuery1.Fields.FieldByName('SELBSTANMIETUNG').AsString+', ';
          s += ZQuery1.Fields.FieldByName('UEBERWACHUNG').AsString+', ';
          s += ZQuery1.Fields.FieldByName('RUNDUM').AsString+', ';
          s += ZQuery1.Fields.FieldByName('POSTSPERRE').AsString+', ';
          s += FormTools.e_versichId.Text+', ';
          if ZQuery1.Fields.FieldByName('ABRECHNUNGSART').IsNull then s += 'NULL, ' else s += ZQuery1.Fields.FieldByName('ABRECHNUNGSART').AsString+', ';
          if ZQuery1.Fields.FieldByName('WAEHRUNG').IsNull then s += 'NULL, ' else s += ZQuery1.Fields.FieldByName('WAEHRUNG').AsString+', ';
          s += ZQuery1.Fields.FieldByName('BERECHNUNGSZEIT').AsString+', ';
          s += ZQuery1.Fields.FieldByName('ANZAHLOEFF').AsString+', ';
          s += '''' + FormatDateTime('yyyy-mm-dd hh:nn:ss', ZQuery1.Fields.FieldByName('T1ZEIT').AsDateTime)+ ''', ';
          s += '''' + FormatDateTime('yyyy-mm-dd hh:nn:ss', ZQuery1.Fields.FieldByName('T2ZEIT').AsDateTime)+ ''', ';
          s += '''' + FormatDateTime('yyyy-mm-dd hh:nn:ss', ZQuery1.Fields.FieldByName('T3ZEIT').AsDateTime)+ ''', ';
          s += ZQuery1.Fields.FieldByName('LAGE').AsString+', ';
          s += ZQuery1.Fields.FieldByName('BLOCK').AsString+', ';
          if ZQuery1.Fields.FieldByName('PREISGRUPPEINDEX').IsNull then s += 'NULL' else s += ZQuery1.Fields.FieldByName('PREISGRUPPEINDEX').AsString;
          s += ') MATCHING (ANLAGENNUMMER, FACHNUMMER);';
        end;
        //FormTools.Memo_export.lines.Add(s);
        FormTools.SynEdit_export.Lines.Add(s);
      end;


      ZQuery1.Next;
    end;
    //FormTools.Memo_export.Lines.EndUpdate;
    FormTools.SynEdit_export.Lines.EndUpdate;
  except
    on E: Exception do
    begin
      //
    end;
  end;








  /// Nochmal die Fachtabelle zum Updaten der Blocknummern aller Fächer
  sql := 'SELECT FACHNUMMER, LAGE, BLOCK from FACH where fachnummer < ' + FormTools.e_fromBox.Text + ' OR fachnummer > '+ FormTools.e_toBox.Text +' AND ANLAGENNUMMER = ' + FormTools.e_anlagennummeralt.Text +' order by fachnummer';
  ZQuery1.SQL.Text:= sql;
  try
    FormTools.SynEdit_export.Lines.BeginUpdate;
    ZQuery1.Open;

    while not ZQuery1.EOF do
    begin
      //if ZQuery1.Fields.FieldByName('ANLAGENNUMMER').AsString = FormTools.e_anlagennummeralt.Text then
      //begin

        s := 'UPDATE FACH SET ';
        s += 'BLOCK = '+ZQuery1.Fields.FieldByName('BLOCK').AsString;
        s += ', LAGE = '+ZQuery1.Fields.FieldByName('LAGE').AsString;
        s += ' WHERE ANLAGENNUMMER = '+new_anlagennummer;
        s += ' AND FACHNUMMER = '+ZQuery1.Fields.FieldByName('FACHNUMMER').AsString;
        FormTools.SynEdit_export.Lines.Add(s);

      //end;
      ZQuery1.Next;
    end;

    FormTools.SynEdit_export.Lines.EndUpdate;
  except
    on E: Exception do
    begin
      log_common(E.Message);
    end;
  end;








  ////////////////////// SC-Tabelle ///////////////////
  log_common('SC-Tabelle:'+ IntToStr(FormTools.sg_sctable.RowCount)+' Einträge');
  for scRow := 1 to FormTools.sg_sctable.RowCount - 1 do begin
    // Insert Beispiel
    // INSERT INTO SC (ANLAGENNUMMER, GESCHAEFTSTELLE, PARTYLINE, SC, ERSTEFACHNR, LETZTEFACHNR, SCGRUPINDEX) VALUES (75, 1, 0, 2, -1, -1, 0);
    if (FormTools.sg_sctable.Cells[7,scRow] = '1') then
    begin
      s := 'INSERT INTO SC (ANLAGENNUMMER, GESCHAEFTSTELLE, PARTYLINE, SC, ERSTEFACHNR, LETZTEFACHNR, SCGRUPINDEX) VALUES ';
      s +='(';
      s += FormTools.sg_sctable.Cells[0,scRow]+',';
      s += FormTools.sg_sctable.Cells[1,scRow]+',';
      s += FormTools.sg_sctable.Cells[2,scRow]+',';
      s += FormTools.sg_sctable.Cells[3,scRow]+',';
      s += FormTools.sg_sctable.Cells[4,scRow]+',';
      s += FormTools.sg_sctable.Cells[5,scRow]+',';
      s += FormTools.sg_sctable.Cells[6,scRow];
      s +=');';
      //FormTools.Memo_export.lines.Add(s);
      FormTools.SynEdit_export.Lines.Add(s);
    end;

  end;

  //s := 'UPDATE KONFIG1 SET QUERSUMME = '+intToStr(qs_recalc)+', SAFENET = xxxx, SAFENETA = xxxx, ELEKTRONIK = xxxx, GRAPHIKTERMINALS = xxxx, TASTATURLES = xxxx;'+#13#10;

  s := 'UPDATE KONFIG1 SET QUERSUMME = '+intToStr(qs_recalc)+', ';
  s += 'SAFENET = '+            FormTools.sg_konfig1.Cells[0,1]+', ';
  s += 'SAFENETA = '+           FormTools.sg_konfig1.Cells[1,1]+', ';
  s += 'ELEKTRONIK = '+         FormTools.sg_konfig1.Cells[2,1]+', ';
  s += 'GRAPHIKTERMINALS = '+   FormTools.sg_konfig1.Cells[3,1]+', ';
  s += 'VIDEOANZEIGE = '+       FormTools.sg_konfig1.Cells[4,1]+', ';
  s += 'VIDEOSPEICHERN = '+     FormTools.sg_konfig1.Cells[5,1]+', ';
  s += 'GEBUEHRENVERWALTUNG = '+FormTools.sg_konfig1.Cells[6,1]+', ';
  s += 'ZEITENSTEUERUNG = '+    FormTools.sg_konfig1.Cells[7,1]+', ';
  s += 'SBANMIETUNG = '+        FormTools.sg_konfig1.Cells[8,1]+', ';
  s += 'NTDEPOT = '+            FormTools.sg_konfig1.Cells[9,1]+', ';
  s += 'TASTATURLES = '+        FormTools.sg_konfig1.Cells[10,1]+';';
  FormTools.SynEdit_export.Lines.Add(s);

  s := 'EXECUTE PROCEDURE DMF_CHECK_SDL_BASIC_DATA;';
  FormTools.SynEdit_export.Lines.Add(s);

  s := 'COMMIT WORK;';
  FormTools.SynEdit_export.Lines.Add(s);
end;

// holt den Wert hinter dem letzen x der Bezeichnung und gibt damit die TIefe des Faches
function TMainForm.get_boxDepth(s:string):string;
var i : integer;
  depth : string;
begin
  depth := '';
  for i := Length(s) downto 1 do
  begin
    if s[i] = 'x' then Break else depth := s[i] + depth;
  end;
  result := trim(depth);
end;

// Export im Cenadco-Format
// Exportieren der Export-SQL-Statements für das Updatescript
procedure TMainForm.exportTableCen(table:string);
var
  s, values, new_anlagennummer, sql, groessenbezeichnung_tempDb: string;
  groessenhoehe_tempDb, groessenbreite_tempDb, s_groessenid_new , block_bak, orderInBlock: string;
  s_boxdepth :string;
  i, scRow, groessenRow: integer;
  groessenid_tempDb, groessenid_new : integer;
  new_groesse_inserted: bool;
begin
  FormTools.memo1.lines.Clear;
  FormTools.SynEdit_export.lines.Clear;

  new_anlagennummer := FormTools.e_anlagennummer.Text;
  new_groesse_inserted := false;

  s := 'DELETE FROM CEN_ANLAGE WHERE ANLAGENNUMMER = '+new_anlagennummer + ';';

  //FormTools.Memo_export.lines.Add(s);
  FormTools.SynEdit_export.lines.Add(s);

  /////////////////////////////////////////////////////
  ///// ANLAGEN-Tabelle ///////////

  sql := 'SELECT * FROM ANLAGE WHERE ANLAGENNUMMER = '+ FormTools.e_anlagennummeralt.Text;
  ZQuery1.SQL.Text:= sql;
  //log_common(sql);
  try
    ZQuery1.Open;
    //FormTools.Memo_export.Lines.BeginUpdate;
    FormTools.SynEdit_export.BeginUpdate(true);
    while not ZQuery1.EOF do
    begin
      //for i := 0 to ZQuery1.FieldCount - 1 do
      //TableList.Add(ZQuery1.Fields[i].AsString);
      //if ZQuery1.Fields.FieldByName('ANLAGENNUMMER').AsString = FormTools.e_anlagennummeralt.Text then
      //begin
        values := new_anlagennummer + ',';
        values += ZQuery1.Fields.FieldByName('BLOCK').AsString + ',';
        values += ZQuery1.Fields.FieldByName('X1').AsString + ',';
        values += ZQuery1.Fields.FieldByName('Y1').AsString + ',';
        values += ZQuery1.Fields.FieldByName('X2').AsString + ',';
        values += ZQuery1.Fields.FieldByName('Y2').AsString + ',';
        values += ZQuery1.Fields.FieldByName('X3').AsString + ',';
        values += ZQuery1.Fields.FieldByName('Y3').AsString + ',';
        values += ZQuery1.Fields.FieldByName('X4').AsString + ',';
        values += ZQuery1.Fields.FieldByName('Y4').AsString + ',';
        values += ZQuery1.Fields.FieldByName('DOPPELBLOCK').AsString;

        // alt sc
        //s := 'INSERT INTO ANLAGE (ANLAGENNUMMER, GESCHAEFTSTELLE, BLOCK, X1, Y1, X2, Y2, X3, Y3, X4, Y4, FACHSTART, FACHSTOP, DOPPELBLOCK) VALUES ('+values+');';
        // neu cen
        s := 'INSERT INTO CEN_ANLAGE (ANLAGENNUMMER, RACKNO, X1, Y1, X2, Y2, X3, Y3, X4, Y4, DOPPELBLOCK) VALUES ('+values+');';
        // Export aus cen
        // INSERT INTO CEN_ANLAGE (ID, ANLAGENNUMMER, RACKNO, X1, Y1, X2, Y2, X3, Y3, X4, Y4, DOPPELBLOCK, REPLIZIER, START_ID, STOP_ID, CEN_SDL_SC_ID) VALUES(1, 1, 1, 20, 85, 67, 85, 67, 20, 20, 20, 1, NULL, NULL, NULL, NULL);

        FormTools.SynEdit_export.lines.Add(s);
      //end;


      ZQuery1.Next;
    end;
    //FormTools.Memo_export.Lines.EndUpdate;
    FormTools.SynEdit_export.EndUpdate;
  except
    on E: Exception do
    begin
      log_common(E.Message);
    end;
  end;

  /////////////////////////////////////////////////////
  ///// GROESSEN-Tabelle ////////////////

  for groessenRow := 1 to FormTools.sg_groessen.RowCount - 1 do
  begin
    groessenid_tempDb := StrToIntDef(FormTools.sg_groessen.Cells[0, groessenRow],0);
    groessenid_new := StrToIntDef(FormTools.sg_groessen.Cells[1, groessenRow],0);

    groessenhoehe_tempDb := FormTools.sg_groessen.Cells[2, groessenRow];
    groessenbreite_tempDb := FormTools.sg_groessen.Cells[3, groessenRow];
    groessenbezeichnung_tempDb := FormTools.sg_groessen.Cells[4, groessenRow];
    if (groessenid_new < 0) then
    begin
      s_groessenid_new := IntToStr(-groessenid_new);
      s_boxdepth := get_boxDepth(groessenbezeichnung_tempDb); // ToDo: die Bezeichnung auseinandernehmen und das Letzte vor dem X zurückgeben.
      //s := 'UPDATE OR INSERT INTO GROESSEN (ID, HOEHE, BREITE, BEZEICHNUNG, ANLAGENNUMMER, GESCHAEFTSTELLE, VOLUMEINDEX) VALUES ('+s_groessenid_new+', '+groessenhoehe_tempDb+', '+groessenbreite_tempDb+', '''+groessenbezeichnung_tempDb+''', 1, 1, 0) MATCHING (ID);';
      s := 'UPDATE OR INSERT INTO CEN_SDL_BOXSIZES (ID, BOXTYPE, HEIGHT, WIDTH, BOXDEPTH, SIZENAME, ANLAGENNUMMER, VOLUMEID, VIEWHEIGHT, VIEWWIDTH) VALUES ('+s_groessenid_new+',1, '+groessenhoehe_tempDb+', '+groessenbreite_tempDb+','+s_boxdepth+', '''+groessenbezeichnung_tempDb+''', '+new_anlagennummer+', 0,'+groessenhoehe_tempDb+', '+groessenbreite_tempDb+') MATCHING (ID, ANLAGENNUMMER);';

      FormTools.SynEdit_export.Lines.Add(s);
      new_groesse_inserted := true;
    end;

  end;

  // Wenn Größen ergänzt werden müssen, muss der Generator manuell hochgezählt werden
  if new_groesse_inserted then
  begin
    s := 'SET GENERATOR CEN_SDL_BOXSIZES_SEQ TO '+intToStr(FormTools.lastGroessenId+1)+';';
    FormTools.SynEdit_export.Lines.Add(s);
  end;
  /////////////////////////////////////////////////////
  ///// FACH-Tabelle ///////////


  sql := 'SELECT ANLAGENNUMMER, GESCHAEFTSTELLE,  FACHNUMMER, GROESSENID, ANZEIGHOEHE, ANZEIGBREITE,FACHART,SPERRE,RESERVIERUNG,ATTRAPPE,BELEGT,SELBSTANMIETUNG,UEBERWACHUNG,RUNDUM,POSTSPERRE,VERSICHID,ABRECHNUNGSART,WAEHRUNG,BERECHNUNGSZEIT,ANZAHLOEFF,T1ZEIT,T2ZEIT,T3ZEIT,LAGE,BLOCK,PREISGRUPPEINDEX from FACH where fachnummer >= ' + FormTools.e_fromBox.Text + ' AND fachnummer <= '+ FormTools.e_toBox.Text +' AND  ANLAGENNUMMER = ' + FormTools.e_anlagennummeralt.Text +' order by ID';
  ZQuery1.SQL.Text:= sql;
  //log_common(sql);
  try
    //FormTools.Memo_export.Lines.BeginUpdate;
    FormTools.SynEdit_export.Lines.BeginUpdate;
    ZQuery1.Open;
    i := 0;
    block_bak := '';

    while not ZQuery1.EOF do
    begin
      //for i := 0 to ZQuery1.FieldCount - 1 do
      //TableList.Add(ZQuery1.Fields[i].AsString);
      if ZQuery1.Fields.FieldByName('ANLAGENNUMMER').AsString = FormTools.e_anlagennummeralt.Text then
      begin
        // Export aus Cenadco DB:
        // INSERT INTO CEN_SDL_BOX
        // (ID, ANLAGENNUMMER, FACHNUMMER, NICHTUEBERWACHTSEIT, UEBERWACHT, CEN_SDL_BOXSIZES_ID, CEN_SC_ID, BOXGROUP, MASTERSLAVE, HOSTNO, HOSTSIZENAME, DUMMY, RACKNO, STATUS, COMPANYNO, ORDERINBLOCK, RENTALSTATE)
        // VALUES(144, 1, 144, NULL, 1, 4, NULL, NULL, 0, NULL, NULL, 0, 8, NULL, 1, 18, 0);

        {
        s := 'UPDATE OR INSERT INTO FACH (ANLAGENNUMMER, GESCHAEFTSTELLE, FACHNUMMER, GROESSENID, ANZEIGHOEHE, ANZEIGBREITE, FACHART, SPERRE, RESERVIERUNG, ATTRAPPE, BELEGT, SELBSTANMIETUNG, UEBERWACHUNG, RUNDUM, POSTSPERRE, VERSICHID, ABRECHNUNGSART, WAEHRUNG, BERECHNUNGSZEIT, ANZAHLOEFF, T1ZEIT, T2ZEIT, T3ZEIT, LAGE, BLOCK, PREISGRUPPEINDEX) VALUES ';
        s +='('+new_anlagennummer+', ';                          //ANLAGENNUMMER
        s += ZQuery1.Fields.FieldByName('GESCHAEFTSTELLE').AsString+', ';
        s += ZQuery1.Fields.FieldByName('FACHNUMMER').AsString+', ';
        s += IntToStr(Abs(StrToIntDef(FormTools.sg_groessen.Cells[1,ZQuery1.Fields.FieldByName('GROESSENID').AsInteger],0))) +', ';
        s += ZQuery1.Fields.FieldByName('ANZEIGHOEHE').AsString+', ';
        s += ZQuery1.Fields.FieldByName('ANZEIGBREITE').AsString+', ';
        s += ZQuery1.Fields.FieldByName('FACHART').AsString+', ';
        s += ZQuery1.Fields.FieldByName('SPERRE').AsString+', ';
        s += ZQuery1.Fields.FieldByName('RESERVIERUNG').AsString+', ';
        s += ZQuery1.Fields.FieldByName('ATTRAPPE').AsString+', ';
        s += ZQuery1.Fields.FieldByName('BELEGT').AsString+', ';
        s += ZQuery1.Fields.FieldByName('SELBSTANMIETUNG').AsString+', ';
        s += ZQuery1.Fields.FieldByName('UEBERWACHUNG').AsString+', ';
        s += ZQuery1.Fields.FieldByName('RUNDUM').AsString+', ';
        s += ZQuery1.Fields.FieldByName('POSTSPERRE').AsString+', ';
        s += FormTools.e_versichId.Text+', ';
        if ZQuery1.Fields.FieldByName('ABRECHNUNGSART').IsNull then s += 'NULL, ' else s += ZQuery1.Fields.FieldByName('ABRECHNUNGSART').AsString+', ';
        if ZQuery1.Fields.FieldByName('WAEHRUNG').IsNull then s += 'NULL, ' else s += ZQuery1.Fields.FieldByName('WAEHRUNG').AsString+', ';
        s += ZQuery1.Fields.FieldByName('BERECHNUNGSZEIT').AsString+', ';
        s += ZQuery1.Fields.FieldByName('ANZAHLOEFF').AsString+', ';
        s += '''' + FormatDateTime('yyyy-mm-dd hh:nn:ss', ZQuery1.Fields.FieldByName('T1ZEIT').AsDateTime)+ ''', ';
        s += '''' + FormatDateTime('yyyy-mm-dd hh:nn:ss', ZQuery1.Fields.FieldByName('T2ZEIT').AsDateTime)+ ''', ';
        s += '''' + FormatDateTime('yyyy-mm-dd hh:nn:ss', ZQuery1.Fields.FieldByName('T3ZEIT').AsDateTime)+ ''', ';
        s += ZQuery1.Fields.FieldByName('LAGE').AsString+', ';
        s += ZQuery1.Fields.FieldByName('BLOCK').AsString+', ';
        if ZQuery1.Fields.FieldByName('PREISGRUPPEINDEX').IsNull then s += 'NULL' else s += ZQuery1.Fields.FieldByName('PREISGRUPPEINDEX').AsString;
        s += ') MATCHING (ANLAGENNUMMER, FACHNUMMER);';
        }

        // Export aus Cenadco DB:
        {
        INSERT INTO CEN_SDL_BOX(
        - ID,
        + ANLAGENNUMMER,
        + FACHNUMMER,
        - NICHTUEBERWACHTSEIT,
        + UEBERWACHT,
        + CEN_SDL_BOXSIZES_ID,
        - CEN_SC_ID,
        - BOXGROUP,
        0 MASTERSLAVE,
        - HOSTNO,
        - HOSTSIZENAME,
        0 DUMMY,
        + RACKNO, (BLOCK)
        - STATUS,
        1 COMPANYNO,
        + ORDERINBLOCK, (Zeilenhöhe, evtl enumerator??)
        0 RENTALSTATE
        )
        VALUES(

        144,
        1,
        144,
        NULL,
        1,
        4,
        NULL,
        NULL,
        0,
        NULL,
        NULL,
        0,
        8,
        NULL,
        1,
        18,
        0);
        }

        if(ZQuery1.Fields.FieldByName('BLOCK').AsString = block_bak)then
          i := i+1
        else
          i := 1;
        orderInBlock := intToStr(i);
        block_bak := ZQuery1.Fields.FieldByName('BLOCK').AsString;

        //s := 'UPDATE OR INSERT INTO CEN_SDL_BOX (ANLAGENNUMMER, FACHNUMMER, UEBERWACHT, CEN_SDL_BOXSIZES_ID, MASTERSLAVE, DUMMY, RACKNO, COMPANYNO, ORDERINBLOCK, RENTALSTATE) VALUES ';
        s := 'UPDATE OR INSERT INTO CEN_SDL_BOX (ANLAGENNUMMER, FACHNUMMER, UEBERWACHT, CEN_SDL_BOXSIZES_ID, MASTERSLAVE, DUMMY, RACKNO, COMPANYNO, ORDERINBLOCK) VALUES ';

        s +='('+new_anlagennummer+', ';                                     // ANLAGENNUMMER
        s += ZQuery1.Fields.FieldByName('FACHNUMMER').AsString+', ';        // Fachnummer
        s += ZQuery1.Fields.FieldByName('UEBERWACHUNG').AsString+', ';      // UEBERWACHT
        s += IntToStr(Abs(StrToIntDef(FormTools.sg_groessen.Cells[1,ZQuery1.Fields.FieldByName('GROESSENID').AsInteger],0))) +', '; // CEN_SDL_BOXSIZES_ID
        s += '0, ';                                                         // MASTERSLAVE
        s += ZQuery1.Fields.FieldByName('ATTRAPPE').AsString+', ';          // DUMMY oder Attrappe
        s += ZQuery1.Fields.FieldByName('BLOCK').AsString+', ';             // RACKNO
        s += '1, ';                                                         // COMPANYNO
        s += orderInBlock;                                                  // orderInBlock
        // s += orderInBlock+', ';                                          // orderInBlock
        // s += '0';                                                        // RENTALSTATE
        s += ') MATCHING (ANLAGENNUMMER, FACHNUMMER);';

        FormTools.SynEdit_export.Lines.Add(s);
      end;


      ZQuery1.Next;
    end;
    //FormTools.Memo_export.Lines.EndUpdate;
    FormTools.SynEdit_export.Lines.EndUpdate;
  except
    on E: Exception do
    begin
      //
    end;
  end;

  ////////////////////// SC-Tabelle ///////////////////
  log_common('SC-Tabelle:'+ IntToStr(FormTools.sg_sctable.RowCount)+' Einträge');
  for scRow := 1 to FormTools.sg_sctable.RowCount - 1 do begin
    // Insert Beispiel
    // INSERT INTO SC (ANLAGENNUMMER, GESCHAEFTSTELLE, PARTYLINE, SC, ERSTEFACHNR, LETZTEFACHNR, SCGRUPINDEX) VALUES (75, 1, 0, 2, -1, -1, 0);
    if (FormTools.sg_sctable.Cells[7,scRow] = '1') then
    begin
      s := 'INSERT INTO CEN_SC (ANLAGENNUMMER, GESCHAEFTSTELLE, PARTYLINE, SC, ERSTEFACHNR, LETZTEFACHNR, SCGRUPINDEX) VALUES ';
      //s +='('+FormTools.sg_sctable.Rows[scRow].CommaText+'); ';
      s +='(';
      s += FormTools.sg_sctable.Cells[0,scRow]+',';
      s += FormTools.sg_sctable.Cells[1,scRow]+',';
      s += FormTools.sg_sctable.Cells[2,scRow]+',';
      s += FormTools.sg_sctable.Cells[3,scRow]+',';
      s += FormTools.sg_sctable.Cells[4,scRow]+',';
      s += FormTools.sg_sctable.Cells[5,scRow]+',';
      s += FormTools.sg_sctable.Cells[6,scRow];
      s +=');';
      //FormTools.Memo_export.lines.Add(s);
      FormTools.SynEdit_export.Lines.Add(s);
    end;

  end;
  //s := 'COMMIT WORK;';
  //FormTools.Memo_export.lines.Add(s);
  //FormTools.SynEdit_export.Lines.Add(s);
end;

procedure TMainForm.log_common(s:string);
var logfilename, dir : String;

begin
  dir := 'log';
  if not DirectoryExists(dir) then
  begin
    CreateDir(dir);
  end;
  logfilename := dir+'\SCConnectTest_'+FormatDateTime('YYYY-MM-DD',now)+'.log';
  FormTools.memo1.lines.add(s);
  writeLog(s,logfilename);
end;

procedure TMainForm.b_toolsClick(Sender: TObject);
var userInput, sTime: string;
  actualTime: TDateTime;

begin
  actualTime := Now;
  sTime := FormatDateTime('ddmmnn', actualTime);
  //showMessage(sTime);
  if (iniSettings.debug = 1) then
  begin
    FormTools.Show;
  end else
  begin
    userInput := InputBox('Passwort', 'Please enter the Passcode:', '');
    //if userInput = '?2024!GunneboMDF' then
    if userInput = '?'+sTime+'!' then
    begin
      FormTools.Show;
    end else ShowMessage('Keine Berechtigung');
  end;
end;



procedure TMainForm.DBGrid1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if(selected_dbId <> 1) then markEditor(1);
end;



procedure TMainForm.DBGrid2MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if(selected_dbId <> 2) then markEditor(2);
end;

procedure TMainForm.Edit_filter2Change(Sender: TObject);
begin
  FilterListbox(Edit_filter2.Text);
end;

procedure TMainForm.Edit_filter2Click(Sender: TObject);
begin
  if(selected_dbId <> 2) then markEditor(2);
end;

procedure TMainForm.Edit_filterClick(Sender: TObject);
begin
  if(selected_dbId <> 1) then markEditor(1);
end;

procedure TMainForm.markEditor(dbId:integer);
begin
  selected_dbId := dbId;
  case dbId of
    1:begin
      DBGrid1.Color := clWindow;
      DBGrid2.Color := clSilver;
      ListBox_tables1.Color:=clWindow;
      ListBox_tables2.Color:=clSilver;
    end;
    2:begin
      DBGrid1.Color := clSilver;
      DBGrid2.Color := clWindow;
      ListBox_tables1.Color:=clSilver;
      ListBox_tables2.Color:=clWindow
    end
  else

  end;
  //getAllTables(dbId);
end;


procedure TMainForm.Edit_filterChange(Sender: TObject);
begin
  FilterListbox(Edit_filter.Text);
end;

procedure TMainForm.e_pw1Change(Sender: TObject);
begin
  iniSettings.dbPw1:=e_pw1.Text;
end;

procedure TMainForm.e_pw2Change(Sender: TObject);
begin
  iniSettings.dbPw2:=e_pw2.Text;
end;


procedure TMainForm.e_SQLQueryKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = 13 then
  begin
     SqlExecute(e_SQLQuery.Text);
  end;
end;

procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  WriteSettings(iniSettings);
end;



procedure TMainForm.FormDestroy(Sender: TObject);
begin
  TableList1.Free;
  TableList2.Free;
  FormTools.Free;
end;


procedure TMainForm.refreshConnection1;
begin
  ZConnection1.Disconnect;
  ZConnection1.Connect;
  showTable(actualTable);
end;

procedure TMainForm.b_refreshClick(Sender: TObject);
begin
  refreshConnection1;
end;

function TMainForm.openDatabase(conn:TZConnection; dbId:integer ):boolean;
begin
  conn.Disconnect;
  log_common('Datenbank getrennt.');
  if (dbId = 1)then
  begin
    conn.Database := iniSettings.dbFile1;
    conn.Protocol := iniSettings.protocol1;
    conn.Port := iniSettings.port1;
    conn.Password:=iniSettings.dbPw1;
    conn.User:=iniSettings.dbUser1;
  end;
  if (dbId = 2)then
  begin
    conn.Database := iniSettings.dbFile2;
    conn.Protocol := iniSettings.protocol2;
    conn.Port := iniSettings.port2;
    conn.Password:=iniSettings.dbPw2;
    conn.User:=iniSettings.dbUser2;
  end;

  try
    conn.Connect;
    log_common('Datenbank erfolgreich verbunden.');
    log_common('Datenbank:'+conn.Database);
    log_common('Protocol:'+conn.Protocol);
    log_common('Port:'+ IntToStr(conn.Port));
    getAllTables(selected_dbId);
    Result := true;
  except
    on E: Exception do
    begin
      ShowMessage('Fehler beim Verbinden zur Datenbank: ' + E.Message);
      mainform.log_common('Fehler beim Verbinden zur Datenbank: ' + E.Message);
      Result:= false;
    end;

  end;



end;

procedure TMainForm.b_chooseSrcClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    OpenDialog1.Filter:= 'Firebird-Files|*.fdb|Interbase-Files|*.gdb';
    iniSettings.dbFile1:= OpenDialog1.FileName;
    WriteSettings(iniSettings);
    //ZConnection1.Disconnect;
    //ZConnection1.Database:=iniSettings.dbFile1;
    //if(lowerCase(ExtractFileExt(iniSettings.dbFile1)) = '.gdb') then ZConnection1.Protocol:= 'interbase-6';
    //ZConnection1.connect;
    openDatabase(ZConnection1,1);
    Label2.Caption:=iniSettings.dbFile1;
    //getAllTables();
  end;
end;


procedure TMainForm.B_whereClick(Sender: TObject);
begin
  e_SQLQuery.Text:= e_SQLQuery.Text+' WHERE ANLAGENNUMMER = ';
end;

procedure TMainForm.exportFachVW(AFileName: string);
var
  f: TextFile;
  i, iFachstart, iFachstop: Integer;
  s,sql, block, fachstart, fachstop: string;
  DataSet: TDataSet;
  columns : Array[0..3] of string;
const
  DELIMITER = ',';
begin
  // Datei zum Schreiben öffnen
  AssignFile(f, AFileName);
  Rewrite(f);



  // Spaltennamen schreiben
  s := ';KOPF';
  Writeln(f, s);


  sql := 'SELECT * FROM ANLAGE WHERE ANLAGENNUMMER = 1';
  ZQuery1.SQL.Text:= sql;
  try
    ZQuery1.Open;
    while not ZQuery1.EOF do
    begin
      block := ZQuery1.Fields.FieldByName('BLOCK').AsString;
      fachstart := ZQuery1.Fields.FieldByName('FACHSTART').AsString;
      fachstop := ZQuery1.Fields.FieldByName('FACHSTOP').AsString;
      ZQuery1.Next;




      s := block + DELIMITER;
      s += fachstart + DELIMITER;
      s += fachstop + DELIMITER;
      Writeln(f, s);
    end;
  except
    on E: Exception do
    begin
      log_common(E.Message);
    end;
  end;
  CloseFile(f);
  ShowMessage('Tabelle Exportiert nach '+AFileName);
end;


procedure ExportDBGridToCSV(AGrid: TDBGrid; AFileName: string; Delimiter: Char);
var
  f: TextFile;
  i: Integer;
  s, path: string;
  DataSet: TDataSet;
begin
  DataSet := AGrid.DataSource.DataSet;


  path := extractFilePath(Application.ExeName)+'exporte\';
  if not DirectoryExists(path) then
  begin
    if CreateDir(path) then
      //showMessage('Ordner "'+path+'" wurde erfolgreich erstellt.')
    else begin
      showMessage('Fehler beim Erstellen des Ordners '+path);
      Exit;
    end;
  end;

  // Datei zum Schreiben öffnen
  AssignFile(f, path+AFileName);
  Rewrite(f);

  // Spaltennamen schreiben
  s := '';
  for i := 0 to AGrid.Columns.Count - 1 do
  begin
    if i > 0 then
      s := s + Delimiter;
    s := s + AGrid.Columns[i].Title.Caption;
  end;
  Writeln(f, s);

  // Daten durchgehen
  DataSet.First;
  while not DataSet.Eof do
  begin
    s := '';
    for i := 0 to AGrid.Columns.Count - 1 do
    begin
      if i > 0 then
        s := s + Delimiter;
      s := s + DataSet.FieldByName(AGrid.Columns[i].FieldName).AsString;
    end;
    Writeln(f, s);
    DataSet.Next;
  end;

  // Datei schließen
  CloseFile(f);
  ShowMessage('Tabelle Exportiert nach '+path+AFileName);
end;



procedure TMainForm.b_exportTableClick(Sender: TObject);
begin
  //.SaveToFile(ExtractFilePath(Application.ExeName)+'export.csv');
  ExportDBGridToCSV(DBGrid1, 'export_'+actualTable+'.csv', ';');
end;

procedure TMainForm.b_fachvwClick(Sender: TObject);
begin
  ExportFachVW(ExtractFilePath(Application.ExeName)+'FachVWTest.txt');
end;

procedure TMainForm.b_defaultpw1Click(Sender: TObject);
begin
  e_pw1.Text:= '19205300';
end;

procedure TMainForm.b_defaultpw2Click(Sender: TObject);
begin
  e_pw2.Text:= 'Bl2020!?';
end;

procedure TMainForm.b_resetSC11UserClick(Sender: TObject);
begin
  SC_resetDefaultUser;
end;

procedure TMainForm.b_toolsMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if ssShift in Shift then FormTools.Show;
end;


procedure TMainForm.b_chooseDstClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    OpenDialog1.Filter:= 'Firebird-Files|*.fdb|Interbase-Files|*.gdb';
    iniSettings.dbFile2:= OpenDialog1.FileName;
    WriteSettings(iniSettings);
    //ZConnection2.Disconnect;
    //ZConnection2.Database:=iniSettings.dbFile2;
    //ZConnection2.connect;
    openDatabase(ZConnection2,2);
    Label3.Caption:=iniSettings.dbFile2;
  end;
end;

procedure TMainForm.ListBox_tables2Click(Sender: TObject);
begin
  if(selected_dbId <> 2) then markEditor(2);
  actualTable := ListBox_tables2.GetSelectedText;
  showTable(actualTable);
end;

procedure TMainForm.rg_scVersionClick(Sender: TObject);
begin
  iniSettings.sc_version:= rg_scVersion.ItemIndex;
  WriteSettings(iniSettings);
end;

procedure TMainForm.SqlExecShow(s:string);
begin
  //Datasource1.DataSet := ZQuery1;
  //Datasource2.DataSet := ZQuery2;

  if(selected_dbId = 1)then
  begin
    DBGrid1.DataSource := Datasource1;
    try
      ZQuery1.SQL.Text:= s;
      e_SQLQuery.Text := s;
      ZQuery1.Open;
    except
      on E: Exception do
      begin
        //
        showMessage(E.Message);
      end;
    end;
  end;

  if(selected_dbId = 2)then
  begin
    DBGrid2.DataSource := Datasource2;
    try
      ZQuery2.SQL.Text:= s;
      e_SQLQuery.Text := s;
      ZQuery2.Open;
    except
      on E: Exception do
      begin
        //
      end;
    end;
  end;



end;



procedure TMainForm.getAllTables(dbId:integer);
var
  sql:string;
  i : integer;

begin
  sql := 'SELECT rdb$relation_name FROM rdb$relations WHERE rdb$view_blr is null AND (rdb$system_flag is null or rdb$system_flag = 0) ORDER BY RDB$RELATION_NAME ';

  if (dbId = 1)then
  begin
    TableList1.Clear;
    ZQuery1.SQL.Text:= sql;
    try

      ZQuery1.Open;
      DBGrid1.DataSource := nil;
      Datasource1.DataSet := ZQuery1;
      //Datasource2.DataSet := ZQuery2;
       while not ZQuery1.EOF do
        begin
          for i := 0 to ZQuery1.FieldCount - 1 do
            TableList1.Add(ZQuery1.Fields[i].AsString);
          ZQuery1.Next;
        end;
       FilterListbox(Edit_Filter.Text);
       ListBox_tables1.ItemIndex:=-1;

    except
      on E: Exception do
      begin

      end;
    end;
  end;

  if (dbId = 2)then
  begin
    TableList2.Clear;
    ZQuery2.SQL.Text:= sql;
    try

      ZQuery2.Open;
      DBGrid2.DataSource := nil;
      Datasource2.DataSet := ZQuery2;
       while not ZQuery2.EOF do
        begin
          for i := 0 to ZQuery2.FieldCount - 1 do
            TableList2.Add(ZQuery2.Fields[i].AsString);
          ZQuery2.Next;
        end;
       FilterListbox(Edit_Filter2.Text);
       ListBox_tables2.ItemIndex:=-1;

    except
      on E: Exception do
      begin

      end;
    end;
  end;



end;

procedure TMainForm.ListBox_tables1Click(Sender: TObject);
begin
  if(selected_dbId <> 1) then markEditor(1);
  actualTable := ListBox_tables1.GetSelectedText;
  showTable(actualTable);
end;

procedure TMainForm.MainFormSizeConstraintsChange(Sender: TObject);
begin
  DBGrid1.Width:= 300;
end;

function TMainForm.getQuersumme:integer;
var
  sql, s_qs :string;
  qs : integer;
begin
  qs := 0;
  s_qs := '0';
  sql := 'SELECT SUM(x1 + y1 + x2 + y2 + x3 + y3 + x4 + y4) AS Summe FROM anlage';
  ZQuery1.SQL.Text:= sql;
  try
    ZQuery1.Open;
    while not ZQuery1.EOF do
     begin
       s_qs := ZQuery1.Fields[0].AsString;
       ZQuery1.Next;
     end;
  except on
    E: Exception do
    begin

    end;
  end;
  TryStrToInt(s_qs,qs);
  Result := qs;
end;

procedure TMainform.getGeneratorValue(table:string);
var
  sql,GeneratorName :string;
begin

  GeneratorName := table+'_ID_GEN';
  l_genid.Caption := GeneratorName+':';
  sql := 'SELECT GEN_ID(' + GeneratorName + ', 0) FROM RDB$DATABASE';
  ZQuery1.SQL.Text:= sql;
  try
    ZQuery1.Open;
    while not ZQuery1.EOF do
    begin
      l_genid.Caption := l_genid.Caption+ZQuery1.Fields[0].AsString;
      ZQuery1.Next;
    end;
  except on E: Exception do
  begin
    l_genid.Caption := l_genid.Caption+'---';
  end;
 end;

end;


procedure TMainForm.TB_2DBChange(Sender: TObject);
begin
  repaint_FormElements;
end;

procedure TMainForm.repaint_FormElements;
begin
  if(TB_2DB.Checked)then
  begin
    if (fileExists(iniSettings.dbFile2)) then
    begin

        Label3.Caption:=iniSettings.dbFile2;
        selected_dbId := 2;

        DBGrid2.Visible := true;
        DBNavigator2.Visible:= true;
        Label3.Visible := true;
        b_chooseDst.Visible:= true;
        ListBox_tables2.Visible:= true;
        edit_filter2.Visible:=true;
        l_filter2.Visible:=true;
        e_pw2.Visible:=true;
        b_defaultPw2.Visible:=true;
        DBGrid1.Width:= MainForm.Width Div 2 - ListBox_tables1.Width - 5;
        DBNavigator1.Width := DBGrid1.Width;

        ListBox_tables2.left := DBGrid1.Left+DBGrid1.Width + 1;
        edit_filter2.Left := ListBox_tables2.left;
        l_filter2.Left := ListBox_tables2.left;
        e_pw2.Left := ListBox_tables2.left;

        DBGrid2.Left:= ListBox_tables2.Left + ListBox_tables2.Width + 1;
        DBGrid2.Width:= DBGrid1.Width;
        DBNavigator2.Width := DBGrid1.Width;
        DBNavigator2.Left:= DBGrid2.Left;
        Label3.Left := DBGrid2.Left + b_chooseDst.Width + 3;
        b_chooseDst.Left:= DBGrid2.Left;

        if (openDatabase(ZConnection2,2)= true) then getAllTables(2);


    end



    else Label3.Caption:='File not found:'+iniSettings.dbFile2;



  end else
  begin
    DBGrid1.Width:= MainForm.Width - ListBox_tables1.Width - 20;
    DBNavigator1.Width := DBGrid1.Width;
    DBGrid2.Visible := false;
    DBNavigator2.Visible:= false;
    ListBox_tables2.Visible:= false;
    Label3.Visible := false;
    b_chooseDst.Visible:= false;
    edit_filter2.Visible:=false;
    l_filter2.Visible:=false;
    e_pw2.Visible:=false;
    b_defaultPw2.Visible:=false;
    ZConnection2.Disconnect;


  end;
  markEditor(selected_dbId);
end;



end.

