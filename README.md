# .dotfiles

Configurações pessoais do **Arch Linux** com **Hyprland** como compositor Wayland.

Repositório minimalista e modular, organizado por contexto. A ideia é evoluir o
desktop de forma incremental, sem importar "rices" prontos nem ambientes
completos.

## Stack

| Componente | Escolha |
| --- | --- |
| Compositor | Hyprland (configuração em **Lua**) |
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
stow hypr ghostty zsh starship xcompose
```

Para ativar só um contexto:

```bash
stow hypr
```

Depois de alterar a configuração do Hyprland, recarregue com:

```bash
hyprctl reload
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
