# .dotfiles

Configurações pessoais do **Arch Linux** com **Hyprland** como compositor Wayland.

Repositório minimalista e modular, organizado por contexto. A ideia é evoluir o
desktop de forma incremental, sem importar "rices" prontos nem ambientes
completos.

## Stack

| Componente | Escolha |
| --- | --- |
| Compositor | Hyprland (configuração em **Lua**) |
| Shell gráfico | Quickshell (QML em `.config/quickshell/`) |
| Editor | Neovim + LazyVim (`.config/nvim/`, com LSP QML) |
| Terminal | Ghostty |
| Shell | Zsh + Starship |
| Prompt | Starship (paleta Catppuccin Mocha) |
| Compose | XCompose (`ç`/`Ç` com `dead_acute`) |
| Teclado | Layout `us` + variante `intl` |

Programas padrão do Hyprland (`hypr/.config/hypr/programs.lua`):

| Papel | Programa |
| --- | --- |
| Terminal | ghostty |
| Navegador | firefox |
| Arquivos | dolphin |
| Launcher | hyprlauncher |

## Estrutura

Layout compatível com [GNU Stow](https://www.gnu.org/software/stow/): cada
pasta de primeiro nível é um pacote instalado a partir de `$HOME`.

```text
.
├── README.md
├── AGENTS.md          # diretrizes do projeto (leitura recomendada)
├── hypr/              # Hyprland em Lua modular (.config/hypr/*.lua)
├── quickshell/        # shell gráfico (.config/quickshell/shell.qml)
├── nvim/              # Neovim + LazyVim (.config/nvim/)
├── ghostty/           # terminal (.config/ghostty/config)
├── zsh/               # shell interativo (.zshrc)
├── starship/          # prompt (.config/starship.toml)
└── xcompose/          # tecla compose (.XCompose)
```

O módulo `hypr` é dividido por responsabilidade (`hyprland.lua` orquestra,
cada arquivo cuida de uma parte: `monitors`, `input`, `environment`,
`look-and-feel`, `windows-and-workspaces`, `keybindings`, `autostart`,
`programs`, `permissions`, `misc`).

## Pré-requisitos

- Arch Linux
- Hyprland
- Quickshell (`quickshell` via AUR/yay) + Qt6 (`qt6-declarative` traz
  `qmlls`, `qmlformat`, `qmllint` em `/usr/lib/qt6/bin/`)
- Neovim (`neovim`, `ripgrep`; opcional `fd`)
- Lua: `lua-language-server`, `stylua` (via Mason no Neovim ou via pacman)
- Ghostty
- Zsh, Starship
- Plugins do Zsh: `zsh-autosuggestions`, `zsh-syntax-highlighting`
- `eza` (aliases de `ls` no `.zshrc`)
- Numeros (opção): `wpctl` (PipeWire) e `brightnessctl` (teclas de mídia no Hyprland)
- `wpctl` (PipeWire) e `brightnessctl` (teclas de mídia no Hyprland)
- **`power-profiles-daemon`** — perfis de energia (`performance`, `balanced`,
  `power-saver`) usados pelo componente de bateria da barra Quickshell: a
  barra lê/troca o perfil via `busctl` (D-Bus do daemon), sem CLI adicional.
  Ativar com: `sudo systemctl enable --now power-profiles-daemon`
- **`gnome-themes-extra`** — fornece o tema `Adwaita-dark` usado pelo
  GTK3 (incl. `xdg-desktop-portal-gtk`, responsável pelos diálogos de
  arquivo do Chrome/Chrome-based apps). Sem este pacote, o GTK não
  encontra `Adwaita-dark` e cai no tema claro padrão, mesmo com
  `prefer-dark` no gsettings
- `stow` (para instalar os pacotes)
- **`mise`** (repositório oficial do Arch) — gerenciador de versões de
  ferramentas de desenvolvimento (ex.: `dotnet`). Ativado no `.zshrc`
  via `eval "$(mise activate zsh)"`, que coloca os shims no `PATH` por
  sessão. Versões ficam em `~/.config/mise/config.toml` (global) ou em
  `.mise.toml` / `.tool-versions` por projeto; veja [Gerenciamento de
  versões (mise)](#gerenciamento-de-versões-mise).
- **VS Code**: instalar `visual-studio-code-electron-bin` (AUR, via `yay`).
  Usa o Electron do sistema (`electron42`) em vez do Chromium empacotado
  da Microsoft, o que facilita aplicar o workaround da cedilha (ç)
  com o `.XCompose` deste repositório — abrimos via `code .`, com o app
  lançado detached pelo alias `code` do zsh.

## Instalação

Clone para `~/.dotfiles` e ative os pacotes que quiser:

```bash
git clone <este-repo> ~/.dotfiles
cd ~/.dotfiles
stow hypr gtk quickshell nvim ghostty zsh starship xcompose
```

Para ativar só um contexto:

```bash
stow hypr
```

Depois de alterar a configuração do Hyprland, recarregue com:

```bash
hyprctl reload
```

## Gerenciamento de versões (mise)

Versões de ferramentas de desenvolvimento são gerenciadas com
[`mise`](https://mise.jdx.dev/) em vez de pacotes do pacman/AUR. Hoje o
uso principal é o **.NET SDK**, mas a ideia é centralizar futuras
ferramentas (Node, Python, Go, etc.) nele também.

- **Instalação**: pacote `mise` dos repositórios oficiais do Arch
  (`sudo pacman -S mise`).
- **Ativação no shell**: uma única linha no fim do `.zshrc`:

  ```zsh
  eval "$(mise activate zsh)"
  ```

  O `activate` injeta os shims no `PATH` da sessão, então `dotnet`,
  `node` etc. apontam para a versão definida pelo mise, e a versão é
  trocada automaticamente ao entrar em um diretório com arquivo de
  config do mise.

- **Configuração**: as versões ficam nos arquivos do mise, não no
  repositório de dotfiles:
  - `~/.config/mise/config.toml` — versões globais;
  - `.mise.toml` / `.tool-versions` na raiz de um projeto — versões
    por projeto.

- **Uso básico**:

  ```bash
  mise ls                 # ferramentas instaladas
  mise use -g dotnet@10   # define a versão global (grava no config.toml)
  mise use dotnet@9       # define a versão só para o diretório atual
  mise install            # instala as versões declaradas nos configs
  mise upgrade            # atualiza as ferramentas gerenciadas
  ```

Ferramentas gerenciadas pelo mise **não** devem ser instaladas em
paralelo via pacman/AUR, para evitar dois `dotnet`/`node` conflitantes
no `PATH`.

## Neovim + Quickshell

O pacote `nvim/` é um LazyVim minimalista com suporte a QML/Quickshell:

- Treesitter `qmljs` para highlight (`:TSInstall qmljs` já coberto via
  `ensure_installed`).
- LSP `qmlls -E -I /usr/lib/qt6/qml` com `root_markers`
  `.qmlls.ini`, `shell.qml`, `.git` (segue a
  [doc oficial](https://quickshell.org/docs/guide/install-setup)).
  No Arch o binário pode ser `qmlls6` ou `/usr/lib/qt6/bin/qmlls`;
  a config detecta automaticamente.
- Formatação com `qmlformat` via conform.nvim.
- Lint complementar com `qmllint` via nvim-lint + atalho `<leader>qc`.
- Atalhos:
  - `<leader>qs` — roda `qs -p <raiz-do-shell>` num terminal.
  - `<leader>qc` — roda `qmllint` no arquivo atual.

Na primeira execução do `qs`, ele gera `.qmlls.ini` ao lado de
`shell.qml` com paths da máquina — o arquivo já está no `.gitignore`
e não deve ser commitado.

Pacotes do Arch usados pelo editor (todos em repositório oficial,
instalação manual com aprovação):

```bash
sudo pacman -S neovim ripgrep fd lua-language-server stylua qt6-declarative
```

## Atalhos principais (`SUPER` = tecla Windows)

| Atalho | Ação |
| --- | --- |
| `SUPER + Q` | Terminal |
| `SUPER + B` | Navegador |
| `SUPER + E` | Gerenciador de arquivos |
| `SUPER + R` | Launcher |
| `SUPER + C` | Fechar janela |
| `SUPER + V` | Alternar flutuante |
| `SUPER + 1..0` | Ir para o workspace |
| `SUPER + SHIFT + 1..0` | Mover janela para o workspace |
| `SUPER + S` | Workspace especial (scratchpad) |
| Teclas de mídia | Volume via `wpctl`, brilho via `brightnessctl` |

## Notas

- Detalhes de arquitetura, convenções e roadmap estão em [`AGENTS.md`](AGENTS.md).
- Mudanças fora de `$HOME` (pacotes, serviços, `/etc`, greetd, Snapper,
  bootloader, Btrfs) são sempre manuais e com aprovação explícita.
- O diretório é versionado em Git; commits seguem o padrão
  gitmoji + escopo (`📝 docs: ...`, `🔧 hypr: ...`).
