unit View.Cliente;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Variants,
  System.Generics.Collections,
  Vcl.Forms,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  cxGraphics,
  cxControls,
  cxLookAndFeels,
  cxLookAndFeelPainters,
  cxStyles,
  cxEdit,
  cxContainer,
  cxTextEdit,
  cxMaskEdit,
  cxDropDownEdit,
  cxCalendar,
  cxLabel,
  cxButtons,
  Model.Entity.Cliente,
  Model.Entity.Cidade,
  Model.Entity.Estado,
  Controller.Cliente, Vcl.ComCtrls, dxCore, cxDateUtils, Vcl.Menus;

type
  TfrmCliente = class(TForm)
    pnlCampos: TPanel;
    lblId: TcxLabel;
    edtId: TcxTextEdit;
    lblNome: TcxLabel;
    edtNome: TcxTextEdit;
    lblCpfCnpj: TcxLabel;
    edtCpfCnpj: TcxTextEdit;
    lblNascimento: TcxLabel;
    edtNascimento: TcxDateEdit;
    lblCep: TcxLabel;
    edtCep: TcxMaskEdit;
    lblDicaCep: TcxLabel;
    lblEndereco: TcxLabel;
    edtEndereco: TcxTextEdit;
    lblNumero: TcxLabel;
    edtNumero: TcxTextEdit;
    lblComplemento: TcxLabel;
    edtComplemento: TcxTextEdit;
    lblBairro: TcxLabel;
    edtBairro: TcxTextEdit;
    lblEstado: TcxLabel;
    cbEstado: TcxComboBox;
    lblCidade: TcxLabel;
    cbCidade: TcxComboBox;
    pnlAcoes: TPanel;
    btnSalvar: TcxButton;
    btnCancelar: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure edtCepPropertiesChange(Sender: TObject);
    procedure edtCepExit(Sender: TObject);
    procedure edtCpfCnpjExit(Sender: TObject);
    procedure cbEstadoPropertiesChange(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
  private
    FController: TClienteController;
    FCliente: TCliente;

    FEstados: TObjectList<TEstado>;
    FCidades: TObjectList<TCidade>;

    FCepConsultado: string;

    procedure CarregarCombos;
    procedure FiltrarCidadesPorEstado(AEstadoId: Integer);

    function EstadoSelecionado: Integer;
    function CidadeSelecionada: Integer;
    procedure SelecionarCidade(ACidadeId: Integer);

    procedure EntidadeParaTela;
    procedure TelaParaEntidade;

    function CepDigitado: string;
    procedure ConsultarCep;
  public
    procedure Carregar(AId: Integer);
  end;

implementation

uses
  Service.EnterTab,
  Service.Documento,
  Service.ViaCep;

{$R *.dfm}

procedure TfrmCliente.FormCreate(Sender: TObject);
begin
  FController := TClienteController.Create;
  FCliente := TCliente.Create;
  FCepConsultado := '';

  CarregarCombos;

  TEnterComoTab.Instalar(Self);
end;

procedure TfrmCliente.FormDestroy(Sender: TObject);
begin
  cbCidade.Properties.Items.Clear;
  cbEstado.Properties.Items.Clear;

  FreeAndNil(FCidades);
  FreeAndNil(FEstados);
  FreeAndNil(FCliente);
  FreeAndNil(FController);
end;

procedure TfrmCliente.CarregarCombos;
var
  I: Integer;
begin
  FEstados := FController.ListarEstados;
  FCidades := FController.ListarCidades;

  cbEstado.Properties.Items.Clear;
  cbEstado.Properties.Items.AddObject('(todos os estados)', nil);
  for I := 0 to FEstados.Count - 1 do
    cbEstado.Properties.Items.AddObject(FEstados[I].Descricao, FEstados[I]);
  cbEstado.ItemIndex := 0;

  FiltrarCidadesPorEstado(0);
end;

procedure TfrmCliente.FiltrarCidadesPorEstado(AEstadoId: Integer);
var
  I: Integer;
  LCidade: TCidade;
begin
  cbCidade.Properties.Items.BeginUpdate;
  try
    cbCidade.Properties.Items.Clear;
    cbCidade.Properties.Items.AddObject('(selecione a cidade)', nil);

    for I := 0 to FCidades.Count - 1 do
    begin
      LCidade := FCidades[I];
      if (AEstadoId = 0) or (LCidade.EstadoId = AEstadoId) then
        cbCidade.Properties.Items.AddObject(LCidade.Descricao, LCidade);
    end;
  finally
    cbCidade.Properties.Items.EndUpdate;
  end;

  cbCidade.ItemIndex := 0;
end;

function TfrmCliente.EstadoSelecionado: Integer;
var
  LObjeto: TObject;
begin
  Result := 0;
  if cbEstado.ItemIndex < 0 then
    Exit;

  LObjeto := cbEstado.Properties.Items.Objects[cbEstado.ItemIndex];
  if LObjeto is TEstado then
    Result := TEstado(LObjeto).Id;
end;

function TfrmCliente.CidadeSelecionada: Integer;
var
  LObjeto: TObject;
begin
  Result := 0;
  if cbCidade.ItemIndex < 0 then
    Exit;

  LObjeto := cbCidade.Properties.Items.Objects[cbCidade.ItemIndex];
  if LObjeto is TCidade then
    Result := TCidade(LObjeto).Id;
end;

procedure TfrmCliente.SelecionarCidade(ACidadeId: Integer);
var
  I: Integer;
  LCidade: TCidade;
  LObjeto: TObject;
begin
  if ACidadeId <= 0 then
  begin
    cbCidade.ItemIndex := 0;
    Exit;
  end;

  LCidade := nil;
  for I := 0 to FCidades.Count - 1 do
    if FCidades[I].Id = ACidadeId then
    begin
      LCidade := FCidades[I];
      Break;
    end;

  if LCidade = nil then
  begin
    cbCidade.ItemIndex := 0;
    Exit;
  end;

  for I := 0 to cbEstado.Properties.Items.Count - 1 do
  begin
    LObjeto := cbEstado.Properties.Items.Objects[I];
    if (LObjeto is TEstado) and (TEstado(LObjeto).Id = LCidade.EstadoId) then
    begin
      cbEstado.ItemIndex := I;
      Break;
    end;
  end;

  FiltrarCidadesPorEstado(LCidade.EstadoId);

  for I := 0 to cbCidade.Properties.Items.Count - 1 do
  begin
    LObjeto := cbCidade.Properties.Items.Objects[I];
    if (LObjeto is TCidade) and (TCidade(LObjeto).Id = ACidadeId) then
    begin
      cbCidade.ItemIndex := I;
      Exit;
    end;
  end;
end;

procedure TfrmCliente.cbEstadoPropertiesChange(Sender: TObject);
begin
  FiltrarCidadesPorEstado(EstadoSelecionado);
end;

procedure TfrmCliente.Carregar(AId: Integer);
var
  LCarregado: TCliente;
begin
  if AId > 0 then
  begin
    LCarregado := FController.ObterPorId(AId);
    if LCarregado = nil then
      raise Exception.CreateFmt('Cliente %d nao encontrado.', [AId]);
    try
      FCliente.Assign(LCarregado);
    finally
      LCarregado.Free;
    end;

    Caption := Format('CARTSYS - Alteracao de Cliente: (ID %d)', [AId]);
    FCepConsultado := TViaCepService.SomenteDigitos(FCliente.Cep);
  end
  else
  begin
    Caption := 'CARTSYS - Inclusao de Cliente';
    FCepConsultado := '';
  end;

  EntidadeParaTela;
end;

procedure TfrmCliente.EntidadeParaTela;
begin
  if FCliente.EhNovo then
    edtId.Text := '(novo)'
  else
    edtId.Text := IntToStr(FCliente.Id);

  edtNome.Text        := FCliente.Nome;
  edtCpfCnpj.Text     := TDocumento.Formatar(FCliente.CpfCnpj);
  edtCep.Text         := TViaCepService.Formatar(FCliente.Cep);
  edtEndereco.Text    := FCliente.Endereco;
  edtNumero.Text      := FCliente.Numero;
  edtComplemento.Text := FCliente.Complemento;
  edtBairro.Text      := FCliente.Bairro;

  if FCliente.DataNascimento > 0 then
    edtNascimento.Date := FCliente.DataNascimento
  else
    edtNascimento.Clear;

  SelecionarCidade(FCliente.CidadeId);
end;

procedure TfrmCliente.TelaParaEntidade;
begin
  FCliente.Nome        := Trim(edtNome.Text);
  FCliente.CpfCnpj     := TDocumento.SomenteDigitos(edtCpfCnpj.Text);
  FCliente.Cep         := CepDigitado;
  FCliente.Endereco    := Trim(edtEndereco.Text);
  FCliente.Numero      := Trim(edtNumero.Text);
  FCliente.Complemento := Trim(edtComplemento.Text);
  FCliente.Bairro      := Trim(edtBairro.Text);
  FCliente.CidadeId    := CidadeSelecionada;

  if VarIsNull(edtNascimento.EditValue) or VarIsEmpty(edtNascimento.EditValue) then
    FCliente.DataNascimento := 0
  else
    FCliente.DataNascimento := edtNascimento.Date;
end;

function TfrmCliente.CepDigitado: string;
begin
  Result := TViaCepService.SomenteDigitos(edtCep.Text);
end;

procedure TfrmCliente.edtCepPropertiesChange(Sender: TObject);
begin
  if CepDigitado <> FCepConsultado then
    FCepConsultado := '';
end;

procedure TfrmCliente.edtCepExit(Sender: TObject);
begin
  ConsultarCep;
end;

procedure TfrmCliente.ConsultarCep;
var
  LCep: string;
  LResultado: TResultadoCep;
begin
  LCep := CepDigitado;

  if (LCep = '') or (LCep = FCepConsultado) then
    Exit;

  if not TViaCepService.FormatoValido(LCep) then
    Exit;

  Screen.Cursor := crHourGlass;
  try
    LResultado := FController.ConsultarCep(LCep);
  finally
    Screen.Cursor := crDefault;
  end;

  FCepConsultado := LCep;

  if not LResultado.Sucesso then
  begin
    ShowMessage(LResultado.Mensagem);
    Exit;
  end;

  TelaParaEntidade;
  FController.AplicarCep(FCliente, LResultado);
  EntidadeParaTela;

  if LResultado.Mensagem <> '' then
    ShowMessage(LResultado.Mensagem);
end;

procedure TfrmCliente.edtCpfCnpjExit(Sender: TObject);
begin
  edtCpfCnpj.Text := TDocumento.Formatar(edtCpfCnpj.Text);
end;

procedure TfrmCliente.btnSalvarClick(Sender: TObject);
begin
  TelaParaEntidade;

  try
    FController.Salvar(FCliente);
  except
    on E: ERegraNegocio do
    begin
      ShowMessage(E.Message);
      Exit;
    end;
  end;

  ModalResult := mrOk;
end;

procedure TfrmCliente.btnCancelarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
