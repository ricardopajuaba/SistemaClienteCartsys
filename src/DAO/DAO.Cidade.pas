unit DAO.Cidade;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Data.DB,
  FireDAC.Stan.Param,
  FireDAC.Comp.Client,
  Model.Entity.Cidade;

type
  TCidadeDAO = class
  private
    function MontarEntidade(AQuery: TFDQuery): TCidade;
    function SqlBase: string;
  public
    function Listar: TObjectList<TCidade>;

    function ListarPorEstado(AEstadoId: Integer): TObjectList<TCidade>;

    function ObterPorId(AId: Integer): TCidade;

    function ObterPorNomeUf(const ANome, AUf: string): TCidade;
  end;

implementation

uses
  DAO.Conexao,
  Service.Texto;

function TCidadeDAO.SqlBase: string;
begin
  Result :=
    'SELECT C.ID, C.NOME, C.ESTADOID, E.NOME AS NOME_ESTADO, E.UF ' +
    '  FROM CIDADE C ' +
    '  JOIN ESTADO E ON E.ID = C.ESTADOID ';
end;

function TCidadeDAO.MontarEntidade(AQuery: TFDQuery): TCidade;
begin
  Result := TCidade.Create;
  try
    Result.Id         := AQuery.FieldByName('ID').AsInteger;
    Result.Nome       := AQuery.FieldByName('NOME').AsString;
    Result.EstadoId   := AQuery.FieldByName('ESTADOID').AsInteger;
    Result.NomeEstado := AQuery.FieldByName('NOME_ESTADO').AsString;
    Result.Uf         := Trim(AQuery.FieldByName('UF').AsString);
  except
    Result.Free;
    raise;
  end;
end;

function TCidadeDAO.Listar: TObjectList<TCidade>;
var
  LQuery: TFDQuery;
begin
  Result := TObjectList<TCidade>.Create(True);
  try
    LQuery := TConexao.Obter.NovaQuery;
    try
      LQuery.SQL.Text := SqlBase + ' ORDER BY E.UF, C.NOME';
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

function TCidadeDAO.ListarPorEstado(AEstadoId: Integer): TObjectList<TCidade>;
var
  LQuery: TFDQuery;
begin
  Result := TObjectList<TCidade>.Create(True);
  try
    LQuery := TConexao.Obter.NovaQuery;
    try
      LQuery.SQL.Text := SqlBase + ' WHERE C.ESTADOID = :ESTADOID ORDER BY C.NOME';
      LQuery.ParamByName('ESTADOID').AsInteger := AEstadoId;
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

function TCidadeDAO.ObterPorId(AId: Integer): TCidade;
var
  LQuery: TFDQuery;
begin
  Result := nil;
  LQuery := TConexao.Obter.NovaQuery;
  try
    LQuery.SQL.Text := SqlBase + ' WHERE C.ID = :ID';
    LQuery.ParamByName('ID').AsInteger := AId;
    LQuery.Open;
    if not LQuery.IsEmpty then
      Result := MontarEntidade(LQuery);
  finally
    LQuery.Free;
  end;
end;

function TCidadeDAO.ObterPorNomeUf(const ANome, AUf: string): TCidade;
var
  LQuery: TFDQuery;
  LNomeProcurado: string;
begin
  Result := nil;
  LNomeProcurado := TTexto.Normalizar(ANome);
  if LNomeProcurado = '' then
    Exit;

  LQuery := TConexao.Obter.NovaQuery;
  try
    LQuery.SQL.Text := SqlBase +
      ' WHERE UPPER(CAST(E.UF AS VARCHAR(50))) = UPPER(:UF)' +
      ' ORDER BY C.NOME';
    LQuery.ParamByName('UF').AsString := Trim(AUf);
    LQuery.Open;

    while not LQuery.Eof do
    begin
      if TTexto.Normalizar(LQuery.FieldByName('NOME').AsString) = LNomeProcurado then
      begin
        Result := MontarEntidade(LQuery);
        Break;
      end;
      LQuery.Next;
    end;
  finally
    LQuery.Free;
  end;
end;

end.
