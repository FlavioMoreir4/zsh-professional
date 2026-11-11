# Zsh Professional · Fedora

> Ambiente Zsh modular, sem framework, para quem desenvolve PHP/Laravel no Fedora: autosuggestions, syntax highlighting, histórico com Atuin, FZF, Zoxide, Eza e prompt Starship. Instalador com dry-run, backup, rollback e diagnóstico.

**Versão:** 3.1.0 · **Alvo:** Fedora 45 (GNOME/Wayland) · Histórico de mudanças em [CHANGELOG.md](CHANGELOG.md)

## Sumário

1. [O que você ganha](#o-que-você-ganha)
2. [Requisitos](#requisitos)
3. [Instalação](#instalação)
4. [Estrutura](#estrutura)
5. [Atalhos e aliases](#atalhos-e-aliases)
6. [Personalização](#personalização)
7. [Decisões e trade-offs](#decisões-e-trade-offs)
8. [Histórico e segurança](#histórico-e-segurança)
9. [Solução de problemas](#solução-de-problemas)
10. [Backup, rollback e diagnóstico](#backup-rollback-e-diagnóstico)
11. [Validação](#validação)
12. [Referências](#referências)

## O que você ganha

- **Aviso antes do Enter:** o comando fica verde se existe e vermelho se não existe (zsh-syntax-highlighting).
- **Sugestão em cinza** vinda do histórico; `→` aceita tudo, `Ctrl+→` aceita palavra por palavra (zsh-autosuggestions).
- **`Ctrl+R` com contexto:** busca por diretório, sessão e código de saída (Atuin), local, sem sync e sem import.
- **Prompt em duas linhas** (Starship): diretório, PHP/Node do projeto, branch e status do Git, duração do último comando e código de saída quando falha.
- **Navegação:** `z <nome>` (Zoxide), `Ctrl+T` arquivos e `Alt+C` diretórios (FZF).
- **Atalhos Laravel:** `a`/`art` (`php artisan`), `pest`, `pint`, `stan`.
- **Sem framework:** nada de Oh My Zsh, zplug ou antigen. Cada módulo tem um número e um propósito.
- **Lerd primeiro no `PATH`:** os shims de `php`, `composer` e `node` resolvem a versão por projeto.

## Requisitos

| Item | Requisito | Observação |
| --- | --- | --- |
| Sistema | Fedora 45 (alvo). Fedora 41+ é aceito com aviso | DNF5 é obrigatório (`--skip-unavailable`) |
| Usuário | Normal, com `sudo` | O instalador recusa rodar como root |
| Terminal | **Nerd Font** selecionada (ex.: JetBrainsMono Nerd Font) | Sem ela, ícones do Starship viram quadrados. O instalador não baixa fontes |
| Rede | Acesso aos repositórios Fedora | COPR só se usar `--with-starship-copr` |
| Lerd | Opcional | Se não existir, o `PATH` apenas ignora o diretório |

Pacotes instalados pelo DNF (somente o que a configuração usa):

| Pacote | Função |
| --- | --- |
| `zsh` | Shell |
| `zsh-autosuggestions` | Sugestão em cinza |
| `zsh-syntax-highlighting` | Verde/vermelho enquanto digita |
| `fzf` | Busca de arquivos/diretórios (precisa de `fzf --zsh`, presente nas versões atuais) |
| `zoxide` | Navegação por frequência |
| `atuin` | Histórico e `Ctrl+R` |
| `eza` | Substituto do `ls` |
| `git` | Usado por funções e pelo prompt |

O **Starship não está nos repositórios oficiais do Fedora**. Use `--with-starship-copr` (COPR `atim/starship`) ou outro método descrito em <https://starship.rs/guide/>. O COPR é de terceiros: o Fedora não o mantém.

## Instalação

```bash
git clone https://github.com/FlavioMoreir4/zsh-professional.git
cd zsh-professional
./install.sh                              # dry-run: só mostra o que faria
./install.sh --apply --with-starship-copr # instala pacotes + Starship + configuração
```

Outras formas:

```bash
./install.sh --apply                 # pacotes Fedora, sem Starship
./install.sh --apply --skip-packages # só copia arquivos (não chama DNF)
```

Depois, teste sem trocar o shell padrão:

```bash
zsh      # abre uma sessão de teste
exit     # volta ao shell anterior
```

### O que o instalador faz

1. Confere que é Fedora (>= 41) e avisa se não for o 45.
2. Cria um backup datado em `~/.local/state/zsh-professional/backups/`, com o registro dos arquivos existentes, dos pacotes já instalados e do estado do COPR.
3. Instala os pacotes base e, se pedido, o Starship. **Falha no COPR não aborta**: o restante fica instalado e o aviso explica o que fazer.
4. Copia somente os arquivos gerenciados, **um a um**. Módulos que você criar em `conf.d/` não são tocados.

### O que ele não faz

- Não executa `chsh` nem `usermod` e não altera o shell padrão.
- Não toca em `.bashrc`, `.bash_profile`, `.profile`, `~/.zshrc.local`, `~/.zsh_history`, `~/.oh-my-zsh` ou `~/.zplug`.
- Não importa histórico para o Atuin.
- Não baixa nem instala fontes.

Para tornar o Zsh o shell padrão depois de validar: `sudo usermod --shell /usr/bin/zsh "$USER"` (ou configure o Ptyxis para iniciar `zsh`).

## Estrutura

```text
zsh-professional/
├── config/
│   ├── .zshenv                    # PATH (lido também por shells não interativos)
│   ├── .zshrc                     # carrega os módulos na ordem
│   ├── atuin/config.toml          # Atuin: local, sem sync, com filtros
│   ├── starship.toml              # prompt em duas linhas
│   └── zsh/conf.d/
│       ├── 00-environment.zsh     # fpath (completions do Lerd) e cache
│       ├── 10-options.zsh         # opções do Zsh
│       ├── 20-history.zsh         # histórico nativo (contingência)
│       ├── 30-completion.zsh      # compinit e menu de completions
│       ├── 40-keybindings.zsh     # Emacs + sequências de terminais modernos
│       ├── 45-autosuggestions.zsh # plugin do Fedora + Ctrl+Espaço
│       ├── 50-fzf.zsh             # Ctrl+T, Alt+C
│       ├── 60-atuin.zsh           # Ctrl+R
│       ├── 70-zoxide.zsh          # z, zi
│       ├── 80-aliases.zsh         # eza, Laravel, Git
│       ├── 85-functions.zsh       # mkcd, croot
│       ├── 90-starship.zsh        # prompt
│       └── 99-highlighting.zsh    # SEMPRE por último (carregado após .zshrc.local)
├── install.sh · rollback.sh · doctor.sh
├── .github/workflows/ci.yml
└── CHANGELOG.md · README.md
```

`config/` é a única fonte da verdade.

## Atalhos e aliases

| Tecla | Ação |
| --- | --- |
| `Ctrl+R` | Busca do Atuin |
| `Ctrl+T` / `Alt+C` | FZF: arquivos / diretórios |
| `→` ou `End` (fim da linha) | Aceita a sugestão inteira |
| `Ctrl+→` | Aceita a sugestão palavra por palavra |
| `Ctrl+Espaço` | Aceita a sugestão, se o terminal enviar esse código |
| `↑` | Histórico nativo do Zsh |
| `Tab` | Completion com menu navegável por setas |

| Comando | Ação |
| --- | --- |
| `a`, `art` | `php artisan` |
| `pest`, `pint` | `vendor/bin/pest`, `vendor/bin/pint` |
| `stan` | `vendor/bin/phpstan analyse` |
| `gs`, `gd`, `gl` | `git status --short --branch`, `git diff`, `git log` compacto |
| `gp` | `git pull --ff-only` (**pull**, não push) |
| `gco`, `gsw` | `git checkout`, `git switch` |
| `ls`, `l`, `ll`, `la`, `lt` | `eza` (`/usr/bin/ls` continua acessível com `command ls`) |
| `mkcd pasta` | Cria e entra |
| `croot` | Vai para a raiz do repositório Git |

## Personalização

### Ajustes só da sua máquina

Crie `~/.zshrc.local`. Ele é carregado **depois** dos módulos (pode sobrescrever qualquer coisa) e **antes** do highlighting. O instalador e o rollback nunca o alteram.

```zsh
# ~/.zshrc.local
alias meu-alias='comando'
export MINHA_VARIAVEL='valor'
```

### Módulos próprios

Coloque o arquivo onde quiser e carregue-o a partir do `~/.zshrc.local`:

```zsh
source ~/.config/zsh/meu-modulo.zsh
```

(Arquivos extras dentro de `conf.d/` são ignorados porque o `.zshrc` lista os módulos explicitamente.)

### Desativar um módulo

Remova o nome da lista no `~/.zshrc`. Não comente a linha no meio da lista: um comentário dentro de um `for ... \` causa `parse error`.

```zsh
for module in \
  00-environment \
  10-options \
  30-completion \
  40-keybindings
do
```

(Exemplo: `20-history` foi removido da lista.) Para desativar só temporariamente, comente o conteúdo do módulo.

## Decisões e trade-offs

| Decisão | Por quê | Custo |
| --- | --- | --- |
| Zsh puro, sem Oh My Zsh | Plugins vêm do Fedora (atualizam via `dnf`); menos código para carregar | Sem os aliases do plugin `git` do OMZ |
| Atuin só no `Ctrl+R` | Busca por diretório/sessão/exit code; `↑` continua simples | Um banco SQLite a mais |
| Atuin sem sync e sem import | Histórico local e previsível | Começa vazio |
| `SHARE_HISTORY` desligado | O Atuin cuida do histórico entre abas | O histórico nativo é gravado a cada comando (`INC_APPEND_HISTORY`), mas só é relido ao abrir uma nova sessão |
| `HISTFILE` em `~/.local/state/zsh/history` | Segue o padrão XDG | O `~/.zsh_history` antigo **não** é lido (veja abaixo) |
| Sem `EXTENDED_GLOB` | `git reset HEAD^` falha com ele (`no matches found`) | Quem precisa de `^`/`#`/`~` em globs ativa no próprio script |
| Highlighting por último | Exigência do plugin | — |
| Lerd no início do `PATH` | Shims resolvem PHP/Node por projeto | Não rode `fnm env` junto |
| Starship pelo COPR | Não há pacote oficial no Fedora | Repositório de terceiros |

**Reaproveitar o histórico antigo do Zsh** (opcional, uma vez):

```bash
mkdir -p ~/.local/state/zsh && cp -n ~/.zsh_history ~/.local/state/zsh/history
```

## Histórico e segurança

- O Atuin guarda em `~/.local/share/atuin/`; `secrets_filter = true` (padrão do Atuin, explícito aqui) filtra padrões conhecidos de chaves.
- `history_filter` acrescenta regras para `export TOKEN=...`, `--token`, `cat .env`, `kubectl get secret`, `gh auth token`, `mysql -pSENHA` e comandos sensíveis do Lerd; `cwd_filter` ignora `~/.ssh` e `~/.gnupg`.
- Comandos iniciados com espaço não entram no histórico nativo (`HIST_IGNORE_SPACE`).

> Filtros são defesa em profundidade, **não garantia**. Não coloque segredos em argumentos de comando; prefira variáveis de ambiente, arquivos com `chmod 600` e gerenciadores de segredos.

## Solução de problemas

| Sintoma | Causa provável | O que fazer |
| --- | --- | --- |
| Ícones viram quadrados | Terminal sem Nerd Font | Selecione a Nerd Font nas preferências de fonte do terminal |
| `Ctrl+Espaço` não faz nada | O terminal/IBus não envia `^@` | Use `→` ou `End` |
| `?` abre o Atuin AI ou mostra mensagem | `?` religado | Rode `./doctor.sh`; o `60-atuin.zsh` restaura `self-insert` |
| `starship: command not found` | Starship não instalado | `./install.sh --apply --with-starship-copr` |
| `copr enable` falha | Repositório de terceiros sem build para a sua versão | Instale o Starship por outro método em <https://starship.rs/guide/> |
| `git ... HEAD^` dá `no matches found` | `EXTENDED_GLOB` ativo no seu `.zshrc.local` | Remova a opção ou use `HEAD\^` |
| Zsh lento | `compinit` ou plugin extra | `time zsh -i -c exit`; `zmodload zsh/zprof` no topo do `.zshrc` |

## Backup, rollback e diagnóstico

```bash
./doctor.sh                                  # diagnóstico
./rollback.sh                                # restaura o backup mais recente
./rollback.sh ~/.local/state/zsh-professional/backups/AAAAmmdd-HHMMSS
./rollback.sh --remove-packages              # também remove pacotes instalados por este projeto (confirma)
./rollback.sh --restore-copr                 # desabilita o COPR se foi habilitado por este projeto (confirma)
```

O rollback restaura arquivo por arquivo e remove os que não existiam antes. Nada além dos arquivos gerenciados é tocado.

## Validação

O CI (`.github/workflows/ci.yml`) roda `bash -n` e `shellcheck` nos scripts, `zsh -n` nos módulos e valida os TOML. Localmente: `./doctor.sh`.

## Referências

- Zsh: <https://zsh.sourceforge.io/Doc/>
- zsh-autosuggestions (widgets de aceite e aceite parcial): <https://github.com/zsh-users/zsh-autosuggestions>
- zsh-syntax-highlighting: <https://github.com/zsh-users/zsh-syntax-highlighting>
- Atuin: <https://docs.atuin.sh/> · `atuin init`: <https://docs.atuin.sh/main/reference/init/> · atalhos: <https://docs.atuin.sh/main/configuration/key-binding/>
- FZF: <https://github.com/junegunn/fzf> · Zoxide: <https://github.com/ajeetdsouza/zoxide> · Eza: <https://github.com/eza-community/eza>
- Starship: <https://starship.rs/guide/> · COPR: <https://copr.fedorainfracloud.org/coprs/atim/starship/>
- DNF5 `install` (`--skip-unavailable`): <https://www.mankier.com/8/dnf5-install>
- Lerd: <https://lerd.sh>
