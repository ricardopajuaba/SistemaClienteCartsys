program ControleClientes;

{ ============================================================================
  Programa principal.

  POR QUE FireDAC.VCLUI.Wait APARECE AQUI E NAO EM DAO.Conexao?

  O FireDAC exige que a aplicacao registre um "wait cursor" - sem isso o
  primeiro Open levanta:

      Object factory for class ... missing

  (a mensagem real traz o GUID da classe no lugar das reticencias; ele nao
   pode ser escrito aqui entre chaves porque a chave de fechamento encerraria
   este proprio comentario - ver CONTEXTO.md, secao 5.7)

  Quem registra e justamente a unit de espera. Existem duas:

      FireDAC.VCLUI.Wait      - aplicacao com formulario
      FireDAC.ConsoleUI.Wait  - aplicacao de console

  Se DAO.Conexao declarasse a versao VCL, a camada de dados passaria a
  depender da interface grafica e os testes de console nao compilariam mais.
  Entao a escolha fica aqui, no .dpr, que e o unico lugar do projeto que
  realmente sabe que tipo de aplicacao esta sendo montada. O programa de
  testes em tests\TesteCamadas.dpr declara a variante de console.

  PLATAFORMA
  Compilar em Win32. O Firebird embedded distribuido em bin\firebird e de 32
  bits, e o processo precisa carregar a fbclient.dll da mesma arquitetura.
  ============================================================================ }

uses
  Vcl.Forms,
  Vcl.Dialogs,
  System.SysUtils,
  System.UITypes,
  FireDAC.VCLUI.Wait,
  DAO.Conexao in 'src\DAO\DAO.Conexao.pas',
  DAO.Cliente in 'src\DAO\DAO.Cliente.pas',
  DAO.Cidade in 'src\DAO\DAO.Cidade.pas',
  DAO.Estado in 'src\DAO\DAO.Estado.pas',
  Model.Entity.Cliente in 'src\Model\Model.Entity.Cliente.pas',
  Model.Entity.Cidade in 'src\Model\Model.Entity.Cidade.pas',
  Model.Entity.Estado in 'src\Model\Model.Entity.Estado.pas',
  Service.Documento in 'src\Service\Service.Documento.pas',
  Service.ViaCep in 'src\Service\Service.ViaCep.pas',
  Service.Texto in 'src\Service\Service.Texto.pas',
  Service.RegrasCliente in 'src\Service\Service.RegrasCliente.pas',
  Service.EnterTab in 'src\Service\Service.EnterTab.pas',
  Controller.Cliente in 'src\Controller\Controller.Cliente.pas',
  View.Principal in 'src\View\View.Principal.pas' {frmPrincipal},
  View.ClientePesquisa in 'src\View\View.ClientePesquisa.pas' {frmClientePesquisa},
  View.Cliente in 'src\View\View.Cliente.pas' {frmCliente},
  View.Relatorio in 'src\View\View.Relatorio.pas' {frmRelatorio};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Controle de Clientes';

  { Conectar antes de abrir a tela transforma "banco nao encontrado" numa
    mensagem clara, em vez de um erro no meio do primeiro cadastro. A conexao
    e singleton: a partir daqui todo mundo usa a mesma. }
  try
    TConexao.Obter;
  except
    on E: Exception do
    begin
      MessageDlg(E.Message, mtError, [mbOk], 0);
      Exit;
    end;
  end;

  { Somente a tela principal e criada aqui. As demais nascem e morrem conforme
    o usuario pede - ver o comentario em View.Principal. }
  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.Run;
end.
