# Zsh Professional · Fedora

**Versão:** 2.0.0

## Sobre este projeto

Este é um ambiente Zsh modular, sem framework, pensado especificamente para o dia a dia de quem desenvolve **PHP/Laravel no Fedora**. A configuração é minimalista: cada módulo tem um propósito claro, sem dependências de Oh My Zsh, zplug ou qualquer outro gerenciador de plugins.

### Para quem é esta configuração

- Quem usa **Fedora** como sistema operacional principal.
- Quem utiliza o **Lerd.sh** para gerenciar versões de PHP, Composer e Node, com os shims do Lerd no `PATH`.
- Quem desenvolve projetos **Laravel** e quer atalhos rápidos para `php artisan`, testes com Pest, formatação com Pint e estática com PHPStan.
- Quem valoriza um shell responsivo, com autocomplete, sugestões automáticas, histórico local (Atuin) e navegação por diretórios (Zoxide).

### O que torna este ambiente especial

- **Zsh puro**: sem Oh My Zsh, zplug, antigen ou framework. Apenas o shell e módulos explícitos.
- **Lerd como única fonte de versões**: os shims do Lerd (`~/.local/share/lerd/bin`) têm precedência sobre qualquer instalação global de PHP, Composer ou Node. Isso significa que `php`, `composer` e `npm` seguem o que cada projeto define em `.node-version` ou `.nvmrc`.
- **Sem fnm manual**: não há `eval "$(fnm env --use-on-cd)"` na configuração. O roteamento de Node é feito pelos shims do Lerd, que já resolvem a versão por projeto.
- **Atuin com histórico próprio**: sem importação automática, sem sincronização. O histórico nativo do Zsh funciona como contingência.
- **FZF para busca**: `Ctrl+T` busca arquivos, `Alt+C` busca diretórios. O Atuin assumiu `Ctrl+R`.
- **Zoxide para navegação**: `z` navega entre diretórios com base no histórico de uso.
- **Eza no lugar do `ls`**: com `--group-directories-first` e aliases úteis.
- **Starship em duas linhas**: diretório, Git, PHP, Node, duração do último com"ando e status.
- **Configuração modular**: cada arquivo em `conf.d/` tem um número e um propósito. Para adicionar ou remover, edite `.zshrc`.
- **`.zshrc.local` preservado**: aliases e ajustes exclusivos da sua máquina não são sobrescritos por atualizações.

## O que este projeto entrega

- Zsh puro, sem Oh My Zsh, zplug ou framework.
- Lerd como primeira prioridade do `PATH`, preservando os shims de PHP, Composer e Node.
- Nenhuma inicialização manual do fnm: o roteamento de Node continua sob responsabilidade dos shims do Lerd.
- Atuin com histórico próprio, sem import automático e com sincronização desativada.
- Histórico nativo do Zsh como contingência.
- FZF para arquivos/diretórios; Atuin assume Ctrl+R.
- Zoxide para navegação por diretórios.
- Eza com aliases compatíveis.
- Autosuggestions e syntax highlighting dos pacotes Fedora.
- Starship em duas linhas, com diretório, Git, PHP, Node, duração e status do último comando.
- Configuração modular e diagnóstico/rollback.
- `.zshrc.local` preservado para aliases e ajustes exclusivos da máquina.

### Lerd.sh — o gerenciador de versões

O [Lerd](https://lerd.sh) é o meu gerenciador central de versões para PHP, Composer e Node. Os shims do Lerd (`~/.local/share/lerd/bin`) têm precedência sobre qualquer instalação global. Ao rodar `php`, `composer` ou `npm`, ele resolve automaticamente a versão do projeto (via `.node-version`, `.nvmrc`, `composer.json`). Não adicione `eval "$(fnm env --use-on-cd)"` — isso causa conflitos.

## Estrutura

```text
zsh-professional-fedora45-v3/
├── config/
│   ├── .zshenv              # PATH e variáveis de ambiente (carregado em shells não interativos)
│   ├── .zshrc               # Carrega módulos de conf.d/ em ordem
│   ├── atuin/
│   │   └── config.toml      # Configuração do Atuin (histórico local, sem sync)
│   ├── starship.toml        # Prompt Starship (duas linhas)
│   └── zsh/
│       └── conf.d/          # Módulos carregados em ordem numérica
│           ├── 00-environment.zsh   # fpath para completions do Lerd
│           ├── 10-options.zsh       # Opções do Zsh (histórico, globbing, etc.)
│           ├── 20-history.zsh       # Configuração do histórico nativo do Zsh
│           ├── 30-completion.zsh    # Sistema de completions
│           ├── 40-keybindings.zsh   # Keybindings (Emacs + terminais modernos)
│           ├── 45-autosuggestions.zsh # zsh-autosuggestions (pacote Fedora)
│           ├── 50-fzf.zsh           # FZF keybindings (Ctrl+T, Alt+C)
│           ├── 60-atuin.zsh         # Atuin init (Ctrl+R, sem up-arrow)
│           ├── 70-zoxide.zsh        # Zoxide init (comando z)
│           ├── 80-aliases.zsh       # Aliases: eza, Laravel, Git
│           ├── 85-functions.zsh     # Funções: mkcd, croot
│           ├── 90-starship.zsh      # Starship init
│           └── 99-highlighting.zsh  # zsh-syntax-highlighting (deve ser último)
├── install.sh               # Instalador (dry-run por padrão)
├── rollback.sh              # Restaura backup anterior
├── doctor.sh                # Diagnóstico completo
└── README.md
```

## Personalização

### Adicionar seus próprios aliases e ajustes

Crie `~/.zshrc.local` (o instalador **não sobrescreve** este arquivo):

```zsh
# ~/.zshrc.local
alias meu-alias='comando personalizado'
export MINHA_VARIAVEL='valor'
```

Ele é carregado **depois** de todos os módulos padrão, então você pode sobrescrever qualquer coisa.

### Desativar um módulo

Edite `~/.zshrc` e comente a linha correspondente no array `module`:

```zsh
for module in \
  00-environment \
  10-options \
  # 20-history        # <-- desativado
  30-completion \
  ...
do
```

### Adicionar um novo módulo

1. Crie `~/.config/zsh/conf.d/95-meu-modulo.zsh`
2. Adicione `95-meu-modulo` ao array `module` em `~/.zshrc` (antes do `99-highlighting`).

## Instalação

> **Importante**: Este instalador foi feito para **Fedora**. Ele instala pacotes via DNF, configura repositórios (opcionalmente o COPR `atim/starship` para o Starship) e aplica os arquivos de configuração em `~/.config/zsh/`, `~/.config/atuin/`, `~/.config/starship.toml`, `~/.zshenv` e `~/.zshrc'.

O instalador é **dry-run por padrão** — ele mostra o que faria sem alterar nada. Primeiro, extraia o ZIP (ou clone o repositório) e entre na pasta do projeto.

```bash
chmod +x install.sh rollback.sh doctor.sh
./install.sh
```

Para instalar os pacotes Fedora e aplicar as configurações:

```bash
./install.sh --apply
```

Para uma instalação completa incluindo Starship pelo COPR `atim/starship`:

```bash
./install.sh --apply --with-starship-copr
```

Para aplicar apenas as configurações, sem instalar pacotes (útil se você já tem os pacotes ou usa outro gerenciador):

```bash
./install.sh --apply --skip-packages
```

O instalador exige Fedora e deve ser executado como usuário normal. O `sudo` é usado somente para operações DNF. O backup é criado antes da instalação dos pacotes e antes de substituir qualquer destino.

### O que o instalador não faz

- Não executa `chsh`, `usermod` nem altera `/etc/passwd`.
- Não modifica `.bashrc`, `.bash_profile`, `.profile` ou o shell padrão.
- Não apaga `~/.oh-my-zsh`, `~/.zplug` ou arquivos antigos.
- Não apaga `~/.zsh_history` nem importa esse histórico para Atuin.
- Não apaga `~/.zshrc.local`.
- Não instala nem baixa fontes. O ambiente já pode usar a JetBrainsMono Nerd Font instalada no sistema.

Após instalar, abra uma sessão de teste:

```bash
zsh
```

Para sair e voltar ao shell anterior:

```bash
exit
```

## Rollback

Restaurar o backup mais recente:

```bash
./rollback.sh
```

Restaurar um backup específico:

```bash
./rollback.sh ~/.local/state/zsh-professional/backups/AAAAmmdd-HHMMSS
```

Por segurança, o rollback padrão restaura apenas os arquivos. Para solicitar a remoção dos pacotes que estavam ausentes antes da instalação:

```bash
./rollback.sh --remove-packages
```

Para também avaliar a desativação do COPR `atim/starship`, caso tenha sido habilitado por esta instalação:

```bash
./rollback.sh --restore-copr
```

As duas operações são independentes e exigem confirmação.

## Diagnóstico

```bash
./doctor.sh
```

Dentro de uma sessão Zsh, confira também a resolução dos executáveis:

```zsh
type -a php node npm npx composer lerd
php --version
node --version
npm --version
composer --version
whence -v _lerd _openchamber _copilot
atuin doctor
```

Em projetos Node, deixe o Lerd resolver a versão indicada por `.node-version` ou `.nvmrc`. Não adicione `eval "$(fnm env --use-on-cd)"` à configuração.

## Atalhos

| Tecla | Ação |
| --- | --- |
| Ctrl+R | Busca do Atuin |
| Ctrl+T | FZF para arquivos |
| Alt+C | FZF para diretórios |
| Tab | Autocompletar do Zsh |
| Seta para cima | Histórico nativo |
| Ctrl+Espaço | Aceita sugestão, se o terminal enviar esse atalho |
| Ctrl+seta esquerda/direita | Navegação por palavra |

## Aliases e funções

| Comando | Ação |
| --- | --- |
| `a` / `art` | `php artisan` |
| `pest` | `vendor/bin/pest` |
| `pint` | `vendor/bin/pint` |
| `stan` | `vendor/bin/phpstan analyse` |
| `gs` | Git status resumido |
| `gd` | Git diff |
| `gl` | Git log compacto |
| `mkcd pasta` | Cria a pasta e entra nela |
| `croot` | Vai para a raiz do repositório Git |

Os aliases que não foram incluídos devem ser migrados manualmente para `~/.zshrc.local`. O instalador preserva esse arquivo e o carrega depois dos módulos padrão.

## PATH e Lerd — como funciona na prática

A prioridade do `PATH` é deliberada e pensada para quem usa o **Lerd.sh** como gerenciador de versões:

1. `~/.local/share/lerd/bin` — **shims do Lerd** (PHP, Composer, Node). É aqui que a mágica acontece: ao rodar `php`, `composer` ou `npm`, o Lerd intercepta e resolve a versão definida no projeto (via `.node-version`, `.nvmrc`, `composer.json`, etc.).
2. `~/.local/bin` — binários locais do usuário.
3. `~/.cargo/bin` — Rust/Cargo.
4. `~/bin` — scripts pessoais.
5. Composer global, pnpm, Bun e LM Studio, quando presentes.
6. Demais diretórios herdados do sistema.

### Por que o Lerd está em primeiro lugar?

No dia a dia com Laravel, você entra em um projeto e o Lerd já sabe qual versão de PHP usar (via `composer.json` ou configuração do Lerd), qual versão de Node (via `.node-version` ou `.nvmrc`). Não há necessidade de `fnm use`, `nvm use` ou `phpenv local`. O shim do Lerd resolve tudo transparentemente.

> **Não adicione** `eval "$(fnm env --use-on-cd)"` ao seu `.zshrc.local`. O Lerd já faz esse trabalho. Adicionar fnm manualmente cria conflitos e comportamento inesperado.

O `.zshenv` é mínimo porque é carregado também em shells não interativos. Os arquivos em `config/` são a fonte da verdade. Plugins, prompt, Atuin, FZF e completions ficam no `.zshrc`.

## Histórico e segurança

### Atuin

- **Sem importação**: Atuin começa com um histórico limpo. Não há importação automática do histórico nativo do Zsh (`~/.zsh_history`).
- **Sem sync**: `auto_sync = false` no `atuin/config.toml`. Seu histórico permanece local, no `~/.local/share/atuin/history`.
- **Filtros**: `secrets_filter` e `history_filter` ajudam a evitar gravação de dados sensíveis, mas **não garantem proteção absoluta**.

### Histórico nativo do Zsh

- O Zsh mantém `~/.zsh_history` como contingência.
- `20-history.zsh` configura `HISTFILE`, `HISTSIZE`, `SAVEHIST`, `IGNORE_SPACE`, etc.

### Boas práticas

- **Nunca coloque senhas/tokens em argumentos de comando**: `git clone https://token@github.com/user/repo` aparece no histórico.
- **Prefira variáveis de ambiente**: `export DB_PASSWORD=secret`.
- **Arquivos com permissões restritas**: `.env` com `chmod 600`.
- **Gerenciadores de segredos**: `pass`, `1Password CLI`, `aws secretsmanager`, etc.

### Filtros de segurança do Atuin (defesa em profundidade)

O `atuin/config.toml` inclui filtros regex para:

- `history_filter`: tenta mascarar `password=`, `token=`, `api-key=`, `private-key=`, `export`, `setenv`, `printenv`, `kubectl get secret`, `gh auth token`, `lerd share:token`, `lerd stripe:login`, etc.
- `cwd_filter`: bloqueia `~/.ssh` e `~/.gnupg`.

> **Aviso**: filtros são **defesa em profundidade**, não uma garantia. Para segredos de alto valor, use um gerenciador de segredos dedicado.

## Validação

Os scripts Bash são validados com `bash -n`; os arquivos TOML são validados sintaticamente. A validação final da sintaxe Zsh deve ser executada no Fedora com `./doctor.sh`, pois o ambiente de empacotamento não substitui o interpretador Zsh da máquina de destino.

## Documentação oficial

- Zsh: <https://zsh.sourceforge.io/Doc/>
- Atuin: <https://docs.atuin.sh/>
- FZF: <https://github.com/junegunn/fzf>
- Zoxide: <https://github.com/ajeetdsouza/zoxide>
- Eza: <https://github.com/eza-community/eza>
- Starship: <https://starship.rs/guide/>
- zsh-autosuggestions: <https://github.com/zsh-users/zsh-autosuggestions>
- zsh-syntax-highlighting: <https://github.com/zsh-users/zsh-syntax-highlighting>
