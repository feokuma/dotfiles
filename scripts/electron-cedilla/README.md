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
alvo do patch é o binário do pacote `electronNN`:

```text
/usr/lib/electronNN/electron
```

A versão é resolvida dinamicamente por glob (`/usr/lib/electron*/electron`),
então upgrades (electron42 → electron43...) continuam funcionando sem ajustes.

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

### Instalar (aplica + persiste entre upgrades) — via script

```bash
sudo ./scripts/electron-cedilla/install.sh
```

O script instala o patch em `/usr/local/bin`, o hook em `/etc/pacman.d/hooks/electron-cedilla.hook`
e aplica o patch a todos os `/usr/lib/electron*/electron`. O hook usa o glob
`Target = electron*`, que continua válido nas próximas atualizações versão (electron42 → electron43...).
Nada precisa ser ajustado quando o Electron sobe de versão — o hook reaplica
o patch automaticamente no post-transaction do pacman.

### Verificar

```bash
python3 /usr/local/bin/electron-cedilla-patch.py /usr/lib/electron43/electron
# → "[ok] already patched (nothing to do)."
```

### Desfazer — via script

```bash
sudo ./scripts/electron-cedilla/uninstall.sh
```

Ele remove hook e script. Reversão segura do binário:

Reinstalar o pacote é a reversão segura após upgrades: o backup `.orig` só é
confiável para a versão na qual foi criado — após um upgrade, `electron.orig`
contém o binário da versão anterior (sem uso). O script recria o `.orig`
automaticamente quando detecta que o binário mudou e, de qualquer forma,
grava um `electron.bak-<data>` do binário atual antes de cada patch.
Para reverter imediatamente (mesma versão, antes de qualquer upgrade):

```bash
sudo cp -a /usr/lib/electronNN/electron.orig /usr/lib/electronNN/electron
```

## Arquivos

- `electron-cedilla-patch.py` — script de patch (idempotente, com backups; detecta todas as versões instaladas via glob).
- `electron-cedilla.hook` — hook do pacman (`Target = electron*`) para reaplicar após upgrades.
- `install.sh` / `uninstall.sh` — instalador/desinstalador (resolvem as versões dinamicamente).
- `LICENSE` — MIT, do projeto upstream [chromium-wayland-cedilla-fix](https://github.com/lcassa/chromium-wayland-cedilla-fix), do qual este script é derivado.
