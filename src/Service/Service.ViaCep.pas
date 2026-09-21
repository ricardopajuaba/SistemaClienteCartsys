unit Service.ViaCep;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.NetEncoding;

type
  TEnderecoCep = record
    Cep: string;
    Logradouro: string;
    Complemento: string;
    Bairro: string;
    Cidade: string;
    Uf: string;
    Encontrado: Boolean;
    Erro: string;

    procedure Limpar;
  end;

  TViaCepService = class
  private
    const
      URL_BASE = 'https://viacep.com.br/ws/%s/json/';
      TIMEOUT_MS = 8000;
  public
    class function SomenteDigitos(const ACep: string): string;

    class function FormatoValido(const ACep: string): Boolean;

    class function Formatar(const ACep: string): string;

    class function Consultar(const ACep: string): TEnderecoCep;
  end;

implementation

procedure TEnderecoCep.Limpar;
begin
  Cep         := '';
  Logradouro  := '';
  Complemento := '';
  Bairro      := '';
  Cidade      := '';
  Uf          := '';
  Encontrado  := False;
  Erro        := '';
end;

class function TViaCepService.SomenteDigitos(const ACep: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(ACep) do
    if CharInSet(ACep[I], ['0'..'9']) then
      Result := Result + ACep[I];
end;

class function TViaCepService.FormatoValido(const ACep: string): Boolean;
begin
  Result := Length(SomenteDigitos(ACep)) = 8;
end;

class function TViaCepService.Formatar(const ACep: string): string;
var
  LDigitos: string;
begin
  LDigitos := SomenteDigitos(ACep);
  if Length(LDigitos) = 8 then
    Result := Copy(LDigitos, 1, 5) + '-' + Copy(LDigitos, 6, 3)
  else
    Result := ACep;
end;

class function TViaCepService.Consultar(const ACep: string): TEnderecoCep;
var
  LHttp: THTTPClient;
  LResposta: IHTTPResponse;
  LCepLimpo: string;
  LConteudo: string;
  LJson: TJSONValue;
  LObjeto: TJSONObject;
  LValorErro: TJSONValue;

  function Texto(const ACampo: string): string;
  var
    LValor: TJSONValue;
  begin
    Result := '';
    LValor := LObjeto.GetValue(ACampo);
    if Assigned(LValor) then
      Result := LValor.Value;
  end;

begin
  Result.Limpar;

  LCepLimpo := SomenteDigitos(ACep);

  if LCepLimpo = '' then
  begin
    Result.Erro := 'Informe o CEP.';
    Exit;
  end;

  if Length(LCepLimpo) <> 8 then
  begin
    Result.Erro := Format(
      'CEP invalido: deve conter 8 digitos, foram informados %d.',
      [Length(LCepLimpo)]);
    Exit;
  end;

  LHttp := THTTPClient.Create;
  try
    LHttp.ConnectionTimeout := TIMEOUT_MS;
    LHttp.ResponseTimeout   := TIMEOUT_MS;

    try
      LResposta := LHttp.Get(Format(URL_BASE, [LCepLimpo]));
    except
      on E: Exception do
      begin
        Result.Erro :=
          'Nao foi possivel consultar o CEP agora (' + E.Message + ').' +
          sLineBreak + 'Preencha o endereco manualmente.';
        Exit;
      end;
    end;

    if LResposta.StatusCode = 400 then
    begin
      Result.Erro := 'CEP invalido: a consulta foi recusada pelo ViaCEP.';
      Exit;
    end;

    if LResposta.StatusCode <> 200 then
    begin
      Result.Erro := Format(
        'O servico de CEP respondeu com o codigo %d. Tente novamente.',
        [LResposta.StatusCode]);
      Exit;
    end;

    LConteudo := LResposta.ContentAsString(TEncoding.UTF8);

    LJson := TJSONObject.ParseJSONValue(LConteudo);
    if not Assigned(LJson) then
    begin
      Result.Erro := 'Resposta do servico de CEP em formato inesperado.';
      Exit;
    end;

    try
      if not (LJson is TJSONObject) then
      begin
        Result.Erro := 'Resposta do servico de CEP em formato inesperado.';
        Exit;
      end;

      LObjeto := TJSONObject(LJson);

      LValorErro := LObjeto.GetValue('erro');
      if Assigned(LValorErro) then
      begin
        if SameText(LValorErro.Value, 'true') then
        begin
          Result.Erro := 'CEP nao encontrado.';
          Exit;
        end;
      end;

      Result.Cep         := Formatar(Texto('cep'));
      Result.Logradouro  := Texto('logradouro');
      Result.Complemento := Texto('complemento');
      Result.Bairro      := Texto('bairro');
      Result.Cidade      := Texto('localidade');
      Result.Uf          := Texto('uf');
      Result.Encontrado  := True;
    finally
      LJson.Free;
    end;
  finally
    LHttp.Free;
  end;
end;

end.
