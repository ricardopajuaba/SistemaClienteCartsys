unit Service.RegrasCliente;

interface

uses
  System.SysUtils,
  System.Classes,
  Model.Entity.Cliente;

type
  TRegrasCliente = class
  public

    class function IdProtegido(AId: Integer): Boolean;
    class function ListaIdsProtegidos: string;
    class function Criticar(ACliente: TCliente): string;
    class function CriticarExclusao(AId: Integer): string;
  end;

implementation

uses
  Service.Documento,
  Service.ViaCep;

const
  IDS_PROTEGIDOS: array[0..4] of Integer = (1, 5, 8, 10, 15);

class function TRegrasCliente.IdProtegido(AId: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := Low(IDS_PROTEGIDOS) to High(IDS_PROTEGIDOS) do
    if IDS_PROTEGIDOS[I] = AId then
      Exit(True);
end;

class function TRegrasCliente.ListaIdsProtegidos: string;
var
  I: Integer;
begin
  Result := '';
  for I := Low(IDS_PROTEGIDOS) to High(IDS_PROTEGIDOS) do
  begin
    if Result = '' then
      Result := IntToStr(IDS_PROTEGIDOS[I])
    else if I = High(IDS_PROTEGIDOS) then
      Result := Result + ' e ' + IntToStr(IDS_PROTEGIDOS[I])
    else
      Result := Result + ', ' + IntToStr(IDS_PROTEGIDOS[I]);
  end;
end;

class function TRegrasCliente.Criticar(ACliente: TCliente): string;
var
  LCriticas: TStringList;
  LCriticaDoc: string;
begin
  Result := '';
  if ACliente = nil then
    Exit('Nenhum cliente informado.');

  LCriticas := TStringList.Create;
  try
    if Trim(ACliente.Nome) = '' then
      LCriticas.Add('- Informe o nome do cliente.')
    else if Length(Trim(ACliente.Nome)) < 3 then
      LCriticas.Add('- O nome deve ter ao menos 3 caracteres.')
    else if Length(Trim(ACliente.Nome)) > 80 then
      LCriticas.Add('- O nome nao pode passar de 80 caracteres.');

    LCriticaDoc := TDocumento.Criticar(ACliente.CpfCnpj);
    if LCriticaDoc <> '' then
      LCriticas.Add('- ' + LCriticaDoc);

    if Trim(ACliente.Cep) <> '' then
      if not TViaCepService.FormatoValido(ACliente.Cep) then
        LCriticas.Add('- CEP invalido: informe 8 digitos.');

    if ACliente.CidadeId <= 0 then
      LCriticas.Add('- Selecione a cidade.');

    if ACliente.DataNascimento > 0 then
    begin
      if ACliente.DataNascimento > Date then
        LCriticas.Add('- A data de nascimento nao pode ser futura.')
      else if ACliente.DataNascimento < EncodeDate(1900, 1, 1) then
        LCriticas.Add('- A data de nascimento parece incorreta (anterior a 1900).');
    end;

    if Length(Trim(ACliente.Endereco)) > 100 then
      LCriticas.Add('- O endereco nao pode passar de 100 caracteres.');
    if Length(Trim(ACliente.Numero)) > 20 then
      LCriticas.Add('- O numero nao pode passar de 20 caracteres.');
    if Length(Trim(ACliente.Complemento)) > 60 then
      LCriticas.Add('- O complemento nao pode passar de 60 caracteres.');
    if Length(Trim(ACliente.Bairro)) > 100 then
      LCriticas.Add('- O bairro nao pode passar de 100 caracteres.');

    if LCriticas.Count > 0 then
      Result := LCriticas.Text;
  finally
    LCriticas.Free;
  end;
end;

class function TRegrasCliente.CriticarExclusao(AId: Integer): string;
begin
  Result := '';

  if AId <= 0 then
    Exit('Selecione um cliente para excluir.');

  if IdProtegido(AId) then
    Result := Format(
      'O cliente de codigo %d nao pode ser excluido.' + sLineBreak + sLineBreak +
      'Os registros de codigo %s sao protegidos pelo sistema.',
      [AId, ListaIdsProtegidos]);
end;

end.
