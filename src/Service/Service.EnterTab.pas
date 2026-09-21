unit Service.EnterTab;

interface

uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  Winapi.Messages,
  Vcl.Forms,
  Vcl.Controls,
  Vcl.StdCtrls;

type
  TEnterComoTab = class(TComponent)
  private
    FFormulario: TCustomForm;
    FEventoAnterior: TKeyPressEvent;
    procedure AoPressionarTecla(Sender: TObject; var Key: Char);
  public

    class procedure Instalar(AFormulario: TCustomForm);

    class procedure Tratar(AFormulario: TCustomForm; var Key: Char);

    class function ControleConsomeEnter(AControle: TWinControl): Boolean;
  end;

implementation

type
  TMemoCracker  = class(TCustomMemo);
  TComboCracker = class(TCustomComboBox);

class function TEnterComoTab.ControleConsomeEnter(
  AControle: TWinControl): Boolean;
var
  LNomeClasse: string;
begin
  Result := False;
  if not Assigned(AControle) then
    Exit;

  LNomeClasse := UpperCase(AControle.ClassName);

  if (AControle is TButtonControl) or
     (Pos('BUTTON', LNomeClasse) > 0) then
    Exit(True);

  if AControle is TCustomMemo then
    Exit(TMemoCracker(AControle).WantReturns);

  if Pos('MEMO', LNomeClasse) > 0 then
    Exit(True);

  if AControle is TCustomComboBox then
    Exit(TComboCracker(AControle).DroppedDown);

  if (Pos('COMBO', LNomeClasse) > 0) or (Pos('LOOKUP', LNomeClasse) > 0) then
  begin
    Result := AControle.Perform(CB_GETDROPPEDSTATE, 0, 0) <> 0;
    Exit;
  end;
end;

class procedure TEnterComoTab.Tratar(AFormulario: TCustomForm; var Key: Char);
begin
  if Key <> #13 then
    Exit;

  if not Assigned(AFormulario) then
    Exit;

  if ControleConsomeEnter(AFormulario.ActiveControl) then
    Exit;

  Key := #0;

  AFormulario.Perform(WM_NEXTDLGCTL, 0, 0);
end;

class procedure TEnterComoTab.Instalar(AFormulario: TCustomForm);
var
  LInstancia: TEnterComoTab;
begin
  if not Assigned(AFormulario) then
    Exit;

  LInstancia := TEnterComoTab.Create(AFormulario);
  LInstancia.FFormulario := AFormulario;

  AFormulario.KeyPreview := True;

  if AFormulario is TForm then
  begin
    LInstancia.FEventoAnterior := TForm(AFormulario).OnKeyPress;
    TForm(AFormulario).OnKeyPress := LInstancia.AoPressionarTecla;
  end;
end;

procedure TEnterComoTab.AoPressionarTecla(Sender: TObject; var Key: Char);
begin
  Tratar(FFormulario, Key);

  if (Key <> #0) and Assigned(FEventoAnterior) then
    FEventoAnterior(Sender, Key);
end;

end.
