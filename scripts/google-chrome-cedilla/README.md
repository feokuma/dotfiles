# Wayland cedilla fix — Google Chrome

Documentação análoga à de [electron-cedilla](../electron-cedilla/), mas para o
**Google Chrome** (`google-chrome`, AUR, binário em `/opt/google/chrome/chrome`).

## Estado atual: NÃO é necessário aplicar

Verificado em `google-chrome 153.0.8010.47-1` (inspeção de bytes do binário):

```text
c->ć (63 00 07 01): 0
C->Ć (43 00 06 01): 0
```

A tabela de compose embutida em `/opt/google/chrome/chrome` já contém
`c → ç`:

```text
61 00 e1 00  63 00 e7 00  65 00 e9 00  67 00 f5 01  69 00 ed 00 ...
a -> á       c -> ç       e -> é       g -> ǵ        i -> í
```

Não há nenhuma ocorrência de `63 00 07 01` (c → ć) no binário — ou seja, o
mapeamento `dead_acute + c → ç` já é o default nesta versão. O fix que motiva
[chromium-wayland-cedilla-fix](https://github.com/lcassa/chromium-wayland-cedilla-fix)
foi incorporado upstream, então `' + c` deve produzir `ç` no Chrome sem patch.

**Como verificar no dia a dia:** abra o Chrome no Wayland nativo e digite
`' + c`. Se sair `ç`, nada a fazer.

## Validação feita

```bash
python3 - <<'EOF'
data = open('/opt/google/chrome/chrome','rb').read()
print('c->ć (63 00 07 01):', data.count(b'\x63\x00\x07\x01'))   # 0
print('C->Ć (43 00 06 01):', data.count(b'\x43\x00\x06\x01'))   # 0
print('c->ç (63 00 e7 00):', data.count(b'\x63\x00\xe7\x00'))   # 8+ (4 cópias da tabela + falso positivo)
EOF
```

Nota: o script de patch **não deve ser executado** no Chrome atual.
Roda com `python3 <script> /opt/google/chrome/chrome`, ele sairia com
"[ok] already patched" (mensagem enganosa — na verdade o patch simplesmente não
se aplica porque o padrão `ć` não existe). Não altera nada, mas o feedback
correto é o do teste acima.

## Se o problema voltar (regressão numa versão futura)

Após um upgrade do `google-chrome`, verifique com o teste acima. Se
`c->ć` contasse `3+` novamente:

1. O script genérico (o mesmo do electron, que aceita o caminho como
   argumento) funciona no Chrome:

   ```bash
   sudo python3 ../electron-cedilla/electron-cedilla-patch.py /opt/google/chrome/chrome
   # instale uma vez em /usr/local/bin para o hook abaixo:
   sudo install -Dm755 ../electron-cedilla/electron-cedilla-patch.py /usr/local/bin/
   ```

2. Instale o hook deste diretório para sobreviver aos upgrades de `google-chrome`
   (updates do AUR via `yay`):

   ```bash
   sudo install -Dm644 google-chrome-cedilla.hook /etc/pacman.d/hooks/google-chrome-cedilla.hook
   ```

3. Reverter — via script:

   ```bash
   sudo ./scripts/google-chrome-cedilla/uninstall.sh
   ```

   Ele remove hook e backups, e só remove o script compartilhado se não houver
   hook do electron instalado. A reversão garantida do binário continua sendo
   reinstalar o pacote:

   O backup `.orig` é confiável apenas para a versão na qual foi criado
   (o script o recria quando o binário muda). Para reverter na mesma versão:

   ```bash
   sudo cp -a /opt/google/chrome/chrome.orig /opt/google/chrome/chrome
   ```

## Arquivos

- `install.sh` — verificação de necessidade + instalação (script compartilhado + hook) + aplicação do patch.
- `uninstall.sh` — remoção do hook/backups (script compartilhado só se não houver hook do electron).
- `README.md` — este documento (estado atual + plano de regressão).
- `google-chrome-cedilla.hook` — hook do pacman (`Target = google-chrome`),
  pronto para uso caso uma versão futura retorne o padrão `c → ć`.
- O script de patch em si vive em [`../electron-cedilla/electron-cedilla-patch.py`](../electron-cedilla/)
  e é compartilhado — aceita o caminho do binário como primeiro argumento.
