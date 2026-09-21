unit Model.Entity.Cliente;

interface

type
  TCliente = class
  private
    FId: Integer;
    FNome: string;
    FCep: string;
    FCpfCnpj: string;
    FEndereco: string;
    FNumero: string;
    FComplemento: string;
    FBairro: string;
    FCidadeId: Integer;
    FDataNascimento: TDateTime;
    FNomeCidade: string;
    FUf: string;
    FNomeEstado: string;
  public
    constructor Create;

    procedure Assign(ASource: TCliente);

    property Id: Integer read FId write FId;
    property Nome: string read FNome write FNome;
    property Cep: string read FCep write FCep;
    property CpfCnpj: string read FCpfCnpj write FCpfCnpj;
    property Endereco: string read FEndereco write FEndereco;
    property Numero: string read FNumero write FNumero;
    property Complemento: string read FComplemento write FComplemento;
    property Bairro: string read FBairro write FBairro;
    property CidadeId: Integer read FCidadeId write FCidadeId;
    property DataNascimento: TDateTime read FDataNascimento write FDataNascimento;
    property NomeCidade: string read FNomeCidade write FNomeCidade;
    property Uf: string read FUf write FUf;
    property NomeEstado: string read FNomeEstado write FNomeEstado;

    function EhNovo: Boolean;

    function EhPessoaJuridica: Boolean;
  end;

implementation

uses
  System.SysUtils;

constructor TCliente.Create;
begin
  inherited Create;
  FId := 0;
  FCidadeId := 0;
  FDataNascimento := 0;
end;

procedure TCliente.Assign(ASource: TCliente);
begin
  if ASource = nil then
    Exit;

  FId             := ASource.Id;
  FNome           := ASource.Nome;
  FCep            := ASource.Cep;
  FCpfCnpj        := ASource.CpfCnpj;
  FEndereco       := ASource.Endereco;
  FNumero         := ASource.Numero;
  FComplemento    := ASource.Complemento;
  FBairro         := ASource.Bairro;
  FCidadeId       := ASource.CidadeId;
  FDataNascimento := ASource.DataNascimento;
  FNomeCidade     := ASource.NomeCidade;
  FUf             := ASource.Uf;
  FNomeEstado     := ASource.NomeEstado;
end;

function TCliente.EhNovo: Boolean;
begin
  Result := FId <= 0;
end;

function TCliente.EhPessoaJuridica: Boolean;
var
  LDigitos: string;
  I: Integer;
begin
  LDigitos := '';
  for I := 1 to Length(FCpfCnpj) do
    if CharInSet(FCpfCnpj[I], ['0'..'9']) then
      LDigitos := LDigitos + FCpfCnpj[I];

  Result := Length(LDigitos) = 14;
end;

end.
