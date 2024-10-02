unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  FileCtrl, ComCtrls, FileUtil, SynHighlighterAny, SynEdit, DefaultTranslator,
  AsyncProcess, ExtCtrls;

type

  { TMainForm }

  TMainForm = class(TForm)
    CertBox: TFileListBox;
    DirBox: TComboBox;
    DeleteBtn: TSpeedButton;
    EditBtn: TSpeedButton;
    ImageList1: TImageList;
    LoadBtn: TSpeedButton;
    OpenDialog1: TOpenDialog;
    Panel1: TPanel;
    Panel2: TPanel;
    SaveBtn: TSpeedButton;
    SaveDialog1: TSaveDialog;
    SelectAll: TSpeedButton;
    ShowCert: TAsyncProcess;
    Splitter1: TSplitter;
    StaticText1: TStaticText;
    SynAnySyn1: TSynAnySyn;
    SynEdit1: TSynEdit;
    procedure CertBoxChange(Sender: TObject);
    procedure CertBoxClick(Sender: TObject);
    procedure CertBoxDblClick(Sender: TObject);
    procedure CertBoxDrawItem(Control: TWinControl; Index: integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure CertBoxKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure CertBoxKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure DeleteBtnClick(Sender: TObject);
    procedure DirBoxCloseUp(Sender: TObject);
    procedure EditBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure LoadBtnClick(Sender: TObject);
    procedure SaveBtnClick(Sender: TObject);
    procedure SelectAllClick(Sender: TObject);
    procedure ShowCertReadData(Sender: TObject);
    procedure StartInit;
    procedure ShowCertExec;

  private

  public

  end;

  //Ресурсы перевода
resourcestring
  SDeleteCert = 'Delete selected certificates?';
  SRenameCert = 'Rename';
  SNewName = 'Eenter a new name';
  SFileExists = 'The file already exists!';
  SDirNotFound = 'not found! Terminate!';

var
  MainForm: TMainForm;
  KeyFlag: boolean; //Флаг нажатия клавиш в FileListBox

implementation

uses commandtrd;

  {$R *.lfm}

  { TMainForm }

//Отображение сертификата
procedure TMainForm.ShowCertExec;
begin
  //Если кнопка отжата и выбран 1 элемент
  if (CertBox.SelCount = 1) and (KeyFlag = False) then
    with ShowCert do
    begin
      Parameters.Clear;
      Parameters.Add('-c');
      Parameters.Add('openssl x509 -in "' + CertBox.FileName + '" -noout -text');
      Execute;
    end;
end;

//Создать /etc/ipsec.d/cacerts (если нет), chmod -R 755 и FileListBox Update
procedure TMainForm.StartInit;
var
  FCommandThread: TThread;
begin
  FCommandThread := StartCommand.Create(False);
  FCommandThread.Priority := tpNormal;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  MainForm.Caption := Application.Title;
  StartInit;
end;

//Загрузить/Сохранить как...
procedure TMainForm.LoadBtnClick(Sender: TObject);
begin
  SaveDialog1.InitialDir := DirBox.Text;

  if OpenDialog1.Execute then
  begin
    SaveDialog1.FileName := ExtractFileName(OpenDialog1.FileName);

    if SaveDialog1.Execute then
      CopyFile(OpenDialog1.FileName, SaveDialog1.FileName, [cffOverwriteFile]);
    StartInit;
  end;
end;

//Save as...
procedure TMainForm.SaveBtnClick(Sender: TObject);
begin
  if CertBox.SelCount <> 0 then
  begin
    SaveDialog1.FileName:=CertBox.FileName;

    if SaveDialog1.Execute then
      CopyFile(CertBox.FileName, SaveDialog1.FileName, [cffOverwriteFile]);
    end;
end;

//SelectAll
procedure TMainForm.SelectAllClick(Sender: TObject);
begin
  CertBox.SelectAll;
end;

//Отображение сертификата
procedure TMainForm.ShowCertReadData(Sender: TObject);
begin
  SynEdit1.Lines.LoadFromStream(ShowCert.Output);
end;

//Иконки списка
procedure TMainForm.CertBoxDrawItem(Control: TWinControl; Index: integer;
  ARect: TRect; State: TOwnerDrawState);
var
  BitMap: TBitMap;
begin
  try
    BitMap := TBitMap.Create;
    with CertBox do
    begin
      Canvas.FillRect(aRect);

      //Название (текст по центру-вертикали)
      Canvas.TextOut(aRect.Left + 30, aRect.Top + ItemHeight div 2 -
        Canvas.TextHeight('A') div 2 + 1, Items[Index]);

      //Иконка
      ImageList1.GetBitMap(0, BitMap);

      Canvas.Draw(aRect.Left + 2, aRect.Top + (ItemHeight - 24) div 2 + 2, BitMap);
    end;
  finally
    BitMap.Free;
  end;
end;

//Клавиша нажата
procedure TMainForm.CertBoxKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  KeyFlag := True;
end;

//Клавиша отпущена
procedure TMainForm.CertBoxKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  KeyFlag := False;
  ShowCertExec;
end;

//Редактировать
procedure TMainForm.CertBoxDblClick(Sender: TObject);
begin
  EditBtn.Click;
end;

//Просмотр сертификата
procedure TMainForm.CertBoxChange(Sender: TObject);
begin
  ShowCertExec;
end;

//Клик мышью
procedure TMainForm.CertBoxClick(Sender: TObject);
begin
  KeyFlag := False;
end;

//Удаление сертификатов
procedure TMainForm.DeleteBtnClick(Sender: TObject);
var
  i: integer;
begin
  if CertBox.SelCount <> 0 then
    if MessageDlg(SDeleteCert, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      //Удаление записей
      for i := -1 + CertBox.Items.Count downto 0 do
        if CertBox.Selected[i] then
          DeleteFile(DirBox.Text + '/' + CertBox.Items[i]);

      StartInit;
    end;
end;

//Изменить/Обновить директорию
procedure TMainForm.DirBoxCloseUp(Sender: TObject);
begin
  KeyFlag := False;
  StartInit;
end;

//Rename
procedure TMainForm.EditBtnClick(Sender: TObject);
var
  cname: string;
begin
  if CertBox.SelCount <> 0 then
  begin
    //Имя
    cname := CertBox.Items[CertBox.ItemIndex];

    repeat
      if not InputQuery(SRenameCert, SNewName, cname) then
        Exit;
    until cname <> '';

    if FileExists(DirBox.Text + '/' + cname) then
      MessageDlg(SFileExists, mtWarning, [mbOK], 0)
    else
    begin
      RenameFile(CertBox.FileName, DirBox.Text + '/' + cname);
      StartInit;
    end;
  end;
end;

end.
