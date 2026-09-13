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
- `wpctl` (PipeWire) e `brightnessctl` (teclas de mídia no Hyprland)
- `stow` (para instalar os pacotes)

## Instalação

Clone para `~/.dotfiles` e ative os pacotes que quiser:

```bash
git clone <este-repo> ~/.dotfiles
cd ~/.dotfiles
stow hypr quickshell nvim ghostty zsh starship xcompose
```

Para ativar só um contexto:

```bash
stow hypr
```

Depois de alterar a configuração do Hyprland, recarregue com:

```bash
hyprctl reload
```

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
