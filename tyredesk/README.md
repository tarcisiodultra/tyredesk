# TyreDesk

Aplicativo Windows baseado no RustDesk **1.5.0**, sem conta, assinatura ou ativacao.
O usuario usa **ID + senha fixa**, ve a tela, controla o mouse e salva favoritos
locais. A senha e cadastrada no computador, nunca no codigo ou no instalador.

## O que foi implementado

- Identidade TyreDesk e configuracoes separadas das instalacoes RustDesk existentes.
- Modo `approve-mode=password` e `verification-method=use-permanent-password`:
  sem aceite local e sem senha temporaria. Sem senha fixa configurada, nao ha
  autenticacao remota por senha disponivel. A validacao permanece a do RustDesk.
- Contas, catalogo online e grupos desativados; recentes e favoritos preservados.
- Botao para definir a senha na tela inicial, usando o dialogo seguro original.
- TCP hole punching habilitado: tentativa direta por ID com relay de fallback.
- Atualizacao automatica upstream desativada para nao substituir o TyreDesk.
- Workflow Windows x64, empacotamento portatil e compose do servidor OSS.

Os avisos de autoria e a AGPL permanecem. Nao foi alterado o verificador de
clientes comerciais nem implementado qualquer mecanismo de ativacao.

## Servidores de conexão

Por padrão, o TyreDesk usa os servidores públicos do RustDesk: o ID é registrado
na infraestrutura pública e o cliente tenta uma conexão direta entre os PCs,
usando relay quando necessário. Não precisa criar uma VM, informar endereço ou
chave de servidor. Os usuários não fazem login no aplicativo.

Essa infraestrutura é operada por terceiros, então disponibilidade, limites e
políticas não ficam sob controle da Tyresoles. Para ter controle próprio, o
workflow também permite compilar com um servidor RustDesk OSS, sem licença Pro.
Nesse caso, escolha `custom` e informe o IPv4/DNS e a chave pública do servidor.
É possível trocar para o servidor Oracle depois sem alterar o protocolo do app.

## Compilar o aplicativo

O repositorio Git do aplicativo e esta pasta (`rustdesk/` no workspace).
O workflow `.github/workflows/tyredesk-windows.yml` usa os compiladores do
GitHub Actions, sem precisar instala-los no computador do usuario.

1. Disponibilize este repositorio modificado em uma conta GitHub autorizada,
   incluindo o submodulo `libs/hbb_common` fixado pelo upstream.
2. Execute manualmente **TyreDesk Windows**. Mantenha `server_mode` como `public`
   para usar os servidores públicos do RustDesk. Ao migrar para Oracle, selecione
   `custom` e informe `server` e `server_key` (o conteúdo de `id_ed25519.pub`).
   Nunca informe a senha remota no workflow.
3. Baixe `TyreDesk-windows-x64` e `TyreDesk-source`. O primeiro contem o EXE
   portatil, ZIP com os arquivos do programa e checksums SHA-256. Distribua
   tambem o codigo-fonte correspondente e preserve os avisos legais.

O workflow usa somente artifacts, nao publica releases nem exige certificado
de assinatura. GitHub Actions tambem tem condicoes e cotas conforme a conta.
O EXE sem assinatura pode mostrar o aviso do Windows SmartScreen.

Compilacao local: prepare Visual Studio 2022 C++ com SDK Windows, Rust 1.75,
Flutter 3.24.5, LLVM 15.0.6, Python, CMake e o vcpkg da revisao usada no workflow.
Gere a ponte Rust/Flutter conforme `.github/workflows/tyredesk-bridge.yml`.
Depois:

```powershell
python tyredesk/configure.py --server SEU_IP_OU_DNS --key-file C:\caminho\id_ed25519.pub
./tyredesk/build-windows.ps1
```

Sem configuração de compilação, o perfil usa os servidores públicos do RustDesk.
Para um servidor próprio, configure o build ou ajuste **Configurações > Rede**
nos dois computadores.

## Conexao direta: o que funciona e o que depende da rede

**Por ID:** o servidor hbbs localiza os pares e coordena TCP hole punching.
Quando a negociacao direta funciona, tela e comandos trafegam entre os PCs.
Quando falha (por exemplo, NAT simetrico ou firewall restritivo), hbbr retransmite
a conexao criptografada. Nao marcamos a opcao "Sempre usar retransmissor".

**Por IP:** o RustDesk tambem permite habilitar "Acesso direto por IP" no destino
e conectar a IP:21118, sem hbbs. Funciona em LAN, VPN ou endereco roteavel com
firewall adequado. Isso nao substitui o encontro por ID entre redes arbitrarias.
Fica desativado por padrao; nao abrimos portas do roteador automaticamente.

Mantemos as opcoes avancadas UDP/IPv6/WebRTC nos defaults upstream para servidor
OSS: elas nao sao habilitadas indiscriminadamente sem confirmar o suporte do
servidor. O caminho TCP direto e o fallback relay sao os caminhos previstos.

Diagnostico de portas (nao comprova P2P sozinho):

```powershell
./tyredesk/Test-Connection.ps1 -Server SEU_IP_OU_DNS
./tyredesk/Test-Connection.ps1 -Server SEU_IP_OU_DNS -DirectAddress IP_DO_PC
```

## Validacao de entrega

Automatica: `python -m unittest discover -s tyredesk -p 'test_*.py' -v`.
O workflow compila o app e executa o teste Rust do perfil de autenticacao.

Antes de distribuir, validar em duas maquinas Windows:

- Sem senha configurada: conexao nao pode autorizar acesso.
- Senha correta: conexao sem aceite; senha incorreta: rejeicao.
- Mesmo segredo em dois PCs: IDs distintos, acesso a cada um pelo proprio ID.
- Favoritar e renomear: persistem apos fechar e reabrir.
- Instalar o servico, reiniciar e testar acesso sem alguem abrir a janela.
- Testar tela, cliques, arrastar, varios monitores e escalas diferentes.
- Redes diferentes: verificar no indicador/log da sessao se usou direto ou relay.
- Forcar relay no cliente para verificar fallback; depois desfazer essa opcao.
- Parar hbbr: em redes compativeis, uma nova conexao P2P deve funcionar com hbbs ativo.
- Confirmar falha clara quando nao ha caminho direto e hbbr esta indisponivel.

**Estado atual:** codigo e configuracao preparados; ainda sem EXE compilado,
sem servidor provisionado e sem teste real entre dois computadores.

## Superficie de alteracao

`src/lib.rs` e `src/core_main.rs`: registram e inicializam o perfil Windows antes
de carregar configuracoes. `src/tyredesk.rs` concentra a politica da distribuicao.
`flutter/lib/common.dart`: marca visual somente quando o app se chama TyreDesk.
`desktop_home_page.dart`: acesso direto ao cadastro de senha fixa nesse perfil.
`Runner.rc` e `libs/portable/Cargo.toml`: metadados dos executaveis.
Nao alteramos captura, entrada de mouse, protocolo, criptografia ou favoritos.

Referencias: https://github.com/rustdesk/rustdesk e
https://rustdesk.com/docs/en/self-host/rustdesk-server-oss/
