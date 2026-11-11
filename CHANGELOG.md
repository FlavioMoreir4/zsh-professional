# Changelog

## 3.1.0

### Correções
- Removido `EXTENDED_GLOB`: quebrava `git ... HEAD^` (`zsh: no matches found`).
- Removido `init.py`: gerador obsoleto que reescrevia os arquivos de `config/` com versões antigas e falhava na própria validação.
- `?` volta a digitar normalmente: versões recentes do Atuin ligam a tecla ao Atuin AI. A correção é feita com `bindkey`, sem depender da flag `--disable-ai` (inexistente em versões antigas).
- Instalador e rollback passam a gerenciar `conf.d/` arquivo por arquivo: módulos criados por você não são apagados pelo rollback.
- Falha no COPR do Starship não aborta mais a instalação; pacotes base são instalados antes.
- `40-keybindings.zsh` sem blocos duplicados.
- Snippet de "desativar módulo" do README corrigido (o anterior dava `parse error`).

### Melhorias
- Filtro do Atuin para `mysql -pSENHA`.
- `secrets_filter = true` explícito (já era o padrão).
- Instalador: requer Fedora >= 41 (DNF5), avisa se a versão difere da testada (45) e instala só os pacotes usados.
- `doctor.sh`: checa Nerd Font, plugins, mensagens no startup, `?`, avisos do Starship.
- CI no GitHub Actions (shellcheck, `zsh -n`, TOML).
- README reescrito: requisitos, decisões e trade-offs, solução de problemas, referências.
