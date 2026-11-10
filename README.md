# Zsh Professional para Fedora 45

Configuração modular para Fedora 45 com Zsh puro, Lerd + fnm, Atuin, FZF, Zoxide, Eza, Starship, autosuggestions e syntax highlighting.

## Decisões aplicadas

- Zsh puro, sem Oh My Zsh, zplug ou framework.
- Lerd gerencia PHP, Composer e Node. Não executar `fnm env` no Zsh.
- Herd Lite fica fora do PATH, mas seus arquivos não são apagados.
- Atuin começa com histórico novo. Nenhum `atuin import` é executado.
- Atuin sem sincronização e sem verificação automática de atualização.
- Eza assume os aliases `ls`, `l`, `ll`, `la` e `lt`; `/usr/bin/ls` continua disponível.
- Starship com prompt de duas linhas.
- Nenhum arquivo Bash é modificado.
- O shell padrão nunca é alterado pelo instalador.

## Instalação

O instalador é dry-run por padrão:

```bash
./install.sh
```

Para aplicar a configuração e instalar os pacotes Fedora:

```bash
./install.sh --apply --with-starship-copr
```

A opção `--with-starship-copr` habilita `atim/starship`, método indicado pela documentação oficial do Starship para Fedora 40+. Se preferir não habilitar o COPR, instale Starship por outro método oficial e execute:

```bash
./install.sh --apply --skip-packages
```

`--skip-packages` não chama DNF. Nesse caso, instale previamente as dependências.

O instalador:
1. Confere Fedora 45.
2. Cria backup datado em `~/.local/state/zsh-professional/backups/`.
3. Registra arquivos existentes e ausentes.
4. Registra os RPMs que estavam ausentes antes da instalação.
5. Instala pacotes, se solicitado.
6. Copia somente os arquivos gerenciados.
7. Não executa `chsh`, não modifica `/etc/passwd` e não altera o shell padrão.

Não importa o histórico antigo para o Atuin.

## Testar Zsh sem mudar o shell padrão

Depois da instalação:

```bash
zsh
```

Para voltar ao Bash:

```zsh
exit
```

## Validar

```bash
./doctor.sh
```

Em uma sessão Zsh, também execute:

```zsh
type -a php node npm npx composer lerd
php --version
node --version
npm --version
composer --version
atuin doctor
whence -v _lerd _openchamber _copilot
```

## Atalhos

| Tecla | Ação |
|---|---|
| Ctrl+R | Pesquisa do histórico Atuin |
| Ctrl+T | FZF: arquivos |
| Alt+C | FZF: diretórios |
| Tab | Completion do Zsh |
| Seta para cima | Histórico nativo do Zsh |
| Seta para direita | Aceitar sugestão no fim da linha |
| Ctrl+Espaço | Widget de aceitar sugestão se o terminal enviar o código esperado |

Atuin é carregado depois do FZF para assumir Ctrl+R. A seta para cima permanece convencional.

## Histórico e segurança

`config/atuin/config.toml` desativa sync, update check e captura de saída; ativa `secrets_filter`; define filtros adicionais por comando e diretório; e usa `enter_accept = false`.

Filtros não são garantia absoluta. Evite inserir tokens e senhas em argumentos de comandos. Prefira variáveis de ambiente, arquivos protegidos e gerenciadores de segredos.

O Atuin cria um histórico novo no diretório de dados padrão. O instalador não executa `atuin import`. O histórico nativo do Zsh (`~/.zsh_history`) permanece como contingência.

## Backup e rollback

Backups ficam em:

```text
~/.local/state/zsh-professional/backups/AAAAmmdd-HHMMSS/
```

Restaurar o backup mais recente:

```bash
./rollback.sh
```

Escolher um backup:

```bash
./rollback.sh ~/.local/state/zsh-professional/backups/AAAAmmdd-HHMMSS
```

Por padrão, o rollback restaura somente arquivos de configuração. Para solicitar também a remoção dos RPMs que o instalador registrou como ausentes antes da instalação:

```bash
./rollback.sh --remove-packages
```

Essa opção exige confirmação. O COPR do Starship também pode ser desabilitado se foi habilitado por esta instalação. Pacotes não são removidos por padrão.

## Arquivos preservados

Não são apagados ou modificados:
- `~/.oh-my-zsh`, `~/.zplug`
- `.bashrc`, `.bash_profile`, `.profile`
- `.zshrc.local`, `.zsh_history`
- `~/.config/herd-lite`
- dados do Lerd, fnm, OpenCode, Composer, pnpm, Cargo e LM Studio

O instalador não carrega Oh My Zsh ou zplug. Arquivos antigos ficam disponíveis para consulta e limpeza manual posterior.

## Integração técnica

### Lerd/fnm
`~/.local/share/lerd/bin` fica no início do PATH. Não se executa `fnm env` nem `fnm --use-on-cd`: os shims auditados chamam `lerd node` e `lerd npm`, que encaminham ao fnm.

### Completions
`~/.local/share/zsh/site-functions` entra no `fpath` antes de `compinit`, preservando `_lerd`, `_openchamber` e `_copilot`.

### Shell não interativo
`.zshenv` contém somente ambiente e PATH. Atuin, FZF, Starship, completions e plugins ficam no `.zshrc` interativo.

### Miyo
O link atual aponta para `/tmp/.mount_...`; não é adicionado ao PATH. É necessário um caminho estável antes de integrá-lo.

### Herd Lite
`~/.config/herd-lite/bin` é filtrado do PATH do Zsh. Seus arquivos não são apagados. `PHP_INI_SCAN_DIR` não é definido.

## Fontes oficiais
- Zsh: https://zsh.sourceforge.io/Doc/
- Atuin: https://docs.atuin.sh/
- Atuin init: https://docs.atuin.sh/main/reference/init/
- FZF: https://github.com/junegunn/fzf
- Zoxide: https://github.com/ajeetdsouza/zoxide
- Eza: https://github.com/eza-community/eza
- Starship: https://starship.rs/guide/
- Autosuggestions: https://github.com/zsh-users/zsh-autosuggestions
- Syntax highlighting: https://github.com/zsh-users/zsh-syntax-highlighting
