# killall

`killall` para o **Git Bash no Windows**: encontra todos os processos com um nome e mata cada um pelo PID.

```bash
killall node        # mata todos os node.exe
killall node.exe    # igual, o .exe é opcional
```

## Comportamento

- Kill forçado (`taskkill /F`), equivalente ao `kill -9`.
- **Não para no primeiro erro:** tenta matar todos e só no fim informa quantos falharam.
- **Só fala quando dá erro.** Se tudo deu certo, não imprime nada (pensado para matar milhares de processos).
- Processo que já sumiu antes da vez dele (por exemplo, um filho que morreu junto com o pai) **não** conta como falha.
- Não mata o próprio shell que executou o comando.

Exemplo com falha:

```
falhou: node.exe (PID 4404) — ERRO: Acesso negado.
1 de 25 falharam
```

### Código de saída

| código | significado                                 |
|--------|---------------------------------------------|
| `0`    | todos morreram                              |
| `1`    | algum falhou, ou nenhum processo encontrado |

## Instalação

Copie o script para uma pasta que esteja no PATH do Git Bash (o `~/bin` já vem no PATH):

```bash
mkdir -p ~/bin && cp killall ~/bin/ && chmod +x ~/bin/killall
```

Depois, abra um Git Bash novo.

> Não funciona no PowerShell nem no CMD, porque é um script bash.
