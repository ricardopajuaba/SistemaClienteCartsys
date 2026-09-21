unit View.ClientePesquisa;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Variants,
  System.UITypes,
  System.Generics.Collections,
  Winapi.Windows,
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
  cxCustomData,
  cxFilter,
  cxData,
  cxDataStorage,
  cxEdit,
  cxNavigator,
  dxDateRanges,
  dxScrollbarAnnotations,
  cxClasses,
  cxGridCustomView,
  cxGridCustomTableView,
  cxGridTableView,
  cxGrid,
  cxGridLevel,
  cxContainer,
  cxTextEdit,
  cxMaskEdit,
  cxDropDownEdit,
  cxCalendar,
  cxLabel,
  cxButtons,
  Model.Entity.Cliente,
  DAO.Cliente,
  Controller.Cliente, Vcl.Menus;

type
  TfrmClientePesquisa = class(TForm)
    pnlFiltro: TPanel;
    lblCampo: TcxLabel;
    cbCampo: TcxComboBox;
    lblValor: TcxLabel;
    edtValor: TcxTextEdit;
    btnPesquisar: TcxButton;
    pnlAcoes: TPanel;
    btnNovo: TcxButton;
    btnAlterar: TcxButton;
    btnExcluir: TcxButton;
    btnFechar: TcxButton;
    grdClientes: TcxGrid;
    tvClientes: TcxGridTableView;
    lvClientes: TcxGridLevel;
    colId: TcxGridColumn;
    colNome: TcxGridColumn;
    colCpfCnpj: TcxGridColumn;
    colCep: TcxGridColumn;
    colEndereco: TcxGridColumn;
    colNumero: TcxGridColumn;
    colBairro: TcxGridColumn;
    colCidade: TcxGridColumn;
    colUf: TcxGridColumn;
    colNascimento: TcxGridColumn;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnPesquisarClick(Sender: TObject);
    procedure btnNovoClick(Sender: TObject);
    procedure btnAlterarClick(Sender: TObject);
    procedure btnExcluirClick(Sender: TObject);
    procedure btnFecharClick(Sender: TObject);
    procedure tvClientesCellDblClick(Sender: TcxCustomGridTableView;
      ACellViewInfo: TcxGridTableDataCellViewInfo; AButton: TMouseButton;
      AShift: TShiftState; var AHandled: Boolean);
  private
    FController: TClienteController;
    FClientes: TObjectList<TCliente>;

    procedure PrepararCombo;
    function CampoSelecionado: TCampoPesquisa;

    procedure Pesquisar;
    procedure PreencherGrid;

    function IdEmFoco: Integer;

    procedure FocalizarId(AId: Integer);

    function AbrirCadastro(AId: Integer): Boolean;
  end;

implementation

uses
  View.Cliente,
  Service.EnterTab,
  Service.Documento,
  Service.ViaCep;

{$R *.dfm}

procedure TfrmClientePesquisa.FormCreate(Sender: TObject);
begin
  FController := TClienteController.Create;

  FClientes := nil;

  PrepararCombo;

  TEnterComoTab.Instalar(Self);
end;

procedure TfrmClientePesquisa.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FClientes);
  FreeAndNil(FController);
end;

procedure TfrmClientePesquisa.FormShow(Sender: TObject);
begin
  Pesquisar;
end;

procedure TfrmClientePesquisa.PrepararCombo;
begin
  cbCampo.Properties.Items.Clear;
  cbCampo.Properties.Items.Add('Todos');
  cbCampo.Properties.Items.Add('ID');
  cbCampo.Properties.Items.Add('Nome');
  cbCampo.Properties.Items.Add('CPF / CNPJ');
  cbCampo.Properties.Items.Add('CEP');
  cbCampo.Properties.Items.Add('Cidade');
  cbCampo.Properties.Items.Add('Estado (UF ou nome)');
  cbCampo.Properties.Items.Add('Data de nascimento');
  cbCampo.ItemIndex := 0;
end;

function TfrmClientePesquisa.CampoSelecionado: TCampoPesquisa;
begin
  if (cbCampo.ItemIndex < 0) or
     (cbCampo.ItemIndex > Ord(High(TCampoPesquisa))) then
    Result := cpTodos
  else
    Result := TCampoPesquisa(cbCampo.ItemIndex);
end;

procedure TfrmClientePesquisa.Pesquisar;
var
  LIdAnterior: Integer;
begin
  LIdAnterior := IdEmFoco;

  Screen.Cursor := crHourGlass;
  try
    FreeAndNil(FClientes);
    FClientes := FController.Pesquisar(CampoSelecionado, edtValor.Text);
    PreencherGrid;
  finally
    Screen.Cursor := crDefault;
  end;

  if LIdAnterior > 0 then
    FocalizarId(LIdAnterior);
end;

procedure TfrmClientePesquisa.PreencherGrid;
var
  I: Integer;
  LCliente: TCliente;
begin
  tvClientes.BeginUpdate;
  try
    tvClientes.DataController.RecordCount := 0;

    if not Assigned(FClientes) then
      Exit;

    tvClientes.DataController.RecordCount := FClientes.Count;

    for I := 0 to FClientes.Count - 1 do
    begin
      LCliente := FClientes[I];

      tvClientes.DataController.Values[I, colId.Index]       := LCliente.Id;
      tvClientes.DataController.Values[I, colNome.Index]     := LCliente.Nome;
      tvClientes.DataController.Values[I, colCpfCnpj.Index]  :=
        TDocumento.Formatar(LCliente.CpfCnpj);
      tvClientes.DataController.Values[I, colCep.Index]      :=
        TViaCepService.Formatar(LCliente.Cep);
      tvClientes.DataController.Values[I, colEndereco.Index] := LCliente.Endereco;
      tvClientes.DataController.Values[I, colNumero.Index]   := LCliente.Numero;
      tvClientes.DataController.Values[I, colBairro.Index]   := LCliente.Bairro;
      tvClientes.DataController.Values[I, colCidade.Index]   := LCliente.NomeCidade;
      tvClientes.DataController.Values[I, colUf.Index]       := LCliente.Uf;

      if LCliente.DataNascimento > 0 then
        tvClientes.DataController.Values[I, colNascimento.Index] :=
          LCliente.DataNascimento
      else
        tvClientes.DataController.Values[I, colNascimento.Index] := Null;
    end;
  finally
    tvClientes.EndUpdate;
  end;
end;

function TfrmClientePesquisa.IdEmFoco: Integer;
var
  LIndice: Integer;
  LValor: Variant;
begin
  Result := 0;

  LIndice := tvClientes.DataController.FocusedRecordIndex;
  if (LIndice < 0) or (LIndice >= tvClientes.DataController.RecordCount) then
    Exit;

  LValor := tvClientes.DataController.Values[LIndice, colId.Index];
  if VarIsNull(LValor) or VarIsEmpty(LValor) then
    Exit;

  Result := LValor;
end;

procedure TfrmClientePesquisa.FocalizarId(AId: Integer);
var
  I: Integer;
  LValor: Variant;
begin
  for I := 0 to tvClientes.DataController.RecordCount - 1 do
  begin
    LValor := tvClientes.DataController.Values[I, colId.Index];
    if (not VarIsNull(LValor)) and (Integer(LValor) = AId) then
    begin
      tvClientes.DataController.FocusedRecordIndex := I;
      Exit;
    end;
  end;
end;

procedure TfrmClientePesquisa.btnPesquisarClick(Sender: TObject);
begin
  Pesquisar;
end;

function TfrmClientePesquisa.AbrirCadastro(AId: Integer): Boolean;
var
  LForm: TfrmCliente;
begin
  LForm := TfrmCliente.Create(Self);
  try
    LForm.Carregar(AId);
    Result := LForm.ShowModal = mrOk;
  finally
    LForm.Free;
  end;
end;

procedure TfrmClientePesquisa.btnNovoClick(Sender: TObject);
begin
  if AbrirCadastro(0) then
    Pesquisar;
end;

procedure TfrmClientePesquisa.btnAlterarClick(Sender: TObject);
var
  LId: Integer;
begin
  LId := IdEmFoco;
  if LId = 0 then
  begin
    ShowMessage('Selecione um cliente na lista.');
    Exit;
  end;

  if AbrirCadastro(LId) then
    Pesquisar;
end;

procedure TfrmClientePesquisa.btnExcluirClick(Sender: TObject);
var
  LId: Integer;
begin
  LId := IdEmFoco;
  if LId = 0 then
  begin
    ShowMessage('Selecione um cliente na lista.');
    Exit;
  end;

  if MessageDlg(Format('Confirma a exclusao do cliente %d?', [LId]),
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  try
    FController.Excluir(LId);
  except
    on E: ERegraNegocio do
    begin
      ShowMessage(E.Message);
      Exit;
    end;
  end;

  Pesquisar;
end;

procedure TfrmClientePesquisa.btnFecharClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmClientePesquisa.tvClientesCellDblClick(
  Sender: TcxCustomGridTableView;
  ACellViewInfo: TcxGridTableDataCellViewInfo; AButton: TMouseButton;
  AShift: TShiftState; var AHandled: Boolean);
begin
  if AButton <> mbLeft then
    Exit;

  AHandled := True;
  btnAlterarClick(Sender);
end;

end.
