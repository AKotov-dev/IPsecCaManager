unit commandtrd;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Process, Dialogs;

type
  StartCommand = class(TThread)
  private

    { Private declarations }
  protected
 { var
    S: TStringList;
  }
    procedure Execute; override;

    //  procedure ShowSDLog;
    procedure StopProgress;
    //  procedure StartProgress;

  end;

implementation

uses unit1;

  { TRD }

//Вывод лога и прогресса
procedure StartCommand.Execute;
var
  ExProcess: TProcess;
begin
  try
    //Synchronize(@StartProgress);

 //   S := TStringList.Create;

    FreeOnTerminate := True; //Уничтожить по завершении

    //Рабочий процесс
    ExProcess := TProcess.Create(nil);

    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add(
      'mkdir -p /etc/ipsec.d/{cacerts,certs,private}; chmod -R 755 /etc/ipsec.d');
    //; systemctl restart ipsec

    ExProcess.Options := [poWaitOnExit]; //poWaitOnExit, UsePipes, poStderrToOutPut

    ExProcess.Execute;

   { while ExProcess.Running do
    begin
      S.LoadFromStream(ExProcess.Output);

      //Выводим лог
      S.Text := Trim(S.Text);
    end; }

  finally
    Synchronize(@StopProgress);
 //   S.Free;
    ExProcess.Free;
    Terminate;
  end;
end;

{ БЛОК ОТОБРАЖЕНИЯ ЛОГА }

//Стоп
procedure StartCommand.StopProgress;
begin
  with MainForm do
  begin
    CertBox.Directory := '';
    if DirectoryExists(DirBox.Text) then
      CertBox.Directory := DirBox.Text
    else
    begin
      MessageDlg(DirBox.Text + ' ' + SDirNotFound, mtError, [mbOK], 0);
      Application.Terminate;
    end;

    if CertBox.Count <> 0 then
      CertBox.ItemIndex := 0
    else
      SynEdit1.Clear;

    CertBox.SetFocus;
  end;
end;

end.
