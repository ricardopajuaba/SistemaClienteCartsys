unit DAO.Cliente;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Data.DB,
  FireDAC.Stan.Param,
  FireDAC.Comp.Client,
  Model.Entity.Cliente;

type
  TCampoPesquisa = (
    cpTodos,
    cpId,
    cpNome,
    cpCpfCnpj,
    cpCep,
    cpCidade,
    cpEstado,
    cpDataNascimento
  );

  TFiltroRelatorio = (frTodos, frFaixaId, frCidadeEstado);

  TClienteDAO = class
  private
    function SqlBase: string;
    function MontarEntidade(AQuery: TFDQuery): TCliente;
    procedure AtribuirParametros(AQuery: TFDQuery; ACliente: TCliente);
  public

    function Pesquisar(ACampo: TCampoPesquisa;
      const AValor: string): TObjectList<TCliente>;

    function ObterPorId(AId: Integer): TCliente;

    function ListarParaRelatorio(AFiltro: TFiltroRelatorio;
      AIdInicial, AIdFinal, ACidadeId, AEstadoId: Integer): TObjectList<TCliente>;

    function Inserir(ACliente: TCliente): Integer;
    procedure Alterar(ACliente: TCliente);
    procedure Excluir(AId: Integer);

    function CpfCnpjEmUso(const ACpfCnpj: string; AIdAtual: Integer): Boolean;
  end;

implementation

uses
  DAO.Conexao;

function TClienteDAO.SqlBase: string;
begin
  Result :=
    'SELECT CL.ID, CL.NOME, CL.CEP, CL.CPF_CNPJ, CL.ENDERECO, CL.NUMERO, ' +
    '       CL.COMPLEMENTO, CL.BAIRRO, CL.CIDADE, CL.DATANASCIMENTO, ' +
    '       CI.NOME AS NOME_CIDADE, E.UF, E.NOME AS NOME_ESTADO, E.ID AS ESTADO_ID ' +
    '  FROM CLIENTE CL ' +
    '  LEFT JOIN CIDADE CI ON CI.ID = CL.CIDADE ' +
    '  LEFT JOIN ESTADO E  ON E.ID  = CI.ESTADOID ';
end;

function TClienteDAO.MontarEntidade(AQuery: TFDQuery): TCliente;
begin
  Result := TCliente.Create;
  try
    Result.Id          := AQuery.FieldByName('ID').AsInteger;
    Result.Nome        := AQuery.FieldByName('NOME').AsString;
    Result.Cep         := Trim(AQuery.FieldByName('CEP').AsString);
    Result.CpfCnpj     := Trim(AQuery.FieldByName('CPF_CNPJ').AsString);
    Result.Endereco    := AQuery.FieldByName('ENDERECO').AsString;
    Result.Numero      := AQuery.FieldByName('NUMERO').AsString;
    Result.Complemento := AQuery.FieldByName('COMPLEMENTO').AsString;
    Result.Bairro      := AQuery.FieldByName('BAIRRO').AsString;
    Result.CidadeId    := AQuery.FieldByName('CIDADE').AsInteger;

    if AQuery.FieldByName('DATANASCIMENTO').IsNull then
      Result.DataNascimento := 0
    else
      Result.DataNascimento := AQuery.FieldByName('DATANASCIMENTO').AsDateTime;

    Result.NomeCidade := AQuery.FieldByName('NOME_CIDADE').AsString;
    Result.Uf         := Trim(AQuery.FieldByName('UF').AsString);
    Result.NomeEstado := AQuery.FieldByName('NOME_ESTADO').AsString;
  except
    Result.Free;
    raise;
  end;
end;

function TClienteDAO.Pesquisar(ACampo: TCampoPesquisa;
  const AValor: string): TObjectList<TCliente>;
var
  LQuery: TFDQuery;
  LWhere: string;
  LValor: string;
  LData: TDateTime;
begin
  LValor := Trim(AValor);
  Result := TObjectList<TCliente>.Create(True);
  try
    LQuery := TConexao.Obter.NovaQuery;
    try
      LWhere := '';

      if LValor <> '' then
      begin
        case ACampo of
          cpId:
            LWhere := ' WHERE CL.ID = :VALOR';
          cpNome:
            LWhere := ' WHERE UPPER(CL.NOME) LIKE UPPER(:VALOR)';
          cpCpfCnpj:
            LWhere := ' WHERE CL.CPF_CNPJ LIKE :VALOR';
          cpCep:
            LWhere := ' WHERE CL.CEP LIKE :VALOR';
          cpCidade:
            LWhere := ' WHERE UPPER(CI.NOME) LIKE UPPER(:VALOR)';
          cpEstado:
            LWhere := ' WHERE UPPER(CAST(E.UF AS VARCHAR(50))) = UPPER(:VALOR)' +
                      '    OR UPPER(E.NOME) LIKE UPPER(:VALOR2)';
          cpDataNascimento:
            LWhere := ' WHERE CL.DATANASCIMENTO = :VALOR';
        end;
      end;

      LQuery.SQL.Text := SqlBase + LWhere + ' ORDER BY CL.ID';

      if LWhere <> '' then
      begin
        case ACampo of
          cpId:
            LQuery.ParamByName('VALOR').AsInteger := StrToIntDef(LValor, -1);

          cpDataNascimento:
            begin
              if TryStrToDate(LValor, LData) then
                LQuery.ParamByName('VALOR').AsDate := LData
              else
                LQuery.ParamByName('VALOR').AsDate := EncodeDate(1900, 1, 1);
            end;

          cpEstado:
            begin
              LQuery.ParamByName('VALOR').AsString  := LValor;
              LQuery.ParamByName('VALOR2').AsString := '%' + LValor + '%';
            end;
        else
          LQuery.ParamByName('VALOR').AsString := '%' + LValor + '%';
        end;
      end;

      LQuery.Open;
      while not LQuery.Eof do
      begin
        Result.Add(MontarEntidade(LQuery));
        LQuery.Next;
      end;
    finally
      LQuery.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TClienteDAO.ObterPorId(AId: Integer): TCliente;
var
  LQuery: TFDQuery;
begin
  Result := nil;
  LQuery := TConexao.Obter.NovaQuery;
  try
    LQuery.SQL.Text := SqlBase + ' WHERE CL.ID = :ID';
    LQuery.ParamByName('ID').AsInteger := AId;
    LQuery.Open;
    if not LQuery.IsEmpty then
      Result := MontarEntidade(LQuery);
  finally
    LQuery.Free;
  end;
end;

function TClienteDAO.ListarParaRelatorio(AFiltro: TFiltroRelatorio;
  AIdInicial, AIdFinal, ACidadeId, AEstadoId: Integer): TObjectList<TCliente>;
var
  LQuery: TFDQuery;
  LWhere: string;
begin
  Result := TObjectList<TCliente>.Create(True);
  try
    LQuery := TConexao.Obter.NovaQuery;
    try
      LWhere := '';

      case AFiltro of
        frFaixaId:
          LWhere := ' WHERE CL.ID BETWEEN :ID_INI AND :ID_FIM';

        frCidadeEstado:
          begin
            if ACidadeId > 0 then
              LWhere := ' WHERE CL.CIDADE = :CIDADE_ID'
            else if AEstadoId > 0 then
              LWhere := ' WHERE CI.ESTADOID = :ESTADO_ID';
          end;
      end;

      LQuery.SQL.Text := SqlBase + LWhere + ' ORDER BY CL.ID';

      case AFiltro of
        frFaixaId:
          begin
            LQuery.ParamByName('ID_INI').AsInteger := AIdInicial;
            LQuery.ParamByName('ID_FIM').AsInteger := AIdFinal;
          end;

        frCidadeEstado:
          begin
            if ACidadeId > 0 then
              LQuery.ParamByName('CIDADE_ID').AsInteger := ACidadeId
            else if AEstadoId > 0 then
              LQuery.ParamByName('ESTADO_ID').AsInteger := AEstadoId;
          end;
      end;

      LQuery.Open;
      while not LQuery.Eof do
      begin
        Result.Add(MontarEntidade(LQuery));
        LQuery.Next;
      end;
    finally
      LQuery.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

procedure TClienteDAO.AtribuirParametros(AQuery: TFDQuery; ACliente: TCliente);

  procedure TextoOuNulo(const AParam, AValor: string);
  begin
    if Trim(AValor) = '' then
      AQuery.ParamByName(AParam).Clear
    else
      AQuery.ParamByName(AParam).AsString := Trim(AValor);
  end;

begin
  AQuery.ParamByName('NOME').AsString := Trim(ACliente.Nome);

  TextoOuNulo('CEP', ACliente.Cep);
  TextoOuNulo('CPF_CNPJ', ACliente.CpfCnpj);
  TextoOuNulo('ENDERECO', ACliente.Endereco);
  TextoOuNulo('NUMERO', ACliente.Numero);
  TextoOuNulo('COMPLEMENTO', ACliente.Complemento);
  TextoOuNulo('BAIRRO', ACliente.Bairro);

  if ACliente.CidadeId > 0 then
    AQuery.ParamByName('CIDADE').AsInteger := ACliente.CidadeId
  else
    AQuery.ParamByName('CIDADE').Clear;

  if ACliente.DataNascimento > 0 then
    AQuery.ParamByName('DATANASCIMENTO').AsDate := ACliente.DataNascimento
  else
    AQuery.ParamByName('DATANASCIMENTO').Clear;
end;

function TClienteDAO.Inserir(ACliente: TCliente): Integer;
var
  LQuery: TFDQuery;
begin
  LQuery := TConexao.Obter.NovaQuery;
  try
    LQuery.SQL.Text :=
      'INSERT INTO CLIENTE ' +
      '  (NOME, CEP, CPF_CNPJ, ENDERECO, NUMERO, COMPLEMENTO, BAIRRO, ' +
      '   CIDADE, DATANASCIMENTO) ' +
      'VALUES ' +
      '  (:NOME, :CEP, :CPF_CNPJ, :ENDERECO, :NUMERO, :COMPLEMENTO, :BAIRRO, ' +
      '   :CIDADE, :DATANASCIMENTO) ' +
      'RETURNING ID';

    AtribuirParametros(LQuery, ACliente);

    LQuery.Open;
    Result := LQuery.FieldByName('ID').AsInteger;
    ACliente.Id := Result;
  finally
    LQuery.Free;
  end;
end;

procedure TClienteDAO.Alterar(ACliente: TCliente);
var
  LQuery: TFDQuery;
begin
  LQuery := TConexao.Obter.NovaQuery;
  try
    LQuery.SQL.Text :=
      'UPDATE CLIENTE SET ' +
      '  NOME = :NOME, CEP = :CEP, CPF_CNPJ = :CPF_CNPJ, ' +
      '  ENDERECO = :ENDERECO, NUMERO = :NUMERO, ' +
      '  COMPLEMENTO = :COMPLEMENTO, BAIRRO = :BAIRRO, ' +
      '  CIDADE = :CIDADE, DATANASCIMENTO = :DATANASCIMENTO ' +
      'WHERE ID = :ID';

    AtribuirParametros(LQuery, ACliente);
    LQuery.ParamByName('ID').AsInteger := ACliente.Id;

    LQuery.ExecSQL;
  finally
    LQuery.Free;
  end;
end;

procedure TClienteDAO.Excluir(AId: Integer);
var
  LQuery: TFDQuery;
begin
  LQuery := TConexao.Obter.NovaQuery;
  try
    LQuery.SQL.Text := 'DELETE FROM CLIENTE WHERE ID = :ID';
    LQuery.ParamByName('ID').AsInteger := AId;
    LQuery.ExecSQL;
  finally
    LQuery.Free;
  end;
end;

function TClienteDAO.CpfCnpjEmUso(const ACpfCnpj: string;
  AIdAtual: Integer): Boolean;
var
  LQuery: TFDQuery;
begin
  Result := False;
  if Trim(ACpfCnpj) = '' then
    Exit;

  LQuery := TConexao.Obter.NovaQuery;
  try
    LQuery.SQL.Text :=
      'SELECT COUNT(*) AS TOTAL FROM CLIENTE ' +
      ' WHERE CPF_CNPJ = :CPF_CNPJ AND ID <> :ID';
    LQuery.ParamByName('CPF_CNPJ').AsString := Trim(ACpfCnpj);
    LQuery.ParamByName('ID').AsInteger := AIdAtual;
    LQuery.Open;
    Result := LQuery.FieldByName('TOTAL').AsInteger > 0;
  finally
    LQuery.Free;
  end;
end;

end.
