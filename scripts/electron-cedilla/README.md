# Wayland cedilla fix para Electron

Faz `' + c` produzir `ç` (e `' + C` → `Ç`) em apps Electron no Wayland nativo
(no caso deste setup: **Visual Studio Code** via `visual-studio-code-electron-bin`).

Adaptado de [chromium-wayland-cedilla-fix](https://github.com/lcassa/chromium-wayland-cedilla-fix).

## O problema

No layout US-International, `'` é dead key (`dead_acute`). Em Wayland nativo,
Chromium/Electron ignora `~/.XCompose` e usa a tabela de compose compilada no
binário (`ui::CharacterComposer`), que mapeia `dead_acute + c → ć`. Bug aberto:
[crbug 40272818](https://issues.chromium.org/issues/40272818).

O pacote `visual-studio-code-electron-bin` **não tem Chromium embutido** — ele
roda sobre o Electron do sistema (shebang `#!/usr/bin/electron42`). Portanto o
alvo do patch é o binário do pacote `electron42`:

```text
/usr/lib/electron42/electron
```

Isso corrige o ç em todos os apps que usam esse Electron.

## Como funciona

A tabela de compose guarda entradas como `[input uint16 LE][output uint16 LE]`.
O patch troca **apenas** a saída de `c`/`C`:

```text
c (0x0063) -> ć (0x0107):  63 00 07 01  =>  63 00 e7 00  (ç U+00E7)
C (0x0043) -> Ć (0x0106):  43 00 06 01  =>  43 00 c7 00  (Ç U+00C7)
```

- Matching por **padrão de bytes** (não offset), então sobrevive a novas versões.
- O binário tem 3 cópias da tabela; as 3 são patcheadas.
- Idempotente: rodar de novo não faz nada.
- Cria `electron.orig` (original intacto, uma vez) e um `electron.bak-<data>` por execução.
- Se o padrão não bater (formato mudou), o script **não altera nada** e sai com aviso.

Consequência: `' + c` não produz mais `ć`/`Ć` no Electron.

## Uso

Aplicar agora:

```bash
sudo python3 scripts/electron-cedilla/electron-cedilla-patch.py
```

Depois feche o VS Code completamente (processo inteiro, não só a janela) e teste `' + c`.

### Persistir entre upgrades

O binário é sobrescrito a cada upgrade de `electron42`. Para reaplicar
automaticamente, instale o hook do pacman (o `Exec` chama o script instalado em
`/usr/local/bin`):

```bash
sudo install -Dm755 scripts/electron-cedilla/electron-cedilla-patch.py /usr/local/bin/
sudo install -Dm644 scripts/electron-cedilla/electron-cedilla.hook /etc/pacman.d/hooks/electron42-cedilla.hook
sudo python3 /usr/local/bin/electron-cedilla-patch.py /usr/lib/electron42/electron
```

O hook dispara em `Install`/`Upgrade` de `electron42` (`PostTransaction`).

### Verificar

```bash
python3 /usr/local/bin/electron-cedilla-patch.py /usr/lib/electron42/electron
# → "[ok] already patched (nothing to do)."
```

### Desfazer

```bash
sudo rm /etc/pacman.d/hooks/electron42-cedilla.hook /usr/local/bin/electron-cedilla-patch.py
sudo pacman -S electron42
```

Reinstalar o pacote é a reversão segura após upgrades: o backup `.orig` só é
confiável para a versão na qual foi criado — após um upgrade, `electron.orig`
contém o binário da versão anterior (sem uso). O script recria o `.orig`
automaticamente quando detecta que o binário mudou e, de qualquer forma,
grava um `electron.bak-<data>` do binário atual antes de cada patch.
Para reverter imediatamente (mesma versão, antes de qualquer upgrade):

```bash
sudo cp -a /usr/lib/electron42/electron.orig /usr/lib/electron42/electron
```

## Arquivos

- `electron-cedilla-patch.py` — script de patch (idempotente, com backups).
- `electron-cedilla.hook` — hook do pacman para reaplicar após upgrades de `electron42`.
