unit DAO.Estado;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Data.DB,
  FireDAC.Stan.Param,
  FireDAC.Comp.Client,
  Model.Entity.Estado;

type
  TEstadoDAO = class
  private
    function MontarEntidade(AQuery: TFDQuery): TEstado;
  public
    function Listar: TObjectList<TEstado>;

    function ObterPorId(AId: Integer): TEstado;
  end;

implementation

uses
  DAO.Conexao;

function TEstadoDAO.MontarEntidade(AQuery: TFDQuery): TEstado;
begin
  Result := TEstado.Create;
  try
    Result.Id   := AQuery.FieldByName('ID').AsInteger;
    Result.Nome := AQuery.FieldByName('NOME').AsString;
    Result.Uf   := Trim(AQuery.FieldByName('UF').AsString);
  except
    Result.Free;
    raise;
  end;
end;

function TEstadoDAO.Listar: TObjectList<TEstado>;
var
  LQuery: TFDQuery;
begin
  Result := TObjectList<TEstado>.Create(True);
  try
    LQuery := TConexao.Obter.NovaQuery;
    try
      LQuery.SQL.Text := 'SELECT ID, NOME, UF FROM ESTADO ORDER BY NOME';
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

function TEstadoDAO.ObterPorId(AId: Integer): TEstado;
var
  LQuery: TFDQuery;
begin
  Result := nil;
  LQuery := TConexao.Obter.NovaQuery;
  try
    LQuery.SQL.Text := 'SELECT ID, NOME, UF FROM ESTADO WHERE ID = :ID';
    LQuery.ParamByName('ID').AsInteger := AId;
    LQuery.Open;

    if not LQuery.IsEmpty then
      Result := MontarEntidade(LQuery);
  finally
    LQuery.Free;
  end;
end;

end.
