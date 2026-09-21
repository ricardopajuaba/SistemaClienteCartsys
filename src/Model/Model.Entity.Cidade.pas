unit Model.Entity.Cidade;

interface

type
  TCidade = class
  private
    FId: Integer;
    FNome: string;
    FEstadoId: Integer;
    FNomeEstado: string;
    FUf: string;
  public
    property Id: Integer read FId write FId;
    property Nome: string read FNome write FNome;
    property EstadoId: Integer read FEstadoId write FEstadoId;

    property NomeEstado: string read FNomeEstado write FNomeEstado;
    property Uf: string read FUf write FUf;

    function Descricao: string;
  end;

implementation

uses
  System.SysUtils;

function TCidade.Descricao: string;
begin
  Result := Trim(FNome);
  if Trim(FUf) <> '' then
    Result := Result + '/' + Trim(FUf);
end;

end.
