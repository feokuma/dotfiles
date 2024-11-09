# Dotfiles

Este são os dotfiles gerados no Archlinux. As configuração são sincronizadas utilizando o [GNU Stow](https://www.gnu.org/software/stow/).

Antes de começar é importante que este repositório seja clonado na raiz do diretório home do seu usuário.

## Tecnologias

- [GNU Stow](https://www.gnu.org/software/stow/)

## Restaurando arquivos

Nesta sessão serão mostrados os comandos usados para restaurar os arquivos para o diretório do **user** e para os diretórios do sistema. Em todos os comandos é necessário estar na raiz do diretório Dotfiles

### Restaurando arquivos no diretório do usuário

Este processo é mais simples porque o usuário terá acesso liberado para fazer a criação dos links

```shell
stow <nome da aplicação>
```

### Restaurando arquivos em pastas do diretório de sistema

Alguns arquivos de configuração ficam em diretórios como **`/etc`** e que fica em um caminho diferente do utilizado por padrão pelo **GNU Stow** além de ser um diretório que o usuário normalmente não tem acesso. Para que seja possível fazer a criação do link corretamente, é necessário algumas mudanças no comando utilizando

```shell
sudo stow <nome da aplicação> --target=/
```

O target é necessário para que o **GNU Stow** saiba que o link não será criado na raiz do diretório do usuário, mas sim considerando o diretório raiz do sistema.
