unit tools;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ValEdit,
  ZDataset, DCPdes, DCPsha1, DCPmd5, DCPcrypt2, Grids, ExtCtrls,
  SynHighlighterSQL, SynEdit;

const
  MaxRows = 1000000; // Anzahl der maximalen Zeilen in der CSV-Datei
  MaxColumns = 100; // Anzahl der maximalen Spalten in der CSV-Datei

type
  TStringArray = array of string;
  T2DStringArray = array of TStringArray;


{
type
  TLicenses = class
  private
    FSafeNet: string;
    FElektronik: string;
    FVideo: string;
  public
    constructor Create(ASafeNet,ASafeNetA, AElektronik, AGraphikterminals, ATastaturles: string);
    // Eigenschaften
    property SafeNet: string read FSafeNet write FSafeNet;
    property SafeNetA: string read FSafeNetA write FSafeNetA;
    property Elektronik: string read FElektronik write FElektronik;
    property Graphikterminals: string read FGraphikterminals write FGraphikterminals;
    property Tastaturles: string read FTastaturles write FTastaturles;
  end;
}


type

  { Tform_tools }

  Tform_tools = class(TForm)
    b_exec_script: TButton;
    b_parseFreischaltCodes: TButton;
    b_encrypt: TButton;
    b_decrypt: TButton;
    b_genereate_script: TButton;
    b_recalc_qs: TButton;
    b_import_csv: TButton;
    b_save_export: TButton;
    b_sc_add: TButton;
    b_sc_del: TButton;
    Cb_matchBreite: TCheckBox;
    ckb_onlyBlock: TCheckBox;
    DCP_3des1: TDCP_3des;
    DCP_md5_1: TDCP_md5;
    DCP_sha1_1: TDCP_sha1;
    e_qs_csv_all: TEdit;
    e_qs_csv_new: TEdit;
    e_dmfLicense: TEdit;
    e_konfig1License: TEdit;
    e_qs_csv: TEdit;
    e_versichId: TEdit;
    e_anlagennummeralt: TEdit;
    e_toBox: TEdit;
    e_fromBox: TEdit;
    e_anlagennummer: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    ll_qs4: TLabel;
    l_lastGroessenId: TLabel;
    ll_qs1: TLabel;
    ll_qs2: TLabel;
    ll_qs3: TLabel;
    l_DMFLicense: TLabel;
    l_DMFLicense1: TLabel;
    l_qs_db: TLabel;
    Memo1: TMemo;
    memo_freischaltcodes: TMemo;
    rg_scVersion: TRadioGroup;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    sg_sctable: TStringGrid;
    sg_konfig1: TStringGrid;
    sg_groessen: TStringGrid;
    SynEdit_export: TSynEdit;
    SynSQLSyn1: TSynSQLSyn;
    VLE_devices: TValueListEditor;


    ///////////////////////////////////////////////////////

    procedure b_decryptClick(Sender: TObject);
    procedure b_encryptClick(Sender: TObject);
    procedure b_exec_scriptClick(Sender: TObject);
    procedure b_genereate_scriptClick(Sender: TObject);
    procedure b_import_csvClick(Sender: TObject);
    procedure b_parseFreischaltCodesClick(Sender: TObject);
    procedure b_save_exportClick(Sender: TObject);
    procedure b_recalc_qsClick(Sender: TObject);
    procedure b_sc_addClick(Sender: TObject);
    procedure b_sc_delClick(Sender: TObject);

    procedure e_anlagennummeraltDblClick(Sender: TObject);
    procedure e_qs_csvChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    function ReadCSVFile(const FileName: string):T2DStringArray;

    function getCSVQuersumme(excluded:string):integer;
    procedure recalc_qs;
    procedure sg_groessenClick(Sender: TObject);
    procedure sg_sctableResize(Sender: TObject);
    procedure sqlquery_groessenzuordnung;
    function getCSVGroessenId(anlagennummer:string; hoehe:integer;breite:integer):integer;
    function getCSVVersichId(anlagennummer:string):integer;

    procedure VLE_devicesMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    //procedure VLE_devicesClick(Sender: TObject);

    procedure ImportCustomerData;
    procedure VLE_devicesSelectEditor(Sender: TObject; aCol, aRow: Integer;
      var Editor: TWinControl);

    procedure readDevices;
    procedure readKonfig;
    procedure readSC;
    procedure readKonfig1;


    procedure parseFreischaltcodes;
    procedure get_sqlFirstLastBox;
    procedure execSqlInDb2 ;
  private

  public

    var lastGroessenId : integer;
  end;



var

  form_tools: Tform_tools;
  CSVArray_anlage: T2DStringArray;
  CSVArray_groessen: T2DStringArray;
  CSVArray_versich: T2DStringArray;
  CSVArray_devices: T2DStringArray;
  CSVArray_konfig_uncrypt: T2DStringArray;
  CSVArray_SC: T2DStringArray;
  CSVArray_konfig1: T2DStringArray;
  current_branch: string;


implementation
  uses mainunit;
{$R *.lfm}

{ Tform_tools }

// Hilfsfunktion für Min
function Minimum(const A, B: Integer): Integer;
begin
  if A < B then
    Result := A
  else
    Result := B;
end;


procedure DisplayCSVArray(arr : T2DStringArray);
var
  Row, Col: Integer;
begin
  FormTools.Memo1.Clear;
  FormTools.Memo1.Lines.BeginUpdate;
  for Row := 0 to High(arr) do
  begin
    //for Col := 0 to Minimum(Length(arr[Row]) - 1) do
    for Col := 0 to High(arr[Row]) do
      FormTools.Memo1.Lines.Add('CSVArray['+ intToStr(Row) + ']['+ intToStr(Col)+ '] = ' + arr[Row, Col]);

  end;

  FormTools.Memo1.Lines.EndUpdate;
end;


// Bereinigen von Dateinamen
function SanitizeFileName(const FileName: string): string;
const
  InvalidChars: set of Char = ['\', '/', ':', '*', '?', '"', '<', '>', '|'];
var
  i: Integer;
  CleanName: string;
begin
  CleanName := '';
  for i := 1 to Length(FileName) do
  begin
    if not (FileName[i] in InvalidChars) then
      CleanName := CleanName + FileName[i];
    // Optional: Statt Entfernen kannst du auch ersetzen, z.B. durch '_'
    // else
    //   CleanName := CleanName + '_';
  end;
  Result := CleanName;
end;


// Einlesen der CSV und übergeben incl. der Kopfzeile
function Tform_tools.ReadCSVFile(const FileName: string): T2DStringArray;
var
  FileLines: TStringList;
  TempList: TStringList;
  Row, Col, i: Integer;
  CSVArray: T2DStringArray;
  s,s1 : string;
begin
  FileLines := TStringList.Create;
  TempList := TStringList.Create;
  try
    FileLines.LoadFromFile(FileName);
    for i := 0 to Filelines.Count-1 do
    begin
      if(trim(Filelines[i]) <> '')then TempList.Add(Filelines[i]);
    end;

    SetLength(CSVArray, TempList.Count, MaxColumns);

    for Row := 0 to Minimum(TempList.Count -1, MaxRows-1) do
    begin
      CSVArray[Row] := TempList[Row].Split(';'); // Trennung der Werte durch das Semikolon

      // und jetzt die Zeile Feld für Feld durchgehen und eventuelle " rausschmeißen
      for Col := 0 to Length(CSVArray[Row]) -1 do
      begin
        s := CSVArray[Row][Col];

        if (Length(s) >= 2) and (s[1] = '"') and (s[Length(s)] = '"') then
        begin
          s1 := Copy(s, 2, Length(s) - 2);
          CSVArray[Row][Col] := s1;

          //mainform.log_common(ExtractFileName(FileName)+' Row'+IntToStr(Row)+' Col'+intToStr(Col)+' :'+s+' -> '+s1);
        end;


      end;
    end;

  finally
    FileLines.Free;
    TempList.Free;
  end;
  Result := CSVArray;
end;

// Quersumme der Tabelle für SC11
function Tform_tools.getCSVQuersumme(excluded:string):integer;
var
  Row, qs: Integer;
begin
  qs := 0;
  // ohne Kopf,ab 1
  for Row := 1 to High(CSVArray_anlage) do
  begin
    if( (CSVArray_anlage[Row,0] <> excluded) or (excluded = '') ) then
      begin
        qs := qs
         + StrToIntDef(CSVArray_anlage[Row,3],0)
         + StrToIntDef(CSVArray_anlage[Row,4],0)
         + StrToIntDef(CSVArray_anlage[Row,5],0)
         + StrToIntDef(CSVArray_anlage[Row,6],0)
         + StrToIntDef(CSVArray_anlage[Row,7],0)
         + StrToIntDef(CSVArray_anlage[Row,8],0)
         + StrToIntDef(CSVArray_anlage[Row,9],0)
         + StrToIntDef(CSVArray_anlage[Row,10],0);
      end;

  end;
  result := qs;
end;

// sucht in der CSV die korrekte Höhen.ID anhand der Anlagennummer, Höhe und Breite heraus
function Tform_tools.getCSVGroessenId(anlagennummer:string; hoehe:integer; breite:integer):integer;
var
  Row, id, csvId, csvHoehe, csvBreite: Integer;
  col_anlagennummer, col_breite, col_hoehe:integer;
begin
  id := -1;

  // memo1.Clear;
  // ohne Kopf,ab 1


  // SC11: ID	HOEHE	BREITE	BEZEICHNUNG	ANLAGENNUMMER	GESCHAEFTSTELLE	VOLUMEINDEX	MAXWEIGHT	MAXWEIGHTDEPO
  if(rg_scVersion.ItemIndex = 0)then
  begin
   col_anlagennummer := 4;
   col_hoehe := 1;
   col_breite := 2;
  end;
  // CEN: ID BOXTYPE HEIGHT WIDTH BOXDEPTH SIZENAME ANLAGENNUMMER VOLUMEID MAXWEIGHT MAXWEIGHTDEPO VIEWHEIGHT VIEWWIDTH
  if(rg_scVersion.ItemIndex = 1)then
  begin
   col_anlagennummer := 6;
   col_hoehe := 2;
   col_breite := 3;
  end;

  for Row := 1 to High(CSVArray_groessen) do
  begin
    csvId := StrToIntDef(CSVArray_groessen[Row,0],0); // ID ist immer COL 0
    if(csvId > lastGroessenId) then lastGroessenId := csvId;
    // nur die Einträge mit der korrekten Anlagennummer
    if (CSVArray_groessen[Row,col_anlagennummer] = anlagennummer) then
      begin

       csvHoehe := StrToIntDef(CSVArray_groessen[Row,col_hoehe],0); // Höhe
       csvBreite := StrToIntDef(CSVArray_groessen[Row,col_breite],0);
       //memo1.Lines.add(intToStr(csvId)+':'+intToStr(csvHoehe)+':'+intToStr(csvBreite));
       mainform.log_common('Höhe:'+ IntToStr(csvHoehe) + ' Breite:' + IntToStr(csvBreite));
       if((csvHoehe = hoehe)and((csvBreite = breite)or(breite = -1))) then
       begin
         id := csvId;
         mainform.log_common('Größe matched:'+intToStr(csvId));
       end;

      end;

  end;
  if(id = -1) then
  begin
    inc(lastGroessenId);
    id := - lastGroessenId;
  end;
  result := id;
  l_lastGroessenId.Caption:= intToStr(lastGroessenId);
end;

// sucht in der CSV die korrekte Versich.ID anhand der Anlagennummer heraus
function Tform_tools.getCSVVersichId(anlagennummer:string):integer;
var
  Row, csvId: Integer;
begin
  csvId := -1;
  // ohne Kopf,ab 1
  // Kopf: ID	BEZEICHNUNG	GEBUEHR	VERSICHERUNGSSUMME	WAEHRUNG	ANLAGENNUMMER	GESCHAEFTSTELLE	KONTROLLSUMME	OHNEMWST	STEUER	REPLIZIER
  for Row := 1 to High(CSVArray_versich) do
  begin
    if (CSVArray_versich[Row,5] = anlagennummer) then
      begin
       csvId := StrToIntDef(CSVArray_versich[Row,0],0);
      end;
  end;
  result := csvId;
end;


procedure Tform_tools.b_genereate_scriptClick(Sender: TObject);
begin
  // die gelesene ANLAGETABELLE zu neuer Tabelle übertragen und neue Werte einfügen
  //mergeTempDBWithCSVArray;
   if (rg_scVersion.ItemIndex = 0) then
     mainform.exportTable(MainForm.actualTable);
   if (rg_scVersion.ItemIndex = 1) then
     mainform.exportTableCen(MainForm.actualTable);
end;

procedure Tform_tools.b_decryptClick(Sender: TObject);
  var
    Key, EncryptedText, DecryptedText: AnsiString;
  begin
    Key := '?BeLa!EdV§2006$'; // Triple DES key (must be 24 characters long)
    EncryptedText := Memo1.Text;

     DCP_3des1.InitStr(Key, TDCP_sha1); // Initialize with the key and hash algorithm
    // DCP_3des1.InitStr(Key,TDCP_md5); //
    DecryptedText := DCP_3des1.DecryptString(EncryptedText);

    //Memo_export.Text := DecryptedText;
    //memoOutput.Lines.SaveToFile('decrypted.txt');
  end;




procedure Tform_tools.b_encryptClick(Sender: TObject);
  var
    Key, InputText, EncryptedText: AnsiString;
  begin
    Key := '?BeLa!EdV§2006$'; // Triple DES key (must be 24 characters long)
    InputText := memo1.Text;

    DCP_3des1.InitStr(Key, TDCP_sha1); // Initialize with the key, no hash algorithm needed for Triple DES
    EncryptedText := DCP_3des1.EncryptString(InputText);

    Memo1.Text := EncryptedText;
    //memoOutput.Lines.SaveToFile('encrypted.txt');
  end;

procedure Tform_tools.b_exec_scriptClick(Sender: TObject);
begin
  execSqlInDb2;
end;

// Zeilenweise das SQL-Script ausführen
procedure TForm_tools.execSqlInDb2;
var
  sql : string;
  Query1: TZQuery;
  AffectedRows, i: Integer;
begin
  sql := synedit_export.Text;

  if MessageDlg('SQL ausführen?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    if(Mainform.ZConnection2.Connected)then
    begin

      Query1 := TZQuery.Create(nil);
      Query1.Connection := Mainform.ZConnection2;

      for i := 0 to synedit_export.Lines.Count -1 do
      begin
        //memo1.Lines.Add(synedit_export.Lines[i]);
        Query1.SQL.Text:= synedit_export.Lines[i];
        try
          Query1.ExecSQL;
          //mainform.log_common(Query1.SQL.Text);
          //ShowMessage(IntToStr(Query1.RowsAffected) + ' Zeile(n) geupdated.');
        except
          on E: Exception do
          begin
            ShowMessage('Fehler bei der Ausführung des SQL-Script: ' + E.Message);
            mainform.log_common('Fehler bei der Ausführung des SQL-Script: ' + E.Message);
            Break;
          end;

        end;
      end;

      {
      Query1.SQL.Text:= sql;
      try
        Query1.ExecSQL;
        ShowMessage(IntToStr(Query1.RowsAffected) + ' Zeile(n) geupdated.');
      except
        on E: Exception do
          ShowMessage('Fehler bei der Ausführung des SQL-Script: ' + E.Message);
      end;
      }
    end else
    begin
      showMessage('keine Verbindung zur Datenbank');
    end;
  end;
end;

procedure EncryptFileWith3DES(const InputFileName, OutputFileName: string; const Key: String);
var
  InputFileStream, OutputFileStream: TFileStream;
  Cipher: TDCP_3des;
begin
  InputFileStream := TFileStream.Create(InputFileName, fmOpenRead or fmShareDenyWrite);
  try
    OutputFileStream := TFileStream.Create(OutputFileName, fmCreate or fmShareDenyWrite);
    try
      Cipher := TDCP_3des.Create(nil);
      try
        Cipher.Init(Key, SizeOf(Key), nil);
        Cipher.EncryptStream(InputFileStream, OutputFileStream, InputFileStream.Size);
      finally
        Cipher.Free;
      end;
    finally
      OutputFileStream.Free;
    end;
  finally
    InputFileStream.Free;
  end;
end;

procedure DecryptFileWith3DES(const InputFileName, OutputFileName: string; const Key: AnsiString);
var
  InputFileStream, OutputFileStream: TFileStream;
  Cipher: TDCP_3des;
begin
  InputFileStream := TFileStream.Create(InputFileName, fmOpenRead or fmShareDenyWrite);
  try
    OutputFileStream := TFileStream.Create(OutputFileName, fmCreate or fmShareDenyWrite);
    try
      Cipher := TDCP_3des.Create(nil);
      try
        Cipher.Init(Key, SizeOf(Key), nil);
        Cipher.DecryptStream(InputFileStream, OutputFileStream, InputFileStream.Size);
      finally
        Cipher.Free;
      end;
    finally
      OutputFileStream.Free;
    end;
  finally
    InputFileStream.Free;
  end;
end;



procedure Tform_tools.b_save_exportClick(Sender: TObject);
var fileName, path : String;
begin
  fileName := SanitizeFileName('data_'+ current_branch +'_A'+e_anlagennummer.Text+'.sql');
  path := extractFilePath(Application.ExeName)+'exporte\';
  if not DirectoryExists(path) then
  begin
    if CreateDir(path) then
      MainForm.log_common('Ordner "'+path+'" wurde erfolgreich erstellt.')
    else begin
      MainForm.log_common('Fehler beim Erstellen des Ordners '+path);
      Exit;
    end;

  end;

  try
    SynEdit_export.Lines.SaveToFile(path+fileName);
  except
    on E: Exception do
    begin
      ShowMessage('Fehler beim Speichern der Datei: '+ fileName +' Details: '+ E.Message);
      mainform.log_common('Fehler beim Speichern der Datei: '+ fileName +' Details: '+ E.Message);
      exit;
    end;
  end;



  ShowMessage('Datei Exportiert nach '+path+fileName);
  MainForm.log_common('Datei Exportiert nach '+path+fileName);
end;


procedure Tform_tools.recalc_qs;
var qs_db, qs_csv:integer;
begin
  qs_db := Mainform.getQuersumme;
  l_qs_db.Caption := IntToStr(qs_db); // QS der temp DB
  //l_qs_csv.Caption := intToStr(getCSVQuersumme(''));

  qs_csv := getCSVQuersumme(e_anlagennummer.Text); // die Quersumme der CSV-Exporte, ausser die aktuelle Anlagennummer
  e_qs_csv_all.Text := intToStr(getCSVQuersumme('0')); // Workaround, um die komplette QS der CSV zu sehen
  e_qs_csv.Text := intToStr(qs_csv);  // nur SQ der CSV ohne aktuell gewählte Anlagennummer
  MainForm.qs_recalc := qs_csv + qs_db;

  e_qs_csv_new.Text := intToStr(MainForm.qs_recalc); // Alles, ausser die aktuelle Anlagennummer + qs der temporären Anlage

end;

procedure Tform_tools.sg_groessenClick(Sender: TObject);
begin
  //showMessage(MainForm.get_boxDepth(sg_groessen.Cells[4,sg_groessen.Row]));
end;

procedure Tform_tools.sg_sctableResize(Sender: TObject);
var myWidth : LongInt;
begin
  myWidth :=
  sg_sctable.Width -
  sg_sctable.ColWidths[0] -
  sg_sctable.ColWidths[1] -
  sg_sctable.ColWidths[2] -
  sg_sctable.ColWidths[3] -
  sg_sctable.ColWidths[6] -
  sg_sctable.ColWidths[7] - 20;

  sg_sctable.ColWidths[4] :=  myWidth div 2 ;
  sg_sctable.ColWidths[5] :=  myWidth div 2 ;
end;





procedure Tform_tools.b_recalc_qsClick(Sender: TObject);

begin
  recalc_qs;
  sqlquery_groessenzuordnung;
end;

procedure Tform_tools.b_sc_addClick(Sender: TObject);
var default: TStringArray = ('1', '0', '0', '0', '1', '499', '1','1');
  selectedRow, lastOrderNr: integer;
begin
  SetLength(default, 8);
  //
  lastOrderNr := 0;
  if (sg_sctable.RowCount > 1)then
    begin
      //lastOrderNr := StrToIntDef(sg_sctable.Cells[6,sg_sctable.RowCount],1);
    end;
  default[0] := e_anlagennummer.Text;
  // Letzte Zeile merken und duplizieren, falls vorhanden
  if(sg_sctable.RowCount > 1) then
    begin
      default := sg_sctable.Rows[sg_sctable.RowCount - 1].ToStringArray;
    end;
  default[7] := '1';
  sg_sctable.InsertRowWithValues(sg_sctable.RowCount,default);

end;

procedure Tform_tools.b_sc_delClick(Sender: TObject);
begin
  if(sg_sctable.RowCount > 1) then
    begin
      sg_sctable.DeleteRow(sg_sctable.Row);
    end;

end;


procedure Tform_tools.e_anlagennummeraltDblClick(Sender: TObject);
begin
 e_anlagennummeralt.ReadOnly:=false;
end;

procedure Tform_tools.e_qs_csvChange(Sender: TObject);
  var qs_db : integer;
begin
  qs_db := Mainform.getQuersumme;
  MainForm.qs_recalc := StrToIntDef(e_qs_csv.Text,0) + qs_db;
  e_qs_csv_new.Text := intToStr(MainForm.qs_recalc); // Alles, ausser die aktuelle Anlagennummer + qs der temporären Anlage
end;


procedure Tform_tools.FormCreate(Sender: TObject);
begin
  // globale variablen initialisieren
  MainForm.qs_recalc := 0;
  LastGroessenId := 0;
  current_branch := '';
end;

procedure Tform_tools.FormDestroy(Sender: TObject);
begin
  //CSVArray_anlage := nil;
end;

procedure Tform_tools.FormShow(Sender: TObject);
begin
  sqlquery_groessenzuordnung;
  get_sqlFirstLastBox;
end;

procedure Tform_tools.b_import_csvClick(Sender: TObject);
begin
  ImportCustomerData;
end;

procedure Tform_tools.b_parseFreischaltCodesClick(Sender: TObject);
begin
  parseFreischaltcodes;
end;

procedure Tform_tools.ImportCustomerData;
var anlagentabelle,
  groessentabelle,
  versichtabelle,
  devicestabelle,
  konfig_uncrypttabelle,
  scTabelle ,
  konfig1Tabelle: string;
begin

  // Bei SC11
  if rg_scVersion.ItemIndex = 0 then
  begin
    anlagentabelle := 'anlage.csv';
    groessentabelle := 'groessen.csv';
    versichtabelle := 'versich.csv';
    devicestabelle := 'devices.csv';
    konfig_uncrypttabelle := 'konfig_uncrypt.csv';
    konfig1Tabelle := 'konfig1.csv';
    scTabelle := 'sc.csv';


    if SelectDirectoryDialog1.Execute then
    begin
      CSVArray_anlage := ReadCSVFile(SelectDirectoryDialog1.FileName + '\' +anlagentabelle);
      CSVArray_groessen := ReadCSVFile(SelectDirectoryDialog1.FileName + '\' +groessentabelle);
      CSVArray_devices := ReadCSVFile(SelectDirectoryDialog1.FileName + '\' +devicestabelle);
      CSVArray_konfig_uncrypt := ReadCSVFile(SelectDirectoryDialog1.FileName + '\' +konfig_uncrypttabelle);
      CSVArray_versich := ReadCSVFile(SelectDirectoryDialog1.FileName + '\' +versichtabelle);
      CSVArray_SC := ReadCSVFile(SelectDirectoryDialog1.FileName + '\' +scTabelle);
      CSVArray_konfig1 := ReadCSVFile(SelectDirectoryDialog1.FileName + '\' +konfig1Tabelle);

      // Werte ausrechnen
      readKonfig;
      recalc_qs;
      sqlquery_groessenzuordnung;
      readDevices;

      readKonfig1;
    end;


  end;

  // Bei Cenadco
  if rg_scVersion.ItemIndex = 1 then
  begin
    anlagentabelle := 'CEN_ANLAGE.csv';
    groessentabelle := 'CEN_SDL_BOXSIZES.csv';
    devicestabelle := 'CEN_DEVICES.csv';
    scTabelle := 'CEN_SC.csv';

    if SelectDirectoryDialog1.Execute then
    begin
      CSVArray_anlage := ReadCSVFile(SelectDirectoryDialog1.FileName + '\' +anlagentabelle);
      CSVArray_groessen := ReadCSVFile(SelectDirectoryDialog1.FileName + '\' +groessentabelle);
      CSVArray_devices := ReadCSVFile(SelectDirectoryDialog1.FileName + '\' +devicestabelle);
      CSVArray_SC := ReadCSVFile(SelectDirectoryDialog1.FileName + '\' +scTabelle);
      //CSVArray_konfig1 := ReadCSVFile(SelectDirectoryDialog1.FileName + '\' +konfig1Tabelle);

      // Werte ausrechnen
      //readKonfig;
      //recalc_qs;
      sqlquery_groessenzuordnung;
      readDevices;
    end;
  end;




end;

//
procedure Tform_tools.sqlquery_groessenzuordnung;
var
  sql,bezeichnung_tempDb : string;
  Query1: TZQuery;
  id_tempDb, hoehe_tempDb, breite_tempDb, breite_tempDb1, id_new : integer;
  arr_geroessen : array[0..4] of string;
begin
  id_new := -1;
  lastGroessenId := 0;
  Query1 := TZQuery.Create(nil);
  Query1.Connection := MainForm.ZConnection1;
  // Temp-DB abfragen
  sql := 'SELECT * FROM GROESSEN WHERE ANLAGENNUMMER = :anlagennummer';
  Query1.SQL.Text:= sql;
  Query1.ParamByName('anlagennummer').AsString := '1';
  Query1.Open;

  sg_groessen.RowCount:=1;

  while not Query1.EOF do
  begin
    id_tempDb := Query1.Fields.FieldByName('id').AsInteger;
    hoehe_tempDb := Query1.Fields.FieldByName('hoehe').AsInteger;
    breite_tempDb := Query1.Fields.FieldByName('breite').AsInteger;
    breite_tempDb1 := -1;
    bezeichnung_tempDb := Query1.Fields.FieldByName('Bezeichnung').AsString;

    // bei nicht gesetzter CHeckbox "Breite berücksichtigen" braucht nur die Höhe matchen
    if(Cb_matchBreite.Checked = True)then breite_tempDb1 := breite_tempDb;

    id_new := getCSVGroessenId(e_anlagennummer.Text,hoehe_tempDb,breite_tempDb1);

    arr_geroessen[0] :=  IntToStr(id_tempDb);
    arr_geroessen[1] :=  IntToStr(id_new);
    arr_geroessen[2] :=  IntToStr(hoehe_tempDb);
    arr_geroessen[3] :=  IntToStr(breite_tempDb);
    arr_geroessen[4] :=  bezeichnung_tempDb;


    sg_groessen.InsertRowWithValues(id_tempDb,arr_geroessen);
    Query1.Next;
  end;
end;

procedure Tform_tools.readDevices;
var row, col_anlagennummer, col_name :integer;
begin
  VLE_devices.Clear;
  // ohne Kopf,ab 1
  if (rg_scVersion.ItemIndex = 0) then
  begin
   col_anlagennummer := 2;
   col_name := 1;
  end;
  if (rg_scVersion.ItemIndex = 1) then
  begin
   col_anlagennummer := 3;
   col_name := 2;
  end;


  for Row := 1 to High(CSVArray_devices) do
  begin
    // ListBox1.Items.Add(CSVArray_devices[Row,1]);
    // VLE_devices.InsertRow(CSVArray_devices[Row,2], CSVArray_devices[Row,1], True);
    VLE_devices.InsertRow(CSVArray_devices[Row,col_anlagennummer], CSVArray_devices[Row,col_name], True);
  end;
  VLE_devices.Strings.Sort;
end;


procedure Tform_tools.VLE_devicesMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  e_anlagennummer.Text:= VLE_devices.Keys[VLE_devices.Row];
  current_branch := VLE_devices.Values[VLE_devices.Keys[VLE_devices.Row]];
  recalc_qs;
  sqlquery_groessenzuordnung;
  e_versichId.Text:= intToStr(getCSVVersichId(VLE_devices.Keys[VLE_devices.Row]));
  readSC;
end;

procedure Tform_tools.readKonfig;
var row:integer;
begin

  e_dmfLicense.Text:= '';
  e_konfig1License.Text:= '';
  // ohne Kopf,ab 1
  for Row := 1 to High(CSVArray_konfig_uncrypt) do
  begin
    if (CSVArray_konfig_uncrypt[Row,0] = 'License') then e_dmfLicense.Text:= CSVArray_konfig_uncrypt[Row,1];
    if (CSVArray_konfig_uncrypt[Row,0] = 'Lizenznummer') then e_konfig1License.Text:= CSVArray_konfig_uncrypt[Row,1];
  end;

end;

procedure Tform_tools.readSC;
var row,i:integer;
begin
  // TODO: In Abhängigkeit des gewählten Formats die Tabelle füllen
  // Beispiel
  {
  if (rg_scVersion.ItemIndex = 0) then
  begin
   col_anlagennummer := 2;

  end;
  if (rg_scVersion.ItemIndex = 1) then
  begin
   col_anlagennummer := 3;

  end;
  }
  sg_sctable.ClearRows;
  sg_sctable.RowCount:=1;
  sg_sctable.FixedRows:=1;
  i := 1;
  // ohne Kopf,ab 1
  if Length(CSVArray_sc) > 0 then
  begin
    for row := 1 to High(CSVArray_sc)do
    begin
      //memo1.Lines.Add(CSVArray_sc[row,0]);
      if(e_anlagennummer.Text = CSVArray_sc[row,0]) then
      begin
        sg_sctable.InsertRowWithValues(i,CSVArray_sc[row]);
        sg_sctable.Cells[7,i] := '0';
        i := i+1;
      end;

    end;
  end;


end;

procedure Tform_tools.readKonfig1;
var row:integer;
begin
  //sg_konfig1.ClearRows;
  sg_konfig1.RowCount:=2;
  // ohne Kopf,ab 1
  for row := 1 to High(CSVArray_konfig1) do
  begin
    sg_konfig1.Cells[0,1] := CSVArray_konfig1[row,7];  // SAFENET
    sg_konfig1.Cells[1,1] := CSVArray_konfig1[row,8];  // SAFENETA
    sg_konfig1.Cells[2,1] := CSVArray_konfig1[row,9];  // ELEKTRONIK
    sg_konfig1.Cells[3,1] := CSVArray_konfig1[row,6];  // GRAPHIKT
    sg_konfig1.Cells[4,1] := CSVArray_konfig1[row,10]; // VIDEOANZ
    sg_konfig1.Cells[5,1] := CSVArray_konfig1[row,18]; // VIDEOSPEICHERN
    sg_konfig1.Cells[6,1] := CSVArray_konfig1[row,12]; // GEB.VERW
    sg_konfig1.Cells[7,1] := CSVArray_konfig1[row,19]; // ZEITENST
    sg_konfig1.Cells[8,1] := CSVArray_konfig1[row,20]; // SBANMIETUNG
    sg_konfig1.Cells[9,1] := CSVArray_konfig1[row,21]; // NTDEPOT
    sg_konfig1.Cells[10,1] := CSVArray_konfig1[row,22];// TASTATURLES
  end;
  sg_sctable.FixedRows:=1;
end;

procedure Tform_tools.VLE_devicesSelectEditor(Sender: TObject; aCol,
  aRow: Integer; var Editor: TWinControl);
begin

end;

procedure Tform_tools.parseFreischaltcodes;
var row:integer;
  sl : TStringList;
  myKey, myValue : string;
  posEqual, i : integer;
begin
 sl := TStringList.Create;
 sl.Text := memo_freischaltcodes.Text;
 posEqual := 0;
 for i := 0 to sl.Count-1 do
    begin
      if(trim(sl[i]) <> '')then
      begin
        posEqual := pos('=', sl[i]);
        myKey := trim(Copy( sl[i], 1, posEqual -1));
        myValue := Copy( sl[i], posEqual + 1, Length(sl[i]));
        if myKey =   'SAFENET' then sg_konfig1.Cells[0,1] := myValue;
        if myKey =   'SAFENETA' then sg_konfig1.Cells[1,1] := myValue;
        if myKey =   'ELEKTRONIK' then sg_konfig1.Cells[2,1] := myValue;
        if myKey =   'GRAPHIKTERMINALS' then sg_konfig1.Cells[3,1] := myValue;
        if ((myKey = 'VIDEOANZEIGE')and(sg_konfig1.Cells[4,1] <> '0')) then sg_konfig1.Cells[4,1] := myValue;
        if ((myKey = 'VIDEOSPEICHERN')and(sg_konfig1.Cells[5,1] <> '0')) then sg_konfig1.Cells[5,1] := myValue;
        if ((myKey = 'GEBUEHRENVERWALTUNG')and(sg_konfig1.Cells[6,1] <> '1')) then sg_konfig1.Cells[6,1] := myValue;
        if ((myKey = 'ZEITENSTEUERUNG')and(sg_konfig1.Cells[7,1] <> '0')) then sg_konfig1.Cells[7,1] := myValue;
        if ((myKey = 'SBANMIETUNG')and(sg_konfig1.Cells[8,1] <> '0')) then sg_konfig1.Cells[8,1] := myValue;
        if ((myKey = 'NTDEPOT')and(sg_konfig1.Cells[9,1] <> '0')) then sg_konfig1.Cells[9,1] := myValue;
        if ((myKey = 'TASTATURLES')and(sg_konfig1.Cells[10,1] <> '0')) then sg_konfig1.Cells[10,1] := myValue;
        //memo1.Lines.Add(myKey+':'+myValue);
      end;
    end;
end;

procedure Tform_tools.get_sqlFirstLastBox;
var
  sql, fachmin, fachmax : string;
  Query1: TZQuery;
begin
  Query1 := TZQuery.Create(nil);
  Query1.Connection := MainForm.ZConnection1;

  // Temp-DB abfragen
  sql := 'SELECT MIN(FACHNUMMER) AS fachmin, MAX(FACHNUMMER) as fachmax FROM FACH WHERE ANLAGENNUMMER = :anlagennummer';
  Query1.SQL.Text:= sql;
  Query1.ParamByName('anlagennummer').AsString := '1';
  Query1.Open;

  while not Query1.EOF do
  begin
    fachmin := Query1.Fields.FieldByName('fachmin').AsString;
    fachmax := Query1.Fields.FieldByName('fachmax').AsString;
    Query1.Next;
  end;
  e_fromBox.Text:=fachmin;
  e_toBox.Text:=fachmax;

end;


end.

