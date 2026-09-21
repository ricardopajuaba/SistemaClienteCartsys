# SistemaClienteCartsys

Aplicação desktop para **cadastro, consulta, alteração, exclusão e emissão de relatórios de clientes**, desenvolvida em **Delphi 10.3** com **VCL**.

O projeto foi organizado em camadas, separando a interface visual, o controle das operações, as regras de negócio, o acesso a dados e as entidades do domínio.

## 📌 Sobre o projeto

O **SistemaClienteCartsys** é um sistema de controle de clientes com suporte a:

- Cadastro e manutenção de clientes;
- Pesquisa por diferentes campos;
- Consulta de endereço por CEP através da API ViaCEP;
- Seleção de estado e cidade;
- Validação de CPF e CNPJ;
- Regras de negócio para inclusão, alteração e exclusão;
- Relatórios de clientes com filtros;
- Navegação entre campos utilizando a tecla `Enter`.

## 🚀 Funcionalidades

### Cadastro de clientes

O formulário de cadastro permite trabalhar com os seguintes dados:

- Nome;
- CPF/CNPJ;
- CEP;
- Endereço;
- Número;
- Complemento;
- Bairro;
- Cidade;
- Data de nascimento.

O CPF/CNPJ é armazenado somente com os dígitos, enquanto a apresentação na tela e nos relatórios utiliza formatação.

### Consulta de CEP

O sistema utiliza o serviço **ViaCEP** para consultar informações de endereço a partir do CEP.

Quando a consulta é realizada, os dados retornados podem preencher:

- Logradouro;
- Bairro;
- Cidade;
- Unidade Federativa (UF).

### Pesquisa de clientes

A tela de pesquisa disponibiliza filtros por:

- Todos;
- ID;
- Nome;
- CPF/CNPJ;
- CEP;
- Cidade;
- Estado — UF ou nome;
- Data de nascimento.

A listagem apresenta informações como ID, nome, CPF/CNPJ, CEP, endereço, número, bairro, cidade, UF e data de nascimento.

Também é possível abrir o cadastro para alteração por meio de duplo clique na linha do cliente.

### Relatórios

O sistema possui um relatório de clientes com filtros por:

- Todos os clientes;
- Faixa de ID;
- Cidade e estado.

O estado selecionado filtra as cidades disponíveis no respectivo campo. O relatório é montado dinamicamente utilizando o **ReportBuilder**, com visualização em tela, orientação paisagem e indicação do total de clientes.

## 🏗️ Arquitetura do projeto

A aplicação está organizada nas seguintes camadas:

```text
src/
├── Controller/
│   └── Controller.Cliente.pas
│
├── DAO/
│   ├── DAO.Cidade.pas
│   ├── DAO.Cliente.pas
│   ├── DAO.Conexao.pas
│   └── DAO.Estado.pas
│
├── Model/
│   ├── Model.Entity.Cidade.pas
│   ├── Model.Entity.Cliente.pas
│   └── Model.Entity.Estado.pas
│
├── Service/
│   ├── Service.Documento.pas
│   ├── Service.EnterTab.pas
│   ├── Service.RegrasCliente.pas
│   ├── Service.Texto.pas
│   └── Service.ViaCep.pas
│
└── View/
    ├── View.Cliente.dfm
    ├── View.Cliente.pas
    ├── View.ClientePesquisa.dfm
    ├── View.ClientePesquisa.pas
    ├── View.Principal.dfm
    ├── View.Principal.pas
    ├── View.Relatorio.dfm
    └── View.Relatorio.pas
```

### Controller

A camada `Controller.Cliente` coordena as operações da aplicação, incluindo:

- Pesquisa e obtenção de clientes;
- Listagem de estados e cidades;
- Preparação dos dados para relatórios;
- Salvamento e exclusão de clientes;
- Consulta e aplicação de dados obtidos pelo ViaCEP.

A camada também centraliza o tratamento das regras de negócio e o controle de transações durante operações de gravação.

### DAO — Data Access Object

Os DAOs são responsáveis pelo acesso ao banco de dados:

- `DAO.Cliente`: pesquisa, inclusão, alteração, exclusão e verificação de CPF/CNPJ em uso;
- `DAO.Cidade`: listagem e consulta de cidades;
- `DAO.Estado`: listagem e consulta de estados;
- `DAO.Conexao`: gerenciamento da conexão, queries e transações.

As consultas utilizam `TFDQuery`, fornecido pelo FireDAC.

### Model

As entidades representam os dados do domínio:

- `TCliente`;
- `TCidade`;
- `TEstado`.

A entidade `TCliente` possui métodos auxiliares, como `EhNovo`, `EhPessoaJuridica` e `Assign`.

### Service

A camada de serviços concentra funcionalidades reutilizáveis:

- `Service.Documento`: limpeza, identificação, validação e formatação de CPF/CNPJ;
- `Service.EnterTab`: permite utilizar a tecla `Enter` como navegação entre controles;
- `Service.RegrasCliente`: validações e regras de negócio relacionadas a clientes;
- `Service.Texto`: normalização e tratamento de textos, incluindo remoção de acentos;
- `Service.ViaCep`: validação, limpeza, formatação e consulta de CEP.

### View

A camada visual contém os formulários da aplicação:

- `View.Principal`: tela principal e menu do sistema;
- `View.ClientePesquisa`: pesquisa, listagem, inclusão, alteração e exclusão de clientes;
- `View.Cliente`: formulário de cadastro e edição;
- `View.Relatorio`: filtros e visualização do relatório de clientes.

## 🛠️ Tecnologias e componentes

- **Delphi 10.3**
- **Object Pascal**
- **VCL — Visual Component Library**
- **FireDAC**
- **Firebird**
- **DevExpress VCL** — componentes visuais, como grids, botões, campos e combos
- **ReportBuilder** — geração e visualização de relatórios
- **ViaCEP** — consulta de endereços por CEP

## 🗄️ Banco de dados

A aplicação utiliza o banco de dados **Firebird**.

A configuração atual do projeto procura os arquivos relativos à pasta da aplicação:

```text
banco\CONTROLECLIENTES.FDB
firebird\fbclient.dll
```

A conexão é configurada por meio da classe `TConexao`, localizada em:

```text
src/DAO/DAO.Conexao.pas
```

A classe é responsável por:

- Criar e disponibilizar a conexão;
- Configurar o driver Firebird;
- Criar consultas (`TFDQuery`);
- Iniciar transações;
- Confirmar operações;
- Desfazer operações;
- Encerrar a conexão.

> **Observação:** o arquivo do banco de dados, a DLL do cliente Firebird e eventuais scripts de criação de tabelas devem ser disponibilizados separadamente para uma instalação completa. Esses arquivos não fazem parte da estrutura de código analisada.

## ▶️ Como executar

### Pré-requisitos

- Windows;
- Delphi 10.3 ou versão compatível com o projeto;
- Componentes DevExpress VCL utilizados pelo projeto;
- FireDAC com suporte ao Firebird;
- ReportBuilder;
- Cliente Firebird (`fbclient.dll`);
- Arquivo do banco `CONTROLECLIENTES.FDB`.

### Passos

1. Clone o repositório:

   ```bash
   git clone https://github.com/ricardopajuaba/SistemaClienteCartsys.git
   ```

2. Abra o arquivo de projeto no Delphi.
3. Verifique se os componentes DevExpress e ReportBuilder estão instalados.
4. Disponibilize o banco na pasta:

   ```text
   banco\CONTROLECLIENTES.FDB
   ```

5. Disponibilize a DLL do Firebird na pasta:

   ```text
   firebird\fbclient.dll
   ```

6. Compile e execute a aplicação.

## 🔒 Regras e cuidados

- O CPF/CNPJ é normalizado para conter somente números;
- A aplicação realiza validações de documento e regras específicas de cliente;
- A exclusão solicita confirmação do usuário;
- As operações de gravação utilizam transações;
- A pesquisa preserva, quando possível, o cliente que estava selecionado na grade;
- A lista de cidades pode ser filtrada de acordo com o estado selecionado.

## 📂 Organização recomendada

Arquivos de histórico e recuperação gerados pela IDE, como as pastas `__history` e `__recovery`, não são necessários para a execução da aplicação e podem ser excluídos do versionamento caso não exista uma necessidade específica de mantê-los.

## 🎯 Objetivo do projeto

O projeto foi desenvolvido como uma aplicação prática de controle de clientes, demonstrando conhecimentos em:

- Desenvolvimento desktop com Delphi;
- Programação orientada a objetos;
- Separação de responsabilidades por camadas;
- Acesso a banco de dados;
- Tratamento de transações;
- Consumo de API HTTP;
- Validação de dados;
- Geração de relatórios;
- Construção de interfaces com componentes visuais.

## 👨‍💻 Autor

**Ricardo Pajuaba**

GitHub: [ricardopajuaba](https://github.com/ricardopajuaba)

## 🔗 Repositório

[github.com/ricardopajuaba/SistemaClienteCartsys](https://github.com/ricardopajuaba/SistemaClienteCartsys)
