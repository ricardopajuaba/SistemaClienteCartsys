unit Service.Texto;

interface

uses
  System.SysUtils;

type
  TTexto = class
  public
    class function RemoverAcentos(const AValor: string): string;

    class function Normalizar(const AValor: string): string;

    class function Equivalentes(const A, B: string): Boolean;
  end;

implementation

const
  COM_ACENTO =
    'ÁÀÃÂÄáàãâä' +
    'ÉÈÊËéèêë' +
    'ÍÌÎÏíìîï' +
    'ÓÒÕÔÖóòõôö' +
    'ÚÙÛÜúùûü' +
    'ÇçÑñÝýÿ';

  SEM_ACENTO =
    'AAAAAaaaaa' +
    'EEEEeeee' +
    'IIIIiiii' +
    'OOOOOooooo' +
    'UUUUuuuu' +
    'CcNnYyy';

class function TTexto.RemoverAcentos(const AValor: string): string;
var
  I, LPos: Integer;
begin
  Result := AValor;
  for I := 1 to Length(Result) do
  begin
    LPos := Pos(Result[I], COM_ACENTO);
    if LPos > 0 then
      Result[I] := SEM_ACENTO[LPos];
  end;
end;

class function TTexto.Normalizar(const AValor: string): string;
var
  LAnterior: string;
begin
  Result := UpperCase(RemoverAcentos(Trim(AValor)));

  repeat
    LAnterior := Result;
    Result := StringReplace(Result, '  ', ' ', [rfReplaceAll]);
  until Result = LAnterior;
end;

class function TTexto.Equivalentes(const A, B: string): Boolean;
begin
  Result := Normalizar(A) = Normalizar(B);
end;

end.
