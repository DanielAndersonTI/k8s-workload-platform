# Relatório de implantação: plataforma Kubernetes

| Campo | Valor |
| --- | --- |
| Grupo | [PREENCHER: identificador do grupo] |
| Alunos | [PREENCHER: nomes completos] |
| Matrículas | [PREENCHER: matrículas] |
| Repositório | https://github.com/DanielAndersonTI/k8s-workload-platform |
| Data da implantação | [PREENCHER: data] |

## 1. Configuração da VM e ambiente da Cloud

### 1.1 Instância

[PREENCHER: imagem, sabor, vCPUs, memória, disco, zona e ID da instância criada. O ID deve ser copiado da saída de `openstack server show`.]

### 1.2 Rede e acesso

[PREENCHER: rede, endereço fixo ou flutuante, grupo de segurança, regras liberadas e forma de acesso SSH. Informar se o acesso continua pelo balanceador ou por IP direto.]

### 1.3 Recursos preservados

[PREENCHER: quais recursos da atividade anterior foram mantidos, quais foram removidos e por quê. Registrar explicitamente que os recursos do professor não foram alterados.]

## 2. Deploy e configuração do cluster Kubernetes

### 2.1 Instalação

[PREENCHER: versão do Ubuntu, versão do Docker, versão do kubectl e versão do Minikube. Indicar o driver usado e a justificativa.]

### 2.2 Dimensionamento do cluster

[PREENCHER: CPUs e memória reservados ao nó, portas publicadas e resultado de `kubectl get nodes -o wide`. Explicar a folga deixada para o sistema operacional e para o Docker.]

### 2.3 Decisões de configuração

| Objeto | Escolha | Justificativa |
| --- | --- | --- |
| Carga de trabalho | `Deployment` | [PREENCHER: processo sem estado, sem identidade estável] |
| Réplicas | 2 | [PREENCHER: disponibilidade durante falha e atualização] |
| Estratégia de atualização | `RollingUpdate`, `maxUnavailable: 0` | [PREENCHER: nenhum pod antigo sai antes de um novo ficar pronto] |
| Serviço | `NodePort` 30080 a 30082 | [PREENCHER: ausência de controlador de nuvem no Minikube] |
| Sondas | `startup`, `readiness` e `liveness` em `/health` | [PREENCHER: separar início, tráfego e reinício] |
| Recursos | `requests` e `limits` por perfil | [PREENCHER: garantir agendamento e limitar consumo] |
| Segurança | UID 10001, raiz somente leitura, sem privilégios, `seccomp` | [PREENCHER: a aplicação não precisa de privilégio nem de escrita na imagem] |
| Armazenamento | `emptyDir` em `/tmp` | [PREENCHER: escrita temporária do perfil de I/O] |

## 3. Deploy das aplicações

### 3.1 Imagens

| Aplicação | Imagem | Porta interna | Porta do nó | Porta externa |
| --- | --- | --- | --- | --- |
| CPU | `danielandersonss/poi-cpu:1.0.0` | 8000 | 30080 | 8100 |
| Memória | `danielandersonss/poi-memory:1.0.0` | 8000 | 30081 | 8101 |
| I/O | `danielandersonss/poi-io:1.0.0` | 8000 | 30082 | 8102 |

[PREENCHER: data do build, tamanho das imagens e confirmação de que são públicas no Docker Hub.]

### 3.2 Manifestos

[PREENCHER: lista dos arquivos em `k8s/` e comando de aplicação. Inserir a saída de `kubectl apply -k k8s/`.]

### 3.3 Exposição pelo balanceador

[PREENCHER: como o membro do pool foi apontado para o novo endereço da VM, quais listeners foram preservados e qual foi o resultado de `openstack loadbalancer member list`.]

### 3.4 Verificação

[PREENCHER: resultado de `/health` e `/work` nas três portas, pela VIP e pelo endereço local. Inserir tempos de resposta e códigos HTTP.]

### 3.5 Teste de falha

[PREENCHER: remoção de um pod, comportamento do `Deployment` e continuidade do serviço. Informar o tempo de recuperação observado.]

## 4. Dificuldades e limitações

[PREENCHER: problemas encontrados, decisões de contorno e limitações conhecidas. Não descrever tentativas que não deixaram evidência.]

## Referências

[PREENCHER: documentação do Kubernetes, do Minikube e do OpenStack efetivamente consultada, com data de acesso.]
