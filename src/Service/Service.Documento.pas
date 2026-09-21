unit Service.Documento;

interface

uses
  System.SysUtils,
  System.Character;

type
  TTipoDocumento = (tdIndefinido, tdCpf, tdCnpj);

  TDocumento = class
  public
    class function SomenteDigitos(const AValor: string): string;
    class function Tipo(const AValor: string): TTipoDocumento;
    class function CpfValido(const AValor: string): Boolean;
    class function CnpjValido(const AValor: string): Boolean;
    class function Valido(const AValor: string): Boolean;
    class function Formatar(const AValor: string): string;
    class function Criticar(const AValor: string): string;
  end;

implementation

class function TDocumento.SomenteDigitos(const AValor: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(AValor) do
    if CharInSet(AValor[I], ['0'..'9']) then
      Result := Result + AValor[I];
end;

class function TDocumento.Tipo(const AValor: string): TTipoDocumento;
var
  LDigitos: string;
begin
  LDigitos := SomenteDigitos(AValor);
  case Length(LDigitos) of
    11: Result := tdCpf;
    14: Result := tdCnpj;
  else
    Result := tdIndefinido;
  end;
end;

class function TDocumento.CpfValido(const AValor: string): Boolean;
var
  LCpf: string;
  LSoma, I, LDv1, LDv2: Integer;
  LTodosIguais: Boolean;
begin
  Result := False;
  LCpf := SomenteDigitos(AValor);

  if Length(LCpf) <> 11 then
    Exit;

  LTodosIguais := True;
  for I := 2 to 11 do
    if LCpf[I] <> LCpf[1] then
    begin
      LTodosIguais := False;
      Break;
    end;
  if LTodosIguais then
    Exit;

  LSoma := 0;
  for I := 1 to 9 do
    LSoma := LSoma + StrToInt(LCpf[I]) * (11 - I);
  LDv1 := (LSoma * 10) mod 11 mod 10;

  LSoma := 0;
  for I := 1 to 10 do
    LSoma := LSoma + StrToInt(LCpf[I]) * (12 - I);
  LDv2 := (LSoma * 10) mod 11 mod 10;

  Result := (LDv1 = StrToInt(LCpf[10])) and (LDv2 = StrToInt(LCpf[11]));
end;

class function TDocumento.CnpjValido(const AValor: string): Boolean;
const
  PESOS_1: array[1..12] of Integer = (5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2);
  PESOS_2: array[1..13] of Integer = (6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2);
var
  LCnpj: string;
  LSoma, I, LResto, LDv1, LDv2: Integer;
  LTodosIguais: Boolean;
begin
  Result := False;
  LCnpj := SomenteDigitos(AValor);

  if Length(LCnpj) <> 14 then
    Exit;

  LTodosIguais := True;
  for I := 2 to 14 do
    if LCnpj[I] <> LCnpj[1] then
    begin
      LTodosIguais := False;
      Break;
    end;
  if LTodosIguais then
    Exit;

  LSoma := 0;
  for I := 1 to 12 do
    LSoma := LSoma + StrToInt(LCnpj[I]) * PESOS_1[I];
  LResto := LSoma mod 11;
  if LResto < 2 then
    LDv1 := 0
  else
    LDv1 := 11 - LResto;

  LSoma := 0;
  for I := 1 to 13 do
    LSoma := LSoma + StrToInt(LCnpj[I]) * PESOS_2[I];
  LResto := LSoma mod 11;
  if LResto < 2 then
    LDv2 := 0
  else
    LDv2 := 11 - LResto;

  Result := (LDv1 = StrToInt(LCnpj[13])) and (LDv2 = StrToInt(LCnpj[14]));
end;

class function TDocumento.Valido(const AValor: string): Boolean;
begin
  case Tipo(AValor) of
    tdCpf:  Result := CpfValido(AValor);
    tdCnpj: Result := CnpjValido(AValor);
  else
    Result := False;
  end;
end;

class function TDocumento.Formatar(const AValor: string): string;
var
  LDigitos: string;
begin
  LDigitos := SomenteDigitos(AValor);

  if Length(LDigitos) = 11 then
    Result := Format('%s.%s.%s-%s', [
      Copy(LDigitos, 1, 3), Copy(LDigitos, 4, 3),
      Copy(LDigitos, 7, 3), Copy(LDigitos, 10, 2)])

  else if Length(LDigitos) = 14 then
    Result := Format('%s.%s.%s/%s-%s', [
      Copy(LDigitos, 1, 2), Copy(LDigitos, 3, 3), Copy(LDigitos, 6, 3),
      Copy(LDigitos, 9, 4), Copy(LDigitos, 13, 2)])

  else
    Result := AValor;
end;

class function TDocumento.Criticar(const AValor: string): string;
var
  LDigitos: string;
begin
  Result := '';
  LDigitos := SomenteDigitos(AValor);

  if LDigitos = '' then
    Exit;

  case Tipo(AValor) of
    tdCpf:
      if not CpfValido(AValor) then
        Result := 'CPF invalido. Confira os numeros digitados.';

    tdCnpj:
      if not CnpjValido(AValor) then
        Result := 'CNPJ invalido. Confira os numeros digitados.';
  else
    Result := Format(
      'Documento invalido: informe 11 digitos para CPF ou 14 para CNPJ. ' +
      'Foram informados %d.', [Length(LDigitos)]);
  end;
end;

end.
