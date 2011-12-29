unit QueryWindow;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IBConnection, sqldb, db, FileUtil, LResources, Forms,
  Controls, Graphics, Dialogs, ExtCtrls, PairSplitter, StdCtrls, Buttons,
  DBGrids, Menus, ComCtrls, SynEdit, SynHighlighterSQL, Reg, sqlscript,
  SynEditTypes, Clipbrd,grids;

type

  { TfmQueryWindow }

  TfmQueryWindow = class(TForm)
    bbClose: TBitBtn;
    FindDialog1: TFindDialog;
    imTools: TImageList;
    imTabs: TImageList;
    lmCloseTab: TMenuItem;
    lmCopy: TMenuItem;
    lmPaste: TMenuItem;
    lmSelectAll: TMenuItem;
    lmUndo: TMenuItem;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem10: TMenuItem;
    lmCut: TMenuItem;
    lmExport: TMenuItem;
    lmCommaDelemited: TMenuItem;
    lmHTML: TMenuItem;
    lmRedo: TMenuItem;
    MenuItem2: TMenuItem;
    lmFind: TMenuItem;
    lmFindAgain: TMenuItem;
    MenuItem3: TMenuItem;
    lmCopyCell: TMenuItem;
    lmExportAsComma: TMenuItem;
    lmExportAsHTML: TMenuItem;
    MenuItem5: TMenuItem;
    lmRun: TMenuItem;
    lmRunSelect: TMenuItem;
    lmRunExec: TMenuItem;
    lmRunScript: TMenuItem;
    OpenDialog1: TOpenDialog;
    PageControl1: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    pmTab: TPopupMenu;
    pmMemo: TPopupMenu;
    pmGrid: TPopupMenu;
    SaveDialog1: TSaveDialog;
    Splitter1: TSplitter;
    meQuery: TSynEdit;
    SynSQLSyn1: TSynSQLSyn;
    ToolBar1: TToolBar;
    tbNew: TToolButton;
    tbOpen: TToolButton;
    tbSave: TToolButton;
    ToolButton1: TToolButton;
    tbRun: TToolButton;
    tbCommit: TToolButton;
    tbRollback: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    tbHistory: TToolButton;
    ToolButton5: TToolButton;
    tbMenu: TToolButton;
    ToolButton6: TToolButton;
    procedure bbRunClick(Sender: TObject);
    procedure DBGrid1DblClick(Sender: TObject);
    procedure DBGridTitleClick(column: TColumn);
    procedure FindDialog1Find(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure lmCloseTabClick(Sender: TObject);
    procedure lmCommaDelemitedClick(Sender: TObject);
    procedure lmCopyCellClick(Sender: TObject);
    procedure lmCopyClick(Sender: TObject);
    procedure lmCutClick(Sender: TObject);
    procedure lmExportAsCommaClick(Sender: TObject);
    procedure lmExportAsHTMLClick(Sender: TObject);
    procedure lmHTMLClick(Sender: TObject);
    procedure lmPasteClick(Sender: TObject);
    procedure lmRedoClick(Sender: TObject);
    procedure lmRunClick(Sender: TObject);
    procedure lmRunExecClick(Sender: TObject);
    procedure lmRunScriptClick(Sender: TObject);
    procedure lmRunSelectClick(Sender: TObject);
    procedure lmSelectAllClick(Sender: TObject);
    procedure lmUndoClick(Sender: TObject);
    procedure lmFindClick(Sender: TObject);
    procedure lmFindAgainClick(Sender: TObject);
    procedure SQLScript1Exception(Sender: TObject; Statement: TStrings;
      TheException: Exception; var Continue: boolean);
    procedure tbCloseClick(Sender: TObject);
    procedure tbCommitClick(Sender: TObject);
    procedure tbHistoryClick(Sender: TObject);
    procedure tbMenuClick(Sender: TObject);
    procedure tbNewClick(Sender: TObject);
    procedure tbOpenClick(Sender: TObject);
    procedure tbRollbackClick(Sender: TObject);
    procedure tbRunClick(Sender: TObject);
    procedure tbSaveClick(Sender: TObject);
  private
    { private declarations }
    fdbIndex: Integer;
    RegRec: TRegisteredDatabase;
    ResultControls: array of TObject;
    ParentResultControls: array of TObject;
    fOptions: set of TSynSearchOption;
    ibConnection: TIBConnection;
    SqlTrans: TSQLTransaction;
  public
    OnCommit: TNotifyEvent;
    procedure Init(dbIndex: Integer);
    function GetQueryType(AQuery: string): Integer;
    function GetQuery: string;
    function CreateResultTab(QueryType: Byte; var SqlQuery: TSQLQuery; var SQLScript: TSqlScript;
      var meResult: TMemo; AdditionalTitle: string = ''): TTabSheet;
    procedure ExecuteQuery(QueryType: Integer);
    function ExecuteScript(Script: string): Boolean;
    procedure AddResultControl(ParentControl: TObject; AControl: TObject);
    procedure RemoveControls;
    function FindSqlQuery: TSqlQuery;
    function GetSQLType(Query: string; var Command: string): string;
    function GetSQLSegment(QueryList: TStringList; StartLine: Integer; var QueryType, EndLine: Integer;
      var SQLSegment: string; var IsDDL: Boolean): Boolean;
    procedure QueryAfterScroll(DataSet: TDataSet);

    { public declarations }
  end; 

var
  fmQueryWindow: TfmQueryWindow;

implementation

{ TfmQueryWindow }

uses main, SQLHistory;

procedure TfmQueryWindow.SQLScript1Exception(Sender: TObject;
  Statement: TStrings; TheException: Exception; var Continue: boolean);
begin
  ShowMessage(TheException.Message);
end;

procedure TfmQueryWindow.tbCloseClick(Sender: TObject);
begin
  Close;
  Parent.Free;
end;

procedure TfmQueryWindow.tbCommitClick(Sender: TObject);
var
  meResult: TMemo;
  SqlQuery: TSQLQuery;
  SqlScript: TSQLScript;
  ATab: TTabSheet;
begin
  RemoveControls;
  SqlTrans.Commit;
  ATab:= CreateResultTab(2, SqlQuery, SqlScript, meResult);
  ATab.ImageIndex:= 4;
  meResult.Lines.Add('Commited');
  meResult.Font.Color:= clGreen;
  if OnCommit <> nil then
    OnCommit(self);
  OnCommit:= nil;
end;

procedure TfmQueryWindow.tbHistoryClick(Sender: TObject);
begin
  fmSQLHistory.Init(RegRec.Title, Self);
  fmSQLHistory.Show;
end;

procedure TfmQueryWindow.tbMenuClick(Sender: TObject);
begin
  pmTab.PopUp;
end;

procedure TfmQueryWindow.tbNewClick(Sender: TObject);
var
  i: Integer;
begin
  for i:= 1 to 1000 do
  begin
    if fmMain.FindQueryWindow(RegRec.Title + ': Query Window # ' + IntToStr(i)) = nil then
    begin
      fmMain.ShowCompleteQueryWindow(fdbIndex, 'Query Window # ' + IntToStr(i), '');
      Break;
    end;
  end;
end;

procedure TfmQueryWindow.tbOpenClick(Sender: TObject);
begin
  OpenDialog1.DefaultExt:= '.sql';
  if OpenDialog1.Execute then
    meQuery.Lines.LoadFromFile(OpenDialog1.FileName);
end;

procedure TfmQueryWindow.tbRollbackClick(Sender: TObject);
var
  meResult: TMemo;
  SqlQuery: TSQLQuery;
  SqlScript: TSQLScript;
  ATab: TTabSheet;
begin
  RemoveControls;
  SqlTrans.Rollback;
  ATab:= CreateResultTab(2, SqlQuery, SqlScript, meResult);
  ATab.ImageIndex:= 5;
  meResult.Lines.Add('Rollback');
  meResult.Font.Color:= $AA6666;
end;

procedure TfmQueryWindow.tbRunClick(Sender: TObject);
begin
  ExecuteQuery(0);
end;

procedure TfmQueryWindow.tbSaveClick(Sender: TObject);
begin
  SaveDialog1.DefaultExt:= '.sql';
  if SaveDialog1.Execute then
    meQuery.Lines.SaveToFile(SaveDialog1.FileName);
end;

procedure TfmQueryWindow.Init(dbIndex: Integer);
begin
  fdbIndex:= dbIndex;
  RegRec:= fmMain.RegisteredDatabases[dbIndex].RegRec;
  ibConnection:= fmMain.RegisteredDatabases[dbIndex].IBConnection;
  with fmMain.RegisteredDatabases[dbIndex] do
  begin
  //  Self.ibConnection.Close;
    Self.ibConnection.DatabaseName:= RegRec.DatabaseName;
    Self.ibConnection.UserName:= RegRec.UserName;
    Self.ibConnection.Password:= RegRec.Password;
    Self.IBConnection.CharSet:= RegRec.Charset;
    Self.ibConnection.Role:= RegRec.Role;
  end;
  SqlTrans:= fmMain.RegisteredDatabases[dbIndex].SQLTrans;

  SynSQLSyn1.TableNames.CommaText:= fmMain.GetTableNames(dbIndex);
end;

(************* Is Selectable (Check statement type Select, Update, Alter, etc) *******************)

function TfmQueryWindow.GetQueryType(AQuery: string): Integer;
var
  List: TStringList;
  i: Integer;
  Line: string;
  StartPos, EndPos: Integer;
begin
  List:= TStringList.Create;
  List.Text:= AQuery;

  Result:= 2; // Default Execute

  for i:= 0 to List.Count - 1 do
  begin
    Line:= List[i];
    // Remove comments
    if Pos('--', Line) > 0 then
      Line:= Copy(Line, 1, Pos('--', Line) - 1);
    if (Pos('/*', Line) > 0) and (Pos('*/', Line) > 0) then
    begin
      StartPos:= (Pos('/*', Line));
      EndPos:= (Pos('*/', Line));
      Delete(Line, StartPos, EndPos - StartPos + 1);
    end;

    if (Pos('select', LowerCase(Trim(Line))) = 1) then
    begin
      Result:= 1; // Selectable
      Break;
    end
    else
    if Pos('setterm', LowerCase(StringReplace(Line, ' ', '', [rfReplaceAll]))) = 1 then
    begin
      Result:= 3;
      Break;
    end;

    if Trim(Line) <> '' then
    begin
      Result:= 2; // Executable
      Break;
    end;

  end;
  List.Free;
end;

function TfmQueryWindow.GetQuery: string;
begin
  Result:= meQuery.SelText;
  if Result = '' then
    Result:= meQuery.Lines.Text;
end;

function TfmQueryWindow.CreateResultTab(QueryType: Byte; var SqlQuery: TSQLQuery; var SQLScript: TSqlScript;
  var meResult: TMemo; AdditionalTitle: string = ''): TTabSheet;
var
  ATab: TTabSheet;
  DBGrid: TDBGrid;
  DataSource: TDataSource;
  StatusBar: TStatusBar;
begin
  ATab:= TTabSheet.Create(nil);
  Result:= ATab;
  ATab.Parent:= PageControl1;
  ATab.Caption:= 'Result # ' + IntToStr(PageControl1.PageCount) + AdditionalTitle;
  if QueryType = 1 then // Select, need record set result
  begin
    // Query
    SqlQuery:= TSQLQuery.Create(nil);
    SqlQuery.DataBase:= ibConnection;
    SqlQuery.Transaction:= SqlTrans;
    SqlQuery.AfterScroll:= @QueryAfterScroll;
    AddResultControl(ATab, SqlQuery);


    // Status Bar
    StatusBar:= TStatusBar.Create(nil);
    StatusBar.Parent:= ATab;
    AddResultControl(ATab, StatusBar);

    // Datasource
    DataSource:= TDataSource.Create(nil);
    DataSource.DataSet:= SqlQuery;
    AddResultControl(ATab, DataSource);

    // Query result Grid
    DBGrid:= TDBGrid.Create(nil);
    DBGrid.Parent:= ATab;
    DBGrid.DataSource:= DataSource;
    DBGrid.Align:= alClient;
    DBGrid.OnDblClick:= @DBGrid1DblClick;
    DBGrid.ReadOnly:= False;
    DBGrid.AutoEdit:= False;
//    DBGrid.FixedColor:= $00DDDACF;   // delete
    DBGrid.PopupMenu:= pmGrid;
    DBGrid.TitleStyle:=tsNative; // add
    DBGrid.Options:= DBGrid.Options + [dgAutoSizeColumns,dgHeaderHotTracking, dgHeaderPushedLook];  // edit
    DBGrid.OnTitleClick:=@DBGridTitleClick;  //  add
    AddResultControl(ATab, DBGrid);
  end
  else
  if QueryType in [2, 3] then
  begin
    meResult:= TMemo.Create(nil);
    meResult.Parent:= ATab;
    meResult.ReadOnly:= True;
    meResult.Align:= alClient;
    AddResultControl(ATab, meResult);

    if QueryType = 2 then
    begin
      SqlQuery:= TSQLQuery.Create(nil);
      SqlQuery.DataBase:= ibConnection;
      SqlQuery.Transaction:= SqlTrans;
      AddResultControl(ATab, SqlQuery);
    end;


    if QueryType = 3 then // Script
    begin
      SQLScript:= TSQLScript.Create(nil);
      SQLScript.DataBase:= ibConnection;
      SQLScript.Transaction:= SqlTrans;
      AddResultControl(ATab, SQLScript);
    end;
  end;
  AddResultControl(nil, ATab);
end;

(***************  Execute Query   ******************)

procedure TfmQueryWindow.ExecuteQuery(QueryType: Integer);
var
  Query: string;
  StartTime: TDateTime;
  QueryPart: string;
  Cnt: Integer;
  SqlQuery: TSQLQuery;
  SqlScript: TSQLScript;
  meResult: TMemo;
  ATab: TTabSheet;
  SqlType: string;
  List: TStringList;
  EndLine: Integer;
  StartLine: Integer;
  Command: string;
  IsDDL: Boolean;
  Affected: Integer;
begin
  try
    RemoveControls;
    Query:= Trim(GetQuery);

    if QueryType = 0 then // Auto
      QueryType:= GetQueryType(Query);

    Cnt:= 0;

    // Script
    if (QueryType = 3) then
    begin
      ExecuteScript(Query);
      SqlType:= GetSQLType(Query, Command);
      fmMain.AddToSQLHistory(RegRec.Title, SqlType, Query);
    end
    else       // normal statement / Multi statements
    begin
      List:= TStringList.Create;
      List.Text:= Query;
      StartLine:= 0;
      repeat
        Inc(Cnt);
        if not GetSQLSegment(List, Startline, QueryType, EndLine, QueryPart, IsDDL) then
          Break;

        if EndLine < StartLine then
          StartLine:= StartLine + 1
        else
          StartLine:= EndLine + 1;


        if Trim(QueryPart) <> '' then   // Select
        if QueryType = 1 then
        begin
          try
            ATab:= CreateResultTab(1, SqlQuery, SqlScript, meResult);
            ATab.ImageIndex:= 0;
            SQLQuery.SQL.Text:= QueryPart;
            SQLQuery.Open;
            fmMain.AddToSQLHistory(RegRec.Title, 'SELECT', QueryPart);

          except
          on e: exception do
          begin
            ATab.Free;
            SetLength(ResultControls, High(ResultControls));
            setlength(ParentResultControls, High(ParentResultControls));
            ATab:= CreateResultTab(2, SqlQuery, SqlScript, meResult);
            PageControl1.ActivePage:= ATab;

            meResult.Text:= e.message;
            meResult.Lines.Add(QueryPart);
            meResult.Font.Color:= clRed;
            ATab.Font.Color:= clRed;
            ATab.ImageIndex:= 3;
          end;
          end;
        end
        else  // Execute
        if QueryType = 2 then
        begin
          ATab:= CreateResultTab(2, SqlQuery, SqlScript, meResult);
          ATab.ImageIndex:= 1;
          SqlType:= GetSQLType(QueryPart, Command);
          StartTime:= Now;
          Affected:= 0;
          try
            if IsDDL then
              ibConnection.ExecuteDirect(QueryPart)
            else
            begin   // DML
              SqlQuery.Close;
              SqlQuery.SQL.Text:= QueryPart;
              SqlQuery.ExecSQL;
              Affected:= sqlQuery.RowsAffected;
            end;

            fmMain.AddToSQLHistory(RegRec.Title, SQLType, QueryPart);
            meResult.Visible:= True;
            meResult.Clear;
            meResult.Lines.Add('statement #' + IntToStr(cnt));
            if IsDDL then
              meResult.Lines.Add(FormatDateTime('hh:nn:ss.z', Now) + ' - DDL Executed. Takes (H:M:S.MS) ' +
                FormatDateTime('HH:nn:ss.z', Now - StartTime))
            else // DML
            begin
              meResult.Lines.Add(FormatDateTime('hh:nn:ss.z', Now) + ' - DML Executed. Takes (H:M:S.MS) ' +
                FormatDateTime('HH:nn:ss.z', Now - StartTime));
              meResult.Lines.Add('Rows affected: ' + Format('%3.0n', [Affected / 1]));

            end;

          except
          on e: exception do
          begin
            ATab:= CreateResultTab(2, SqlQuery, SqlScript, meResult);
            PageControl1.ActivePage:= ATab;
            meResult.Text:= e.message;
            meResult.Lines.Add(QueryPart);
            meResult.Font.Color:= clRed;
            ATab.Font.Color:= clRed;
            ATab.ImageIndex:= 3;
          end;
          end

        end
        else  // Script
        begin
          if ExecuteScript(QueryPart) then
          begin
            SqlType:= GetSQLType(QueryPart, Command);
            fmMain.AddToSQLHistory(RegRec.Title, SqlType, Query);
          end;
        end;

        Application.ProcessMessages;
      until StartLine >= List.Count;
      List.Free;
    end;

  except
  on e: exception do
  begin
    ATab:= CreateResultTab(2, SqlQuery, SqlScript, meResult);
    ATab.ImageIndex:= 2;
    PageControl1.ActivePage:= ATab;

    meResult.Text:= e.message;
    meResult.Lines.Add(QueryPart);
    meResult.Font.Color:= clRed;
  end;
  end;

end;

function TfmQueryWindow.ExecuteScript(Script: string): Boolean;
var
  StartTime: TDateTime;
  SqlQuery: TSQLQuery;
  SqlScript: TSQLScript;
  meResult: TMemo;
  ATab: TTabSheet;
begin
  try
    StartTime:= Now;
    ATab:= CreateResultTab(3, SqlQuery, SqlScript, meResult);
    ATab.ImageIndex:= 2;
    SQLScript.Script.Text:= Script;
    SQLScript.ExecuteScript;
    Result:= True;
    meResult.Lines.Text:= FormatDateTime('hh:nn:ss.z', Now) + ' - Script Executed. It takes (H:M:S.MS) ' +
      FormatDateTime('HH:nn:ss.z', Now - StartTime);

  except
  on e: exception do
  begin
    Result:= False;
    ATab:= CreateResultTab(2, SqlQuery, SqlScript, meResult);
    PageControl1.ActivePage:= ATab;
    meResult.Text:= e.Message;
    meResult.Lines.Add(Script);
    meResult.Font.Color:= clRed;
    ATab.Font.Color:= clRed;
    ATab.ImageIndex:= 3;
  end;

  end;
end;

procedure TfmQueryWindow.AddResultControl(ParentControl: TObject; AControl: TObject);
begin
  SetLength(ResultControls, Length(ResultControls) + 1);
  SetLength(ParentResultControls, Length(ParentResultControls) + 1);
  ResultControls[High(ParentResultControls)]:= AControl;
  ParentResultControls[High(ParentResultControls)]:= ParentControl;
end;

procedure TfmQueryWindow.RemoveControls;
var
  i: Integer;
  CannotFree: Boolean;
begin
  for i:= High(ResultControls) downto  0 do
  begin
    if ResultControls[i] is TSQLQuery then
      (ResultControls[i] as TSQLQuery).Close;

    //    CannotFree:= (ResultControls[i] is TStatusBar) or (ResultControls[i] is TSQLQuery);

    //  if not CannotFree then
    ResultControls[i].Free;
  end;

  SetLength(ResultControls, 0);
  SetLength(ParentResultControls, 0);
end;

function TfmQueryWindow.FindSqlQuery: TSqlQuery;
var
  i: Integer;
begin
  Result:= nil;
  if PageControl1.PageCount > 0 then
  begin
    with PageControl1.ActivePage do
      for i:= 0 to ControlCount - 1 do
        if Controls[i] is TDBGrid then
        begin
          Result:= TSqlQuery((Controls[i] as TDBGrid).DataSource.DataSet);
          Break;
        end;
  end;

end;

function TfmQueryWindow.GetSQLType(Query: string; var Command: string): string;
begin
  Query:= Trim(Query);
  if (Query <> '') and (Pos(' ', Query) > 0) then
  begin
    Command:= Copy(Query, 1, Pos(' ', Query) - 1);
    Command:= LowerCase(Command);
    if (Command = 'alter') or (Command = 'create') or (Command = 'drop') or (Command = 'grant') or
       (Command = 'revoke') then
      Result:= 'DDL'
    else
      Result:= 'DML';
  end;
end;

function TfmQueryWindow.GetSQLSegment(QueryList: TStringList; StartLine: Integer; var QueryType, EndLine: Integer;
  var SQLSegment: string; var IsDDL: Boolean): Boolean;
var
  i: Integer;
  RealStartLine: Integer;
  SecondRealStart: Integer;
  MultiComment: Boolean;
  Comment: Boolean;
  BeginExist: Boolean;
begin
  // Get start
  MultiComment:= False;
  SQLSegment:= '';
  RealStartLine:= StartLine;
  SecondRealStart:= -1;
  Result:= False;

  // Remove comment
  for i:= StartLine to QueryList.Count - 1 do
  begin
    if Pos('/*', Trim(QueryList[i])) = 1 then
    begin
      MultiComment:= True;
      Comment:= False;
    end;

    if not MultiComment then
      Comment:= Pos('--', Trim(QueryList[i])) = 1;

    if (Trim(QueryList[i]) <> '') and (not Comment) and (not MultiComment) then
    begin
      RealStartLine:= i;
      Break;
    end;

    if MultiComment and (Pos('*/', QueryList[i]) > 0) then // End of multi-line comment
    begin
      QueryList[i]:= Trim(Copy(QueryList[i], Pos('*/', QueryList[i]) + 2, Length(QueryList[i])));
      RealStartLine:= i;
      MultiComment:= False;
      Comment:= False;
      if (i = QueryList.Count - 1) or
         ((Trim(QueryList[i + 1]) <> '') and  (Pos('/*', Trim(QueryList[i + 1])) <> 1) and
         (Pos('--', Trim(QueryList[i + 1])) <> 1)) then
          Break;
    end;

  end;

  SecondRealStart:= RealStartLine;
  // remove empty lines
  for i:= RealStartLine to QueryList.Count - 1 do
  begin
     if Trim(QueryList[i]) <> '' then
     begin
       SecondRealStart:= i;
       Break;
     end;
  end;


  IsDDL:= False;
  if SecondRealStart < QueryList.Count then
  begin
    SQLSegment:= SQLSegment + QueryList[SecondRealStart];

    if (Pos('select', LowerCase(Trim(SQLSegment))) = 1) then
      QueryType:= 1 // Selectable
    else
    if Pos('setterm', LowerCase(StringReplace(SQLSegment, ' ', '', [rfReplaceAll]))) = 1 then
      QueryType:= 3 // Script
    else
    begin
      QueryType:= 2; // Executable
      IsDDL:= (Pos('create', lowerCase(Trim(SQLSegment))) = 1) or (Pos('alter', lowerCase(Trim(SQLSegment))) = 1) or
         (Pos('modify', lowerCase(Trim(SQLSegment))) = 1);
    end;
  end;

  // Concatinate
  SQLSegment:= '';
  BeginExist:= False;
    for i:= SecondRealStart to QueryList.Count - 1 do
    begin
      if Pos('begin', Trim(LowerCase(QueryList[i]))) > 0 then
        BeginExist:= True;

      SQLSegment:= SQLSegment + QueryList[i] + #10;

      if (QueryType in [1, 2]) and
        (((Pos(';', QueryList[i]) > 0) and (Not BeginExist)) or
        ((Pos('end', LowerCase(Trim(QueryList[i]))) = 1) and BeginExist)
        or (i = QueryList.Count - 1)) then
      begin
        Result:= True;
        if (not BeginExist) and (Pos(';', QueryList[i]) > 0) then
        begin
          QueryList[i]:= Trim(Copy(QueryList[i],  Pos(';', QueryList[i]) + 1, Length(QueryList[i])));
          if QueryList[i] = '' then
           EndLine:= i
          else
          begin
            EndLine:= i - 1;
            SQLSegment:= Trim(Copy(SQLSegment, 1, Pos(';',  SQLSegment)));
          end;

        end
        else
          EndLine:= i;
        Break;
      end
      else
      if (QueryType = 3) and (i > SecondRealStart) and (Pos('setterm', LowerCase(StringReplace(QueryList[i],
        ' ', '', [rfReplaceAll]))) > 0) then
      begin
        Result:= True;
        EndLine:= i;
        Break;
      end;
    end;

end;


procedure TfmQueryWindow.bbRunClick(Sender: TObject);
begin
  ExecuteQuery(0);
end;



procedure TfmQueryWindow.DBGrid1DblClick(Sender: TObject);
begin
  if (Sender as TDBGrid).SelectedField.DataType in [ftBlob, ftMemo] then
    ShowMessage((Sender as TDBGrid).SelectedField.AsString);
end;

procedure TfmQueryWindow.DBGridTitleClick(column: TColumn);
var   SqlQuery: TSQLQuery;
//    indexoption : TIndexOptions;
begin
SqlQuery:= FindSqlQuery;
if  SqlQuery <> Nil then
 if SqlQuery.IndexFieldNames = Column.Field.FieldName then
  SqlQuery.IndexFieldNames := Column.Field.FieldName //+ 'DESC'
//   indexoption :=[ixDescending];
//   SqlQuery.AddIndex('',Column.Field.FieldName,indexoption,'');
 else
  SqlQuery.IndexFieldNames := Column.Field.FieldName

end;

procedure TfmQueryWindow.FindDialog1Find(Sender: TObject);
begin
  fOptions:= [];

  if frMatchCase in FindDialog1.Options then
    fOptions:= fOptions + [ssoMatchCase];

  if frWholeWord in FindDialog1.Options then
    fOptions:= fOptions + [ssoWholeWord];

  if not (frDown in FindDialog1.Options) then
    fOptions:= fOptions + [ssoBackwards];

   if frEntireScope in FindDialog1.Options then
     fOptions:= fOptions + [ssoEntireScope];

  meQuery.SearchReplace(FindDialog1.FindText, '', fOptions);
end;


procedure TfmQueryWindow.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  RemoveControls;
  if SqlTrans.Active then
  begin
    SqlTrans.Commit;
    if OnCommit <> nil then
      OnCommit(self);
    OnCommit:= nil;
  end;
  IBConnection.Close;
  CloseAction:= caFree;
end;

procedure TfmQueryWindow.FormShow(Sender: TObject);
begin
  meQuery.SetFocus;
end;

procedure TfmQueryWindow.lmCloseTabClick(Sender: TObject);
begin
  if MessageDlg('Do you want to close this query window?', mtCustom, [mbNo,mbyes], 0) = mryes then
  begin
    Close;
    Parent.Free;
  end;
end;


procedure TfmQueryWindow.lmCommaDelemitedClick(Sender: TObject);
var
  i: Integer;
  F: TextFile;
  SqlQuery: TSQLQuery;
begin
  SaveDialog1.DefaultExt:= '.txt';
  SqlQuery:= FindSqlQuery;
  if SqlQuery = nil then
  begin
    ShowMessage('There is no recordset in result');
    Exit;
  end;
  if (not SQLQuery.Active) or (SQLQuery.RecordCount = 0) then
    MessageDlg('No data', mtError, [mbOk], 0)
  else
  if SaveDialog1.Execute then
  begin
    SQLQuery.DisableControls;
    SQLQuery.First;
    AssignFile(F, SaveDialog1.FileName);
    Rewrite(F);
    for i:= 0 to SQLQuery.FieldCount - 1 do
    begin
      Write(F, '"', SQLQuery.Fields[i].FieldName, '"');
      if i = SQLQuery.FieldCount - 1 then
        Writeln(F)
      else
        Write(F, ', ');
    end;

    while not SQLQuery.EOF do
    begin
      for i:= 0 to SQLQuery.FieldCount - 1 do
      begin
        Write(F, '"', SQLQuery.Fields[i].AsString, '"');
        if i = SQLQuery.FieldCount - 1 then
          Writeln(F)
        else
          Write(F, ', ');
      end;
      SQLQuery.Next;
    end;
    CloseFile(F);
    SQLQuery.EnableControls;
  end;

end;

procedure TfmQueryWindow.lmCopyCellClick(Sender: TObject);
begin
  Clipboard.AsText:= TdbGrid(pmGrid.PopupComponent).SelectedField.AsString;
end;

procedure TfmQueryWindow.lmCopyClick(Sender: TObject);
begin
  meQuery.CopyToClipboard;
end;

procedure TfmQueryWindow.lmCutClick(Sender: TObject);
begin
  meQuery.CutToClipboard;
end;

procedure TfmQueryWindow.lmExportAsCommaClick(Sender: TObject);
begin
  lmCommaDelemitedClick(nil);
end;

procedure TfmQueryWindow.lmExportAsHTMLClick(Sender: TObject);
begin
  lmHTMLClick(nil);
end;


procedure TfmQueryWindow.lmHTMLClick(Sender: TObject);
var
  i: Integer;
  F: TextFile;
  SqlQuery: TSQLQuery;
begin
  SaveDialog1.DefaultExt:= '.htm';
  SqlQuery:= FindSqlQuery;
  if SqlQuery = nil then
  begin
    ShowMessage('There is no record set in result');
  end
  else
  if (not SQLQuery.Active) or (SQLQuery.RecordCount = 0) then
    MessageDlg('No data', mtError, [mbOk], 0)
  else
  if SaveDialog1.Execute then
  begin
    SQLQuery.DisableControls;
    SQLQuery.First;
    AssignFile(F, SaveDialog1.FileName);
    Rewrite(F);
    Writeln(F, '<table border=0><tr bgcolor="DDDDDD">');
    for i:= 0 to SQLQuery.FieldCount - 1 do
    begin
      Write(F, '<th>', SQLQuery.Fields[i].FieldName, '</th>');
      if i = SQLQuery.FieldCount - 1 then
        Writeln(F, '</tr>');
    end;

    while not SQLQuery.EOF do
    begin
      Write(f, '<tr bgcolor="');
      if SQLQuery.RecNo mod 2 = 0 then
        Write(F, '#EEDDFF">')
      else
        Write(F, '#FFFFFF">');

      for i:= 0 to SQLQuery.FieldCount - 1 do
      begin
        Write(F, '<td>', SQLQuery.Fields[i].AsString, '</td>');
        if i = SQLQuery.FieldCount - 1 then
          Writeln(F, '</tr>');
      end;
      SQLQuery.Next;
    end;
    Writeln(F, '</table>');
    CloseFile(F);
    SQLQuery.EnableControls;
  end;

end;



procedure TfmQueryWindow.lmPasteClick(Sender: TObject);
begin
  meQuery.PasteFromClipboard;
end;

procedure TfmQueryWindow.lmRedoClick(Sender: TObject);
begin
  meQuery.Redo;
end;

procedure TfmQueryWindow.lmRunClick(Sender: TObject);
begin
  ExecuteQuery(0);
end;

procedure TfmQueryWindow.lmRunExecClick(Sender: TObject);
begin
  ExecuteQuery(2);
end;

procedure TfmQueryWindow.lmRunScriptClick(Sender: TObject);
begin
  ExecuteQuery(3);
end;

procedure TfmQueryWindow.lmRunSelectClick(Sender: TObject);
begin
  ExecuteQuery(1);
end;

procedure TfmQueryWindow.lmSelectAllClick(Sender: TObject);
begin
  meQuery.SelectAll;
end;


procedure TfmQueryWindow.lmUndoClick(Sender: TObject);
begin
  meQuery.Undo;
end;


procedure TfmQueryWindow.lmFindClick(Sender: TObject);
begin
  FindDialog1.Execute;
end;

procedure TfmQueryWindow.lmFindAgainClick(Sender: TObject);
begin
  meQuery.SearchReplace(FindDialog1.FindText, '', fOptions);
end;


procedure TfmQueryWindow.QueryAfterScroll(DataSet: TDataSet);
var
  TabSheet: TTabSheet;
  i: Integer;
begin
  TabSheet:= nil;
  // Get DataSet's TTabsheet
  for i:= 0 to High(ResultControls) do
  if DataSet = ResultControls[i] then
  begin
    TabSheet:= ParentResultControls[i] as TTabSheet;
    Break;
  end;

  if TabSheet <> nil then
  for i:= 0 to High(ResultControls) do
    if  (ParentResultControls[i] <> nil) and ((ParentResultControls[i] as TTabSheet) = TabSheet)
      and (ResultControls[i] is TStatusBar) then
      begin
      (ResultControls[i] as TStatusBar).SimpleText:= IntToStr(DataSet.RecordCount) +
        ' records fetched. At record # ' + IntToStr(DataSet.RecNo);
      break;
  end;

end;

initialization
  {$I querywindow.lrs}

end.
