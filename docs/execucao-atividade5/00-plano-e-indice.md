# Plano de execução e índice da Atividade 5

| Campo | Valor |
| --- | --- |
| Início | 21/11/2026 |
| Entrega | 26/11/2026 |
| Repositório | https://github.com/DanielAndersonTI/k8s-workload-platform |
| Relatório final | `docs/relatorio-final.md` |
| Registro de execução | `docs/execucao-atividade5/` |

## Legenda

- `[x]` concluído
- `[ ]` pendente
- `[?]` decisão pendente

## Decisões fechadas em 21/11/2026

- Opção A: a A4 permanece nos listeners 8100 a 8102 e 2222; a A5 usa 8600 a 8602 e 2223.
- VM `vm-atividade5-k8s`, sabor `general.large`, imagem Ubuntu 24.04, rede `provider`.
- Keypair `atividade5` e security group `sg-atividade5`.
- A VM e o volume da A4 ficam ligados e intocados, sem remoção.
- As imagens da A5 serão publicadas como `1.1.0`.
- Portas externas da A5: 8600 a 8602 e SSH 2223. A porta 8201 do rascunho
  inicial pertence ao grupo 4 no balanceador compartilhado da turma.
- O balanceador tem duas instâncias com o mesmo nome; o script seleciona a que
  está `ACTIVE` e a referencia por ID.

## Fase 0 — Repositório e base documental

| ID | Tarefa | Estado |
| --- | --- | --- |
| T0.1 | Criar o repositório público `k8s-workload-platform` | [x] |
| T0.2 | Inicializar o repositório local em `Atividade-5` e configurar `origin` | [x] |
| T0.3 | Copiar as três aplicações e o Dockerfile para o repositório novo | [x] |
| T0.4 | Criar os manifestos Kubernetes em `k8s/` | [x] |
| T0.5 | Criar os scripts de provisionamento, deploy e verificação | [x] |
| T0.6 | Escrever o README em inglês | [x] |
| T0.7 | Escrever `docs/background.md` | [x] |
| T0.8 | Criar o esqueleto do relatório final em português | [x] |
| T0.9 | Validar YAML, sintaxe dos scripts e código Python | [x] |
| T0.10 | Isolar `Atividade-5` do repositório das atividades 3 e 4 | [x] |
| T0.11 | Fazer o commit e o push iniciais | [x] |

O commit e o push são manuais, sem coautoria automatizada.

## Fase 1 — Decisões e pré-requisitos

| ID | Tarefa | Estado |
| --- | --- | --- |
| T1.1 | Confirmar sessão, projeto e cota no OpenStack | [x] |
| T1.2 | Confirmar o sabor `general.large` e a imagem Ubuntu 24.04 | [x] |
| T1.3 | Definir VM `vm-atividade5-k8s`, keypair `atividade5`, SG `sg-atividade5` e rede `provider` | [x] |
| T1.4 | Manter a VM e o volume da Atividade 4 e criar a A5 em paralelo | [x] |
| T1.5 | Definir a tag `1.1.0` para as imagens da A5 | [x] |
| T1.6 | Definir pasta, nomes e sanitização das evidências | [x] |
| T1.7 | Definir formato e link do relatório final | [x] |

As decisões T1.2 a T1.6 foram fechadas antes da execução. A sessão e a cota
foram confirmadas ao vivo em 22/11/2026, com evidência em `T1.1-sessao-cota.txt`.

O relatório final fica em `docs/relatorio-final.md` e será exportado em PDF. A
entrega usa o link do arquivo no repositório e o PDF anexado no formulário.

## Fase 2 — Provisionamento da VM

| ID | Tarefa | Estado |
| --- | --- | --- |
| T2.1 | Criar o keypair `atividade5` e registrar a chave pública | [x] |
| T2.2 | Criar o security group `sg-atividade5` com as regras restritas | [x] |
| T2.3 | Criar a VM `vm-atividade5-k8s` com `general.large` e Ubuntu 24.04 | [x] |
| T2.4 | Registrar ID, endereço e zona da instância | [x] |
| T2.5 | Acessar a VM por SSH | [x] |
| T2.6 | Confirmar CPU, memória, disco e versão do sistema | [x] |
| T2.7 | Registrar as evidências `T2.1-keypair`, `T2.2-sg` e `T2.3-vm-show` | [x] |

## Fase 3 — Instalação do cluster

| ID | Tarefa | Estado |
| --- | --- | --- |
| T3.1 | Instalar Docker, `kubectl` e Minikube | [x] |
| T3.2 | Desabilitar o swap e ajustar o `fstab` | [x] |
| T3.3 | Iniciar o Minikube com 3 CPUs, 6 GB e as portas 8000 a 8002 | [x] |
| T3.4 | Confirmar nó `Ready`, versões e portas publicadas | [x] |
| T3.5 | Registrar as evidências `T3.1-versions` e `T3.2-node` | [x] |
| T3.6 | Acionar o plano alternativo se `--ports` não publicar as portas | [x] |

O plano alternativo é usar `kubectl port-forward` com units `systemd` ou
reconfigurar o driver. A decisão só é tomada se a verificação de portas falhar.
As portas 8000 a 8002 foram publicadas na primeira tentativa, então T3.6 não foi
acionada.

## Fase 4 — Imagens

| ID | Tarefa | Estado |
| --- | --- | --- |
| T4.1 | Confirmar que as imagens necessárias são públicas no Docker Hub | [x] |
| T4.2 | Executar `scripts/05-images.sh` e publicar as três imagens como `1.1.0` | [x] |
| T4.3 | Atualizar manifestos, README e relatório com a tag `1.1.0` | [x] |
| T4.4 | Testar o `docker pull` das três imagens na VM | [x] |

A primeira execução usou `IMAGE_TAG=1.0.0`, herdada do `session.env` da A3, e
republicou as imagens da A4. O script passou a usar `A5_IMAGE_TAG` e a tag
`1.0.0` foi restaurada a partir das imagens originais, com verificação de
digest em `T4.1-imagens-publicas.txt`.

## Fase 5 — Deploy das aplicações

| ID | Tarefa | Estado |
| --- | --- | --- |
| T5.1 | Aplicar os manifestos com `kubectl apply -k k8s/` | [x] |
| T5.2 | Acompanhar os três rollouts e conferir pods, serviços e endpoints | [x] |
| T5.3 | Testar `/health`, `/work` e `/metrics` em 8000, 8001 e 8002 | [x] |
| T5.4 | Registrar as evidências `T5.1-apply`, `T5.2-pods` e `T5.3-local` | [x] |

## Fase 6 — Exposição pelo balanceador

| ID | Tarefa | Estado |
| --- | --- | --- |
| T6.1 | Criar os três listeners `app-*-atividade5` nas portas 8600 a 8602 | [x] |
| T6.2 | Criar os pools, monitores e membros das três aplicações | [x] |
| T6.3 | Criar o listener SSH `ssh-atividade5` na porta 2223 | [x] |
| T6.4 | Aguardar listeners, pools e membros ficarem `ONLINE` | [x] |
| T6.5 | Testar as três URLs externas nas portas 8600, 8601 e 8602 | [x] |
| T6.6 | Confirmar que as URLs da A4 em 8100 a 8102 continuam respondendo | [x] |
| T6.7 | Registrar as evidências `T6.1-listeners`, `T6.2-members` e `T6.3-external` | [x] |

## Fase 7 — Verificação e falha controlada

| ID | Tarefa | Estado |
| --- | --- | --- |
| T7.1 | Excluir um pod e confirmar a recriação pelo `Deployment` | [x] |
| T7.2 | Confirmar que o serviço continuou disponível durante a falha | [x] |
| T7.3 | Conferir o consumo com `kubectl top` | [x] |
| T7.4 | Registrar as evidências `T7.1-failover` e `T7.2-top` | [x] |
| T7.5 | Testar a persistência após `minikube stop` e `minikube start` | [x] |

T7.5 foi executada. Os seis pods voltaram a `Running`, as portas 8000 a 8002
continuaram publicadas e as três aplicações responderam em seguida; evidência em
`T7.3-restart.txt`.

## Fase 8 — Conferência do ambiente anterior

| ID | Tarefa | Estado |
| --- | --- | --- |
| T8.1 | Confirmar as três URLs externas da A5 | [x] |
| T8.2 | Confirmar que as três URLs da A4 continuam respondendo | [x] |
| T8.3 | Confirmar que nenhum recurso do professor foi alterado | [x] |
| T8.4 | Registrar a evidência `T8.1-coexistencia` | [x] |

A A4 não é removida. A conferência prova que os dois ambientes coexistem.

## Fase 9 — Registro de execução

| ID | Tarefa | Estado |
| --- | --- | --- |
| T9.1 | Criar um arquivo por tarefa em `docs/execucao-atividade5/` | [x] |
| T9.2 | Registrar objetivo, comandos, saída, decisões e problemas | [x] |
| T9.3 | Ligar cada tarefa às evidências correspondentes | [x] |
| T9.4 | Revisar datas, IDs e coerência entre os registros | [x] |

Cada arquivo segue o formato da Atividade 4: tabela de identificação, objetivo,
comandos, o que aconteceu, saída, decisões e problemas. Foram criados 66
arquivos, das fases 0 a 10; o índice fica em `INDEX.md`.

## Fase 10 — Relatório final

| ID | Tarefa | Estado |
| --- | --- | --- |
| T10.1 | Preencher as seções do modelo da disciplina | [x] |
| T10.2 | Escrever a síntese no estilo acadêmico treinado | [x] |
| T10.3 | Inserir as tabelas de VM, cluster, imagens e portas | [x] |
| T10.4 | Referenciar as evidências por ID | [x] |
| T10.5 | Preencher as referências com data de acesso | [x] |
| T10.6 | Aplicar o checklist de revisão | [x] |
| T10.7 | Exportar o PDF ou publicar o link de entrega | [x] |

O relatório final sintetiza decisões e resultados. Os comandos e as saídas
brutas ficam no registro de execução. A exportação gerou
`docs/relatorio-final.pdf`, com 5 páginas. Restam no relatório apenas os campos
de identificação do grupo e de matrícula.

## Fase 11 — Entrega e apresentação

| ID | Tarefa | Estado |
| --- | --- | --- |
| T11.1 | Revisar o README em inglês contra o estado real do deploy | [ ] |
| T11.2 | Fazer o commit e o push finais | [ ] |
| T11.3 | Preencher os 19 campos do formulário | [ ] |
| T11.4 | Preparar os slides da apresentação | [ ] |
| T11.5 | Ensaiar a demonstração das três URLs | [ ] |
| T11.6 | Apresentar em 26/11/2026 | [ ] |

## Os dois relatórios

### Registro de execução

Pasta: `docs/execucao-atividade5/`.

Um arquivo por tarefa, com data, fase, status, evidências, objetivo, comandos,
resultado, decisões e problemas. É a memória técnica do processo e a fonte para
o relatório final. Não precisa de prosa acadêmica, mas precisa ser verificável.

### Relatório final

Arquivo: `docs/relatorio-final.md`.

Segue o modelo da disciplina: configuração da VM e da nuvem, deploy e
configuração do cluster, deploy das aplicações. Usa a voz acadêmica treinada,
cita as evidências por ID e não repete as saídas brutas. É o documento que será
entregue no formulário.

## Evidências

- Pasta: `docs/evidencias/`, com a política em `docs/evidencias/README.md`.
- Nome: `T<fase>.<tarefa>-<assunto>.txt`, por exemplo `T2.3-vm-show.txt`.
- Conteúdo: comando, data, saída relevante e ambiente.
- Sanitização: remover tokens, chaves, senhas e identificadores pessoais que não
  sejam necessários.
- Nenhum arquivo `docker.env`, `clouds.yaml` ou chave privada entra no repositório.

## Cronograma sugerido

| Data | Foco |
| --- | --- |
| 21/11 | Fases 0 e 1; commit inicial |
| 22/11 | Fases 2 a 5; primeira URL externa |
| 23/11 | Fases 6 a 8; falha controlada e coexistência com a A4 |
| 24/11 | Fase 9; registro de execução |
| 25/11 | Fase 10; relatório final, formulário e slides |
| 26/11 | Revisão final e apresentação |

A estimativa de trabalho efetivo é de 10 a 12 horas, sem contar esperas de
provisionamento e propagação do balanceador.
