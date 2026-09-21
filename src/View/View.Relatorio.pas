unit View.Relatorio;

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
  cxSpinEdit,
  cxLabel,
  cxRadioGroup,
  cxButtons,
  ppClass,
  ppCtrls,
  ppBands,
  ppPrnabl,
  ppVar,
  ppTypes,
  ppReport,
  ppDB,
  ppDBJIT,
  Model.Entity.Cliente,
  Model.Entity.Cidade,
  Model.Entity.Estado,
  DAO.Cliente,
  Controller.Cliente, Vcl.Menus, cxGroupBox;

type
  TfrmRelatorio = class(TForm)
    rgFiltro: TcxRadioGroup;
    lblIdInicial: TcxLabel;
    seIdInicial: TcxSpinEdit;
    lblIdFinal: TcxLabel;
    seIdFinal: TcxSpinEdit;
    lblEstado: TcxLabel;
    cbEstado: TcxComboBox;
    lblCidade: TcxLabel;
    cbCidade: TcxComboBox;
    pnlAcoes: TPanel;
    btnVisualizar: TcxButton;
    btnFechar: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure rgFiltroPropertiesChange(Sender: TObject);
    procedure cbEstadoPropertiesChange(Sender: TObject);
    procedure btnVisualizarClick(Sender: TObject);
    procedure btnFecharClick(Sender: TObject);
  private
    FController: TClienteController;
    FEstados: TObjectList<TEstado>;
    FCidades: TObjectList<TCidade>;

    FClientes: TObjectList<TCliente>;

    FReport: TppReport;
    FPipeline: TppJITPipeline;

    procedure CarregarCombos;
    procedure FiltrarCidadesPorEstado(AEstadoId: Integer);
    procedure AtualizarHabilitacao;

    function FiltroSelecionado: TFiltroRelatorio;
    function EstadoSelecionado: Integer;
    function CidadeSelecionada: Integer;

    procedure MontarRelatorio;
    function PipelineGetFieldValue(aFieldName: String): Variant;
  public
    function Gerar: Integer;
  end;

implementation

uses
  Service.EnterTab,
  Service.Documento,
  Service.ViaCep;

{$R *.dfm}

type
  TColunaRelatorio = record
    Campo: string;       { nome usado no OnGetFieldValue }
    Titulo: string;      { texto do cabecalho }
    EsquerdaMm: Double;
    LarguraMm: Double;
  end;

const
 COLUNAS: array[0..9] of TColunaRelatorio = (
    (Campo: 'ID';          Titulo: 'Cod.';       EsquerdaMm:   0; LarguraMm: 12),
    (Campo: 'NOME';        Titulo: 'Nome';       EsquerdaMm:  12; LarguraMm: 55),
    (Campo: 'CPF_CNPJ';    Titulo: 'CPF / CNPJ'; EsquerdaMm:  67; LarguraMm: 32),
    (Campo: 'CEP';         Titulo: 'CEP';        EsquerdaMm:  99; LarguraMm: 20),
    (Campo: 'ENDERECO';    Titulo: 'Endereco';   EsquerdaMm: 119; LarguraMm: 50),
    (Campo: 'NUMERO';      Titulo: 'Num.';       EsquerdaMm: 169; LarguraMm: 12),
    (Campo: 'BAIRRO';      Titulo: 'Bairro';     EsquerdaMm: 181; LarguraMm: 33),
    (Campo: 'CIDADE';      Titulo: 'Cidade';     EsquerdaMm: 214; LarguraMm: 33),
    (Campo: 'UF';          Titulo: 'UF';         EsquerdaMm: 247; LarguraMm:  8),
    (Campo: 'NASCIMENTO';  Titulo: 'Nascimento'; EsquerdaMm: 255; LarguraMm: 20)
  );

  MM = 1000;

procedure TfrmRelatorio.FormCreate(Sender: TObject);
begin
  FController := TClienteController.Create;
  FClientes := nil;

  CarregarCombos;
  AtualizarHabilitacao;

  TEnterComoTab.Instalar(Self);
end;

procedure TfrmRelatorio.FormDestroy(Sender: TObject);
begin
  cbCidade.Properties.Items.Clear;
  cbEstado.Properties.Items.Clear;

  FreeAndNil(FClientes);
  FreeAndNil(FCidades);
  FreeAndNil(FEstados);
  FreeAndNil(FController);

  FreeAndNil(FReport);
  FreeAndNil(FPipeline);
end;

procedure TfrmRelatorio.CarregarCombos;
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

procedure TfrmRelatorio.FiltrarCidadesPorEstado(AEstadoId: Integer);
var
  I: Integer;
begin
  cbCidade.Properties.Items.BeginUpdate;
  try
    cbCidade.Properties.Items.Clear;
    cbCidade.Properties.Items.AddObject('(todas as cidades)', nil);

    for I := 0 to FCidades.Count - 1 do
      if (AEstadoId = 0) or (FCidades[I].EstadoId = AEstadoId) then
        cbCidade.Properties.Items.AddObject(FCidades[I].Descricao, FCidades[I]);
  finally
    cbCidade.Properties.Items.EndUpdate;
  end;

  cbCidade.ItemIndex := 0;
end;

procedure TfrmRelatorio.AtualizarHabilitacao;
var
  LFaixa: Boolean;
  LLocal: Boolean;
begin
  LFaixa := FiltroSelecionado = frFaixaId;
  LLocal := FiltroSelecionado = frCidadeEstado;

  lblIdInicial.Enabled := LFaixa;
  seIdInicial.Enabled  := LFaixa;
  lblIdFinal.Enabled   := LFaixa;
  seIdFinal.Enabled    := LFaixa;

  lblEstado.Enabled := LLocal;
  cbEstado.Enabled  := LLocal;
  lblCidade.Enabled := LLocal;
  cbCidade.Enabled  := LLocal;
end;

procedure TfrmRelatorio.rgFiltroPropertiesChange(Sender: TObject);
begin
  AtualizarHabilitacao;
end;

procedure TfrmRelatorio.cbEstadoPropertiesChange(Sender: TObject);
begin
  FiltrarCidadesPorEstado(EstadoSelecionado);
end;

function TfrmRelatorio.FiltroSelecionado: TFiltroRelatorio;
begin
  if (rgFiltro.ItemIndex < 0) or
     (rgFiltro.ItemIndex > Ord(High(TFiltroRelatorio))) then
    Result := frTodos
  else
    Result := TFiltroRelatorio(rgFiltro.ItemIndex);
end;

function TfrmRelatorio.EstadoSelecionado: Integer;
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

function TfrmRelatorio.CidadeSelecionada: Integer;
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

function TfrmRelatorio.PipelineGetFieldValue(aFieldName: String): Variant;
var
  LCliente: TCliente;
  LIndice: Integer;
begin
  Result := Null;

  if not Assigned(FClientes) then
    Exit;

  LIndice := FPipeline.RecordIndex;
  if (LIndice < 0) or (LIndice >= FClientes.Count) then
    Exit;

  LCliente := FClientes[LIndice];

  if aFieldName = 'ID' then
    Result := LCliente.Id
  else if aFieldName = 'NOME' then
    Result := LCliente.Nome
  else if aFieldName = 'CPF_CNPJ' then
    Result := TDocumento.Formatar(LCliente.CpfCnpj)
  else if aFieldName = 'CEP' then
    Result := TViaCepService.Formatar(LCliente.Cep)
  else if aFieldName = 'ENDERECO' then
    Result := LCliente.Endereco
  else if aFieldName = 'NUMERO' then
    Result := LCliente.Numero
  else if aFieldName = 'BAIRRO' then
    Result := LCliente.Bairro
  else if aFieldName = 'CIDADE' then
    Result := LCliente.NomeCidade
  else if aFieldName = 'UF' then
    Result := LCliente.Uf
  else if aFieldName = 'NASCIMENTO' then
  begin
    if LCliente.DataNascimento > 0 then
      Result := FormatDateTime('dd/mm/yyyy', LCliente.DataNascimento);
  end;
end;

procedure TfrmRelatorio.MontarRelatorio;

  procedure Posicionar(AComp: TppComponent;
    AEsqMm, ATopoMm, ALargMm, AAltMm: Single);
  begin
    AComp.Left   := AEsqMm;
    AComp.Top    := ATopoMm;
    AComp.Width  := ALargMm;
    AComp.Height := AAltMm;
  end;

  function NovoRotulo(ABand: TppBand; const ATexto: string;
    AEsqMm, ATopoMm, ALargMm: Double; ANegrito: Boolean): TppLabel;
  begin
    Result := TppLabel.Create(Self);
    Result.Band := ABand;
    Result.Caption := ATexto;
    Result.Font.Name := 'Arial';
    Result.Font.Size := 8;
    if ANegrito then
      Result.Font.Style := [fsBold];
    Result.Transparent := True;
    Posicionar(Result, AEsqMm, ATopoMm, ALargMm, 4);
  end;

var
  I: Integer;
  LTexto: TppDBText;
  LLinha: TppLine;
  LTitulo: TppLabel;
  LVariavel: TppSystemVariable;
begin
  FreeAndNil(FReport);
  FreeAndNil(FPipeline);

  FPipeline := TppJITPipeline.Create(Self);
  FPipeline.UserName := 'plClientes';
  FPipeline.OnGetFieldValue := PipelineGetFieldValue;

  for I := Low(COLUNAS) to High(COLUNAS) do
    FPipeline.DefineField(COLUNAS[I].Campo, dtString, 100);

  FReport := TppReport.Create(Self);
  FReport.UserName := 'repClientes';
  FReport.DataPipeline := FPipeline;
  FReport.Units := utMillimeters;

  FReport.PrinterSetup.Orientation := poLandscape;

  FReport.PrinterSetup.MarginLeft   := 11;
  FReport.PrinterSetup.MarginRight  := 11;
  FReport.PrinterSetup.MarginTop    := 11;
  FReport.PrinterSetup.MarginBottom := 11;

  FReport.DefaultBands := [btTitle, btHeader, btDetail, btFooter];
  FReport.CreateDefaultBands;

  FReport.TitleBand.mmHeight := 16 * MM;

  LTitulo := NovoRotulo(FReport.TitleBand, 'Relatorio de Clientes', 0, 1, 120, True);
  LTitulo.Font.Size := 14;
  Posicionar(LTitulo, 0, 1, 120, 7);

  NovoRotulo(FReport.TitleBand, 'Emitido em ' +
    FormatDateTime('dd/mm/yyyy hh:nn', Now), 0, 9, 120, False);

  FReport.HeaderBand.mmHeight := 8 * MM;

  for I := Low(COLUNAS) to High(COLUNAS) do
    NovoRotulo(FReport.HeaderBand, COLUNAS[I].Titulo,
      COLUNAS[I].EsquerdaMm, 1, COLUNAS[I].LarguraMm, True);

  LLinha := TppLine.Create(Self);
  LLinha.Band := FReport.HeaderBand;
  LLinha.Position := lpBottom;
  LLinha.Weight := 0.75;
  Posicionar(LLinha, 0, 6.5, 275, 1);

  FReport.DetailBand.mmHeight := 5 * MM;

  for I := Low(COLUNAS) to High(COLUNAS) do
  begin
    LTexto := TppDBText.Create(Self);
    LTexto.Band := FReport.DetailBand;
    LTexto.DataPipeline := FPipeline;
    LTexto.DataField := COLUNAS[I].Campo;
    LTexto.Font.Name := 'Arial';
    LTexto.Font.Size := 8;
    LTexto.Transparent := True;
    Posicionar(LTexto, COLUNAS[I].EsquerdaMm, 0.5, COLUNAS[I].LarguraMm, 4);
  end;

  FReport.FooterBand.mmHeight := 10 * MM;

  LLinha := TppLine.Create(Self);
  LLinha.Band := FReport.FooterBand;
  LLinha.Position := lpTop;
  LLinha.Weight := 0.75;
  Posicionar(LLinha, 0, 1, 275, 1);

  NovoRotulo(FReport.FooterBand,
    Format('Total de clientes: %d', [FClientes.Count]), 0, 3, 100, False);

  LVariavel := TppSystemVariable.Create(Self);
  LVariavel.Band := FReport.FooterBand;
  LVariavel.VarType := vtPageNoDesc;
  LVariavel.Font.Name := 'Arial';
  LVariavel.Font.Size := 8;
  LVariavel.Alignment := taRightJustify;
  LVariavel.Transparent := True;
  Posicionar(LVariavel, 195, 3, 80, 4);
end;

function TfrmRelatorio.Gerar: Integer;
begin
  Screen.Cursor := crHourGlass;
  try
    FreeAndNil(FClientes);
    FClientes := FController.ListarParaRelatorio(
      FiltroSelecionado,
      seIdInicial.Value,
      seIdFinal.Value,
      CidadeSelecionada,
      EstadoSelecionado);
  finally
    Screen.Cursor := crDefault;
  end;

  Result := FClientes.Count;
  if Result = 0 then
    Exit;

  MontarRelatorio;

  FPipeline.RecordCount := FClientes.Count;
end;

procedure TfrmRelatorio.btnVisualizarClick(Sender: TObject);
begin
  if Gerar = 0 then
  begin
    ShowMessage('Nenhum cliente encontrado para o filtro informado.');
    Exit;
  end;

  FReport.DeviceType := 'Screen';
  FReport.ShowPrintDialog := False;
  FReport.ModalPreview := True;
  FReport.Print;
end;

procedure TfrmRelatorio.btnFecharClick(Sender: TObject);
begin
  Close;
end;

end.
