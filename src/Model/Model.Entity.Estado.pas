unit Model.Entity.Estado;

interface

type
  TEstado = class
  private
    FId: Integer;
    FNome: string;
    FUf: string;
  public
    property Id: Integer read FId write FId;
    property Nome: string read FNome write FNome;
    property Uf: string read FUf write FUf;

    function Descricao: string;
  end;

implementation

uses
  System.SysUtils;

function TEstado.Descricao: string;
begin
  Result := Trim(FNome);
  if Trim(FUf) <> '' then
    Result := Result + ' (' + Trim(FUf) + ')';
end;

end.
