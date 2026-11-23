# Atividade 5 — índice de execução

Registro por tarefa da implantação Kubernetes. Cada linha aponta para um arquivo
Markdown com objetivo, comandos, saída, decisões e problemas; as evidências
ficam em `docs/evidencias/`.

Status possíveis: `pendente`, `em andamento`, `concluída`, `bloqueada`.

| Task | Descrição | Status | Registro |
| --- | --- | --- | --- |
| T0.1 | Criar o repositório público k8s-workload-platform | concluída | [T0.1.md](T0.1.md) |
| T0.2 | Inicializar o repositório local e configurar origin | concluída | [T0.2.md](T0.2.md) |
| T0.3 | Copiar as três aplicações e o Dockerfile | concluída | [T0.3.md](T0.3.md) |
| T0.4 | Criar os manifestos Kubernetes em k8s/ | concluída | [T0.4.md](T0.4.md) |
| T0.5 | Criar os scripts de provisionamento, deploy e verificação | concluída | [T0.5.md](T0.5.md) |
| T0.6 | Escrever o README em inglês | concluída | [T0.6.md](T0.6.md) |
| T0.7 | Escrever docs/background.md | concluída | [T0.7.md](T0.7.md) |
| T0.8 | Criar o esqueleto do relatório final | concluída | [T0.8.md](T0.8.md) |
| T0.9 | Validar YAML, scripts e código Python | concluída | [T0.9.md](T0.9.md) |
| T0.10 | Isolar Atividade-5 do repositório das atividades 3 e 4 | concluída | [T0.10.md](T0.10.md) |
| T0.11 | Fazer o commit e o push iniciais | concluída | [T0.11.md](T0.11.md) |
| T1.1 | Confirmar sessão, projeto e cota no OpenStack | concluída | [T1.1.md](T1.1.md) |
| T1.2 | Confirmar o sabor general.large e a imagem Ubuntu 24.04 | concluída | [T1.2.md](T1.2.md) |
| T1.3 | Definir VM, keypair, security group e rede | concluída | [T1.3.md](T1.3.md) |
| T1.4 | Manter a VM e o volume da Atividade 4 | concluída | [T1.4.md](T1.4.md) |
| T1.5 | Definir a tag 1.1.0 para as imagens | concluída | [T1.5.md](T1.5.md) |
| T1.6 | Definir pasta, nomes e sanitização das evidências | concluída | [T1.6.md](T1.6.md) |
| T1.7 | Definir formato e link do relatório final | concluída | [T1.7.md](T1.7.md) |
| T2.1 | Criar o keypair atividade5 | concluída | [T2.1.md](T2.1.md) |
| T2.2 | Criar o security group sg-atividade5 | concluída | [T2.2.md](T2.2.md) |
| T2.3 | Criar a VM vm-atividade5-k8s | concluída | [T2.3.md](T2.3.md) |
| T2.4 | Registrar ID, endereço e zona da instância | concluída | [T2.4.md](T2.4.md) |
| T2.5 | Acessar a VM por SSH | concluída | [T2.5.md](T2.5.md) |
| T2.6 | Confirmar CPU, memória, disco e versão do sistema | concluída | [T2.6.md](T2.6.md) |
| T2.7 | Registrar as evidências da fase 2 | concluída | [T2.7.md](T2.7.md) |
| T3.1 | Instalar Docker, kubectl e Minikube | concluída | [T3.1.md](T3.1.md) |
| T3.2 | Desabilitar o swap e ajustar o fstab | concluída | [T3.2.md](T3.2.md) |
| T3.3 | Iniciar o Minikube com 3 CPUs, 6 GB e as portas | concluída | [T3.3.md](T3.3.md) |
| T3.4 | Confirmar nó Ready, versões e portas publicadas | concluída | [T3.4.md](T3.4.md) |
| T3.5 | Registrar as evidências da fase 3 | concluída | [T3.5.md](T3.5.md) |
| T3.6 | Acionar o plano alternativo se as portas não forem publicadas | concluída | [T3.6.md](T3.6.md) |
| T4.1 | Confirmar que as imagens são públicas no Docker Hub | concluída | [T4.1.md](T4.1.md) |
| T4.2 | Publicar as três imagens como 1.1.0 | concluída | [T4.2.md](T4.2.md) |
| T4.3 | Atualizar manifestos, README e relatório com a tag | concluída | [T4.3.md](T4.3.md) |
| T4.4 | Testar o docker pull na VM | concluída | [T4.4.md](T4.4.md) |
| T5.1 | Aplicar os manifestos com kubectl apply -k | concluída | [T5.1.md](T5.1.md) |
| T5.2 | Acompanhar rollouts e conferir pods, serviços e endpoints | concluída | [T5.2.md](T5.2.md) |
| T5.3 | Testar /health, /work e /metrics nas portas locais | concluída | [T5.3.md](T5.3.md) |
| T5.4 | Registrar as evidências da fase 5 | concluída | [T5.4.md](T5.4.md) |
| T6.1 | Criar os três listeners nas portas 8600 a 8602 | concluída | [T6.1.md](T6.1.md) |
| T6.2 | Criar pools, monitores e membros | concluída | [T6.2.md](T6.2.md) |
| T6.3 | Criar o listener SSH na porta 2223 | concluída | [T6.3.md](T6.3.md) |
| T6.4 | Aguardar listeners, pools e membros ONLINE | concluída | [T6.4.md](T6.4.md) |
| T6.5 | Testar as três URLs externas | concluída | [T6.5.md](T6.5.md) |
| T6.6 | Confirmar as URLs da A4 | concluída | [T6.6.md](T6.6.md) |
| T6.7 | Registrar as evidências da fase 6 | concluída | [T6.7.md](T6.7.md) |
| T7.1 | Excluir um pod e confirmar a recriação | concluída | [T7.1.md](T7.1.md) |
| T7.2 | Confirmar a disponibilidade durante a falha | concluída | [T7.2.md](T7.2.md) |
| T7.3 | Conferir o consumo com kubectl top | concluída | [T7.3.md](T7.3.md) |
| T7.4 | Registrar as evidências da fase 7 | concluída | [T7.4.md](T7.4.md) |
| T7.5 | Testar a persistência após minikube stop e start | concluída | [T7.5.md](T7.5.md) |
| T8.1 | Confirmar as três URLs externas da A5 | concluída | [T8.1.md](T8.1.md) |
| T8.2 | Confirmar as três URLs da A4 | concluída | [T8.2.md](T8.2.md) |
| T8.3 | Confirmar que nenhum recurso do professor foi alterado | concluída | [T8.3.md](T8.3.md) |
| T8.4 | Registrar a evidência de coexistência | concluída | [T8.4.md](T8.4.md) |
| T9.1 | Criar um arquivo por tarefa | concluída | [T9.1.md](T9.1.md) |
| T9.2 | Registrar objetivo, comandos, saída, decisões e problemas | concluída | [T9.2.md](T9.2.md) |
| T9.3 | Ligar cada tarefa às evidências | concluída | [T9.3.md](T9.3.md) |
| T9.4 | Revisar datas, IDs e coerência | concluída | [T9.4.md](T9.4.md) |
| T10.1 | Preencher as seções do modelo | concluída | [T10.1.md](T10.1.md) |
| T10.2 | Escrever a síntese no estilo acadêmico | concluída | [T10.2.md](T10.2.md) |
| T10.3 | Inserir as tabelas de VM, cluster, imagens e portas | concluída | [T10.3.md](T10.3.md) |
| T10.4 | Referenciar as evidências por ID | concluída | [T10.4.md](T10.4.md) |
| T10.5 | Preencher as referências com data de acesso | concluída | [T10.5.md](T10.5.md) |
| T10.6 | Aplicar o checklist de revisão | concluída | [T10.6.md](T10.6.md) |
| T10.7 | Exportar o PDF | concluída | [T10.7.md](T10.7.md) |
| T11.1 | Revisar o README contra o estado real do deploy | pendente | — |
| T11.2 | Fazer o commit e o push finais | pendente | — |
| T11.3 | Preencher os 19 campos do formulário | pendente | — |
| T11.4 | Preparar os slides da apresentação | pendente | — |
| T11.5 | Ensaiar a demonstração das três URLs | pendente | — |
| T11.6 | Apresentar em 26/11/2026 | pendente | — |

## Evidências esperadas

| Prefixo | Conteúdo |
| --- | --- |
| `T1.*` | sessão, projeto, cota, sabor, imagem e conflito de portas |
| `T2.*` | keypair, grupo de segurança, VM, SSH e recursos |
| `T3.*` | versões, nó, pods de sistema e portas publicadas |
| `T4.*` | imagens públicas, build, digests e pull na VM |
| `T5.*` | aplicação, pods, serviços, endpoints e respostas locais |
| `T6.*` | listeners, membros e URLs externas da A5 e da A4 |
| `T7.*` | falha de pod, consumo e persistência após reinício |
| `T8.*` | coexistência final entre A5 e A4 |
| `T10.*` | relatório final em Markdown e PDF |
