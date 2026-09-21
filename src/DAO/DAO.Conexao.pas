unit DAO.Conexao;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IniFiles,
  System.IOUtils,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.Phys,
  FireDAC.Phys.Intf,
  FireDAC.Phys.FB,
  FireDAC.Phys.FBDef,
  FireDAC.UI.Intf,
  FireDAC.DApt,
  FireDAC.Comp.Client;

type
  EConexaoBanco = class(Exception);

  TConexao = class
  private
    FConnection: TFDConnection;
    FTransacao: TFDTransaction;
    FDriverLink: TFDPhysFBDriverLink;
    FCaminhoBanco: string;
    FCaminhoClientDLL: string;

    FGravacaoEmAndamento: Boolean;

    procedure CarregarConfiguracao;
    procedure ConfigurarDriver;
    procedure ConfigurarConexao;
    constructor CriarInterno;
  public
    destructor Destroy; override;

    class function Obter: TConexao;
    class procedure Liberar;

    procedure Conectar;
    procedure Desconectar;
    function Conectado: Boolean;

    procedure IniciarTransacao;
    procedure Confirmar;
    procedure Desfazer;
    function EmTransacao: Boolean;

    procedure EncerrarLeitura;

    function NovaQuery: TFDQuery;

    property Connection: TFDConnection read FConnection;
    property CaminhoBanco: string read FCaminhoBanco;
  end;

implementation

var
  FInstancia: TConexao = nil;

class function TConexao.Obter: TConexao;
begin
  if FInstancia = nil then
  begin
    FInstancia := TConexao.CriarInterno;
    FInstancia.Conectar;
  end;
  Result := FInstancia;
end;

class procedure TConexao.Liberar;
begin
  FreeAndNil(FInstancia);
end;

constructor TConexao.CriarInterno;
begin
  inherited Create;

  FGravacaoEmAndamento := False;

  FDriverLink := TFDPhysFBDriverLink.Create(nil);

  FConnection := TFDConnection.Create(nil);
  FTransacao  := TFDTransaction.Create(nil);

  CarregarConfiguracao;
  ConfigurarDriver;
  ConfigurarConexao;
end;

destructor TConexao.Destroy;
begin
  if Assigned(FConnection) and FConnection.Connected then
  begin
    if FTransacao.Active then
      FTransacao.Rollback;
    FConnection.Connected := False;
  end;

  FreeAndNil(FTransacao);
  FreeAndNil(FConnection);
  FreeAndNil(FDriverLink);

  inherited Destroy;
end;

procedure TConexao.CarregarConfiguracao;
var
  LIni: TIniFile;
  LPastaApp: string;
  LArquivoIni: string;
begin
  LPastaApp := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  LArquivoIni := LPastaApp + 'ControleClientes.ini';

  FCaminhoBanco     := LPastaApp + 'banco\CONTROLECLIENTES.FDB';
  FCaminhoClientDLL := LPastaApp + 'firebird\fbclient.dll';

  if FileExists(LArquivoIni) then
  begin
    LIni := TIniFile.Create(LArquivoIni);
    try
      FCaminhoBanco     := LIni.ReadString('BANCO', 'Database', FCaminhoBanco);
      FCaminhoClientDLL := LIni.ReadString('BANCO', 'VendorLib', FCaminhoClientDLL);

      if TPath.IsRelativePath(FCaminhoBanco) then
        FCaminhoBanco := LPastaApp + FCaminhoBanco;
      if TPath.IsRelativePath(FCaminhoClientDLL) then
        FCaminhoClientDLL := LPastaApp + FCaminhoClientDLL;
    finally
      LIni.Free;
    end;
  end;
end;

procedure TConexao.ConfigurarDriver;
begin
  FDriverLink.DriverID := 'FB';

  if FileExists(FCaminhoClientDLL) then
    FDriverLink.VendorLib := FCaminhoClientDLL;
end;

procedure TConexao.ConfigurarConexao;
begin
  FTransacao.Connection := FConnection;

  FTransacao.Options.Isolation := xiReadCommitted;
  FTransacao.Options.ReadOnly  := False;
  FTransacao.Options.AutoCommit := False;
  FTransacao.Options.AutoStop   := False;
  FTransacao.Options.AutoStart  := False;

  FTransacao.Options.Params.Clear;
  FTransacao.Options.Params.Add('no_auto_undo');

  FConnection.Transaction       := FTransacao;
  FConnection.UpdateTransaction := FTransacao;

  FConnection.LoginPrompt := False;

  FConnection.Params.Clear;
  FConnection.Params.DriverID  := 'FB';
  FConnection.Params.Database  := FCaminhoBanco;
  FConnection.Params.UserName  := 'SYSDBA';
  FConnection.Params.Password  := 'masterkey';
  FConnection.Params.Add('CharacterSet=UTF8');

  end;

procedure TConexao.Conectar;
begin
  if FConnection.Connected then
    Exit;

  if not FileExists(FCaminhoBanco) then
    raise EConexaoBanco.CreateFmt(
      'Banco de dados nao encontrado em:' + sLineBreak + '%s' + sLineBreak + sLineBreak +
      'Confira o caminho no arquivo ControleClientes.ini.', [FCaminhoBanco]);

  try
    FConnection.Connected := True;
  except
    on E: Exception do
      raise EConexaoBanco.CreateFmt(
        'Nao foi possivel conectar ao banco de dados.' + sLineBreak + sLineBreak +
        'Banco : %s' + sLineBreak +
        'Client: %s' + sLineBreak + sLineBreak +
        'Erro  : %s', [FCaminhoBanco, FCaminhoClientDLL, E.Message]);
  end;
end;

procedure TConexao.Desconectar;
begin
  if FTransacao.Active then
    FTransacao.Rollback;
  FConnection.Connected := False;
end;

function TConexao.Conectado: Boolean;
begin
  Result := Assigned(FConnection) and FConnection.Connected;
end;

procedure TConexao.IniciarTransacao;
begin
  Conectar;

   if FTransacao.Active and not FGravacaoEmAndamento then
    FTransacao.Commit;

  if not FTransacao.Active then
    FTransacao.StartTransaction;

  FGravacaoEmAndamento := True;
end;

procedure TConexao.Confirmar;
begin
  if FTransacao.Active then
    FTransacao.Commit;
  FGravacaoEmAndamento := False;
end;

procedure TConexao.Desfazer;
begin
  if FTransacao.Active then
    FTransacao.Rollback;
  FGravacaoEmAndamento := False;
end;

procedure TConexao.EncerrarLeitura;
begin
  if FGravacaoEmAndamento then
    Exit;

  if Assigned(FTransacao) and FTransacao.Active then
    FTransacao.Commit;
end;

function TConexao.EmTransacao: Boolean;
begin
  Result := Assigned(FTransacao) and FTransacao.Active;
end;

function TConexao.NovaQuery: TFDQuery;
begin
  Conectar;

   if not FTransacao.Active then
    FTransacao.StartTransaction;

  Result := TFDQuery.Create(nil);
  Result.Connection := FConnection;
  Result.Transaction := FTransacao;
end;

initialization

finalization
  TConexao.Liberar;

end.
