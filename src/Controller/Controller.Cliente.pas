unit Controller.Cliente;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Model.Entity.Cliente,
  Model.Entity.Cidade,
  Model.Entity.Estado,
  DAO.Cliente,
  DAO.Cidade,
  DAO.Estado,
  Service.ViaCep;

type
  ERegraNegocio = class(Exception);

  TResultadoCep = record
    Sucesso: Boolean;
    Mensagem: string;
    Endereco: string;
    Bairro: string;
    NomeCidade: string;
    Uf: string;

    CidadeId: Integer;
  end;

  TClienteController = class
  private
    FClienteDAO: TClienteDAO;
    FCidadeDAO: TCidadeDAO;
    FEstadoDAO: TEstadoDAO;
  public
    constructor Create;
    destructor Destroy; override;

    function Pesquisar(ACampo: TCampoPesquisa;
      const AValor: string): TObjectList<TCliente>;

    function ObterPorId(AId: Integer): TCliente;

    function ListarEstados: TObjectList<TEstado>;
    function ListarCidades: TObjectList<TCidade>;
    function ListarCidadesPorEstado(AEstadoId: Integer): TObjectList<TCidade>;

    function ListarParaRelatorio(AFiltro: TFiltroRelatorio;
      AIdInicial, AIdFinal, ACidadeId, AEstadoId: Integer): TObjectList<TCliente>;

    procedure Salvar(ACliente: TCliente);

    procedure Excluir(AId: Integer);


    function ConsultarCep(const ACep: string): TResultadoCep;

    procedure AplicarCep(ACliente: TCliente; const AResultado: TResultadoCep);
  end;

implementation

uses
  DAO.Conexao,
  Service.RegrasCliente,
  Service.Texto;

constructor TClienteController.Create;
begin
  inherited Create;
  FClienteDAO := TClienteDAO.Create;
  FCidadeDAO  := TCidadeDAO.Create;
  FEstadoDAO  := TEstadoDAO.Create;
end;

destructor TClienteController.Destroy;
begin
  FEstadoDAO.Free;
  FCidadeDAO.Free;
  FClienteDAO.Free;
  inherited Destroy;
end;

function TClienteController.Pesquisar(ACampo: TCampoPesquisa;
  const AValor: string): TObjectList<TCliente>;
begin
  try
    Result := FClienteDAO.Pesquisar(ACampo, AValor);
  finally
    TConexao.Obter.EncerrarLeitura;
  end;
end;

function TClienteController.ObterPorId(AId: Integer): TCliente;
begin
  try
    Result := FClienteDAO.ObterPorId(AId);
  finally
    TConexao.Obter.EncerrarLeitura;
  end;
end;

function TClienteController.ListarEstados: TObjectList<TEstado>;
begin
  try
    Result := FEstadoDAO.Listar;
  finally
    TConexao.Obter.EncerrarLeitura;
  end;
end;

function TClienteController.ListarCidades: TObjectList<TCidade>;
begin
  try
    Result := FCidadeDAO.Listar;
  finally
    TConexao.Obter.EncerrarLeitura;
  end;
end;

function TClienteController.ListarCidadesPorEstado(
  AEstadoId: Integer): TObjectList<TCidade>;
begin
  try
    Result := FCidadeDAO.ListarPorEstado(AEstadoId);
  finally
    TConexao.Obter.EncerrarLeitura;
  end;
end;

function TClienteController.ListarParaRelatorio(AFiltro: TFiltroRelatorio;
  AIdInicial, AIdFinal, ACidadeId, AEstadoId: Integer): TObjectList<TCliente>;
begin
  if (AFiltro = frFaixaId) and (AIdInicial > AIdFinal) then
  begin
    AIdFinal := AIdInicial xor AIdFinal;
    AIdInicial := AIdInicial xor AIdFinal;
    AIdFinal := AIdInicial xor AIdFinal;
  end;

  try
    Result := FClienteDAO.ListarParaRelatorio(
      AFiltro, AIdInicial, AIdFinal, ACidadeId, AEstadoId);
  finally
    TConexao.Obter.EncerrarLeitura;
  end;
end;

procedure TClienteController.Salvar(ACliente: TCliente);
var
  LCriticas: string;
  LDocumento: string;
begin
  if ACliente = nil then
    raise ERegraNegocio.Create('Nenhum cliente informado.');

  LCriticas := TRegrasCliente.Criticar(ACliente);
  if LCriticas <> '' then
    raise ERegraNegocio.Create(
      'Nao foi possivel salvar:' + sLineBreak + sLineBreak + LCriticas);

  LDocumento := Trim(ACliente.CpfCnpj);
  if LDocumento <> '' then
    if FClienteDAO.CpfCnpjEmUso(LDocumento, ACliente.Id) then
      raise ERegraNegocio.CreateFmt(
        'O CPF/CNPJ %s ja esta cadastrado para outro cliente.', [LDocumento]);

  TConexao.Obter.IniciarTransacao;
  try
    if ACliente.EhNovo then
      FClienteDAO.Inserir(ACliente)
    else
      FClienteDAO.Alterar(ACliente);

    TConexao.Obter.Confirmar;
  except
    TConexao.Obter.Desfazer;
    raise;
  end;
end;

procedure TClienteController.Excluir(AId: Integer);
var
  LCritica: string;
begin
  LCritica := TRegrasCliente.CriticarExclusao(AId);
  if LCritica <> '' then
    raise ERegraNegocio.Create(LCritica);

  TConexao.Obter.IniciarTransacao;
  try
    FClienteDAO.Excluir(AId);
    TConexao.Obter.Confirmar;
  except
    on E: Exception do
    begin
      TConexao.Obter.Desfazer;

      if Pos('EX_CLIENTE_PROTEGIDO', UpperCase(E.Message)) > 0 then
        raise ERegraNegocio.Create(TRegrasCliente.CriticarExclusao(AId));

      raise;
    end;
  end;
end;

function TClienteController.ConsultarCep(const ACep: string): TResultadoCep;
var
  LEndereco: TEnderecoCep;
  LCidade: TCidade;
begin
  Result.Sucesso    := False;
  Result.Mensagem   := '';
  Result.Endereco   := '';
  Result.Bairro     := '';
  Result.NomeCidade := '';
  Result.Uf         := '';
  Result.CidadeId   := 0;

  LEndereco := TViaCepService.Consultar(ACep);

  if not LEndereco.Encontrado then
  begin
    Result.Mensagem := LEndereco.Erro;
    Exit;
  end;

  Result.Sucesso    := True;
  Result.Endereco   := LEndereco.Logradouro;
  Result.Bairro     := LEndereco.Bairro;
  Result.NomeCidade := LEndereco.Cidade;
  Result.Uf         := LEndereco.Uf;

  try
    LCidade := FCidadeDAO.ObterPorNomeUf(LEndereco.Cidade, LEndereco.Uf);
  finally
    TConexao.Obter.EncerrarLeitura;
  end;

  if Assigned(LCidade) then
  try
    Result.CidadeId := LCidade.Id;
  finally
    LCidade.Free;
  end
  else
    Result.Mensagem := Format(
      'Endereco encontrado, mas a cidade %s/%s nao esta cadastrada.' +
      sLineBreak + 'Selecione a cidade manualmente.',
      [LEndereco.Cidade, LEndereco.Uf]);
end;

procedure TClienteController.AplicarCep(ACliente: TCliente;
  const AResultado: TResultadoCep);
begin
  if (ACliente = nil) or (not AResultado.Sucesso) then
    Exit;

  ACliente.Cep := TViaCepService.SomenteDigitos(ACliente.Cep);

  if Trim(AResultado.Endereco) <> '' then
    ACliente.Endereco := AResultado.Endereco;

  if Trim(AResultado.Bairro) <> '' then
    ACliente.Bairro := AResultado.Bairro;

  if AResultado.CidadeId > 0 then
  begin
    ACliente.CidadeId   := AResultado.CidadeId;
    ACliente.NomeCidade := AResultado.NomeCidade;
    ACliente.Uf         := AResultado.Uf;
  end;

end;

end.
