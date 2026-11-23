# Relatório de implantação: plataforma Kubernetes

| Campo | Valor |
| --- | --- |
| Grupo | [VERIFICAR: identificação do grupo] |
| Alunos | Daniel Anderson |
| Matrículas | [VERIFICAR: matrícula] |
| Repositório | https://github.com/DanielAndersonTI/k8s-workload-platform |
| Data da implantação | 22 e 23 de novembro de 2026 |

## 1. Configuração da VM e ambiente da Cloud

### 1.1 Instância

A instância `vm-atividade5-k8s` foi criada no projeto `Provisionamento`, com a imagem `ubuntu-24.04` e o sabor `general.large`. O `cloud-init` terminou antes da instalação do cluster, e a máquina não recebeu volume adicional.

| Campo | Valor |
| --- | --- |
| ID | `8c77dbe6-dd33-43ba-9d96-939ddfd5effa` |
| Projeto | `Provisionamento` (`2c593796f29e4b829b1b523775e2fa26`) |
| Imagem | `ubuntu-24.04` (625476096 bytes) |
| Sabor | `general.large`, 4 vCPU, 8192 MB, 20 GB |
| Zona | `nova` |
| Sistema | Ubuntu 24.04.3 LTS |
| Recursos vistos pela VM | 4 vCPU, 7941 MB, 19 GB em `/` |
| Endereço | `10.5.11.226`, rede `provider` |

O sabor cobre o nó do Minikube com folga para o sistema operacional e para o Docker. A memória útil fica 251 MB abaixo do valor nominal, diferença compatível com firmware e kernel. O disco de 20 GB foi suficiente para o sistema, as imagens e o nó; nenhum volume extra foi anexado.

### 1.2 Rede e acesso

O acesso não usa IP flutuante. A entrada administrativa é o listener TCP `ssh-atividade5`, na porta 2223 do balanceador compartilhado, que encaminha para a porta 22 da VM. O grupo `sg-atividade5` libera SSH, as portas 8000 a 8002 e ICMP apenas a partir de `10.5.8.0/22`. As portas 8000 a 8002 atendem aos membros do pool, não a clientes externos.

### 1.3 Recursos preservados

A VM `vm-daniel-ranya`, os três containers e os listeners 8100 a 8102 e 2222 da Atividade 4 permaneceram ligados e sem alteração. A instância `ERROR` do balanceador `poi-atividades` já existia e não foi tocada; todas as criações ocorreram na instância `ACTIVE`, referenciada por ID. Nenhum recurso de outro grupo foi criado, alterado ou removido.

## 2. Deploy e configuração do cluster Kubernetes

### 2.1 Instalação

O cluster usa o driver Docker do Minikube, escolhido porque o Docker já fazia parte do ambiente e não exige módulo de kernel adicional. A instalação partiu de um script único, que também desligou o swap e comentou a linha correspondente no `fstab`.

| Componente | Versão |
| --- | --- |
| Ubuntu | 24.04.3 LTS |
| Docker | 29.1.3 |
| kubectl | v1.37.2 |
| Minikube | v1.39.0 |
| Kubernetes | v1.37.0 |
| containerd | 2.3.4 |

O nó ficou `Ready` com os pods de sistema em execução. O `metrics-server` foi habilitado para permitir a leitura de consumo por `kubectl top`. A verificação ocorreu antes de qualquer manifesto de aplicação, o que separa falha de instalação de falha de deploy.

### 2.2 Dimensionamento do cluster

O nó recebeu 3 vCPU e 6144 MB, de um total de 4 vCPU e 7941 MB. A reserva restante atende ao sistema operacional, ao daemon do Docker e ao processo que mantém o nó. As portas 30080 a 30082 foram publicadas no host como 8000 a 8002, que são os destinos dos membros do balanceador.

A conferência usou `docker port minikube`, que mostra o mapeamento efetivo do container, e `ss -ltn`, que confirma o socket em escuta. As três portas apareceram nas duas verificações, sem necessidade de plano alternativo com `kubectl port-forward`.

### 2.3 Decisões de configuração

| Objeto | Escolha | Justificativa |
| --- | --- | --- |
| Carga de trabalho | `Deployment` | As aplicações não guardam estado e não precisam de identidade estável |
| Réplicas | 2 | Uma réplica atende enquanto a outra é recriada ou atualizada |
| Estratégia de atualização | `RollingUpdate`, `maxUnavailable: 0` | Nenhum pod antigo sai antes de um novo ficar pronto |
| Serviço | `NodePort` 30080 a 30082 | O Minikube não oferece controlador de nuvem para criar `LoadBalancer` |
| Sondas | `startup`, `readiness` e `liveness` em `/health` | Separam início, entrada no Service e reinício por falha |
| Recursos | `requests` e `limits` por perfil | Garantem agendamento e limitam o consumo de cada aplicação |
| Segurança | UID 10001, raiz somente leitura, sem privilégios, `seccomp` | A aplicação não precisa de privilégio nem de escrita na imagem |
| Armazenamento | `emptyDir` em `/tmp` | Apenas o perfil de I/O grava arquivos temporários |

Os limites seguem o perfil de cada aplicação. CPU e memória recebem 1 vCPU e 512 MiB; memória, 1 vCPU e 1536 MiB; I/O, 500 m e 512 MiB, com `emptyDir` de 1 GiB. As requisições ficam entre 100 m e 250 m de CPU e entre 128 MiB e 512 MiB de memória.

## 3. Deploy das aplicações

### 3.1 Imagens

As imagens foram construídas em 23 de novembro de 2026, para `linux/amd64`, e publicadas no Docker Hub. Cada uma ocupa cerca de 44,3 MB no registro e foi lida sem autenticação, o que confirma o acesso público.

| Aplicação | Imagem | Porta interna | Porta do nó | Porta externa |
| --- | --- | --- | --- | --- |
| CPU | `danielandersonss/poi-cpu:1.1.0` | 8000 | 30080 | 8600 |
| Memória | `danielandersonss/poi-memory:1.1.0` | 8000 | 30081 | 8601 |
| I/O | `danielandersonss/poi-io:1.1.0` | 8000 | 30082 | 8602 |

Os digests publicados foram `e3d6931e83aa` para CPU, `dc65bb896626` para memória e `875c7f03f4ac` para I/O. O `docker pull` na VM devolveu os mesmos identificadores, o que liga o manifesto à imagem efetivamente baixada.

### 3.2 Manifestos

O diretório `k8s/` contém um namespace, três Deployments, três Services e o `kustomization.yaml` que reúne os oito arquivos. A aplicação usa `kubectl apply -k k8s/` e espera o rollout de cada Deployment antes de seguir.

Cada Deployment declara duas réplicas, histórico de três revisões e a estratégia `RollingUpdate`. O pod roda como usuário 10001, com raiz somente leitura, sem escalada de privilégio e com todas as capacidades removidas. Os três rollouts terminaram sem erro, e os seis pods ficaram `Running` com um endpoint por réplica em cada Service.

### 3.3 Exposição pelo balanceador

O balanceador `poi-atividades` é compartilhado pela turma e tem duas instâncias com o mesmo nome. O script seleciona a instância `ACTIVE` e passa a referenciá-la pelo ID `57c2b14a-b746-4f34-8719-d0627e409609`, o que evita que a linha de comando atinja a instância em `ERROR`.

| Listener | Porta | Pool | Monitor | Membro |
| --- | --- | --- | --- | --- |
| `app-cpu-atividade5` | 8600 | `pool-app-cpu-atividade5` | HTTP `/health`, 5 s | `10.5.11.226:8000` |
| `app-memory-atividade5` | 8601 | `pool-app-memory-atividade5` | HTTP `/health`, 5 s | `10.5.11.226:8001` |
| `app-io-atividade5` | 8602 | `pool-app-io-atividade5` | HTTP `/health`, 5 s | `10.5.11.226:8002` |
| `ssh-atividade5` | 2223 | `pool-ssh-atividade5` | TCP, 5 s | `10.5.11.226:22` |

Os quatro listeners ficaram `ACTIVE/ONLINE`, e os quatro membros, `ONLINE`. O monitor usa o mesmo `/health` das sondas do Kubernetes; quando a aplicação falha, o membro sai do pool antes que o cliente receba erro.

### 3.4 Verificação

As medições partiram da VDI, que é a única máquina com rota para a VIP `150.165.85.77`. Os tempos incluem o balanceador e o caminho completo até o pod. Na primeira verificação, a chamada ao perfil de I/O levou 322 ms; na conferência final, 30,4 ms.

| Serviço | URL | `/health` | Tempo |
| --- | --- | --- | --- |
| CPU A5 | `http://150.165.85.77:8600/health` | 200 | 25,8 ms |
| Memória A5 | `http://150.165.85.77:8601/health` | 200 | 22,9 ms |
| I/O A5 | `http://150.165.85.77:8602/health` | 200 | 30,4 ms |
| CPU A4 | `http://150.165.85.77:8100/health` | 200 | 22,1 ms |
| Memória A4 | `http://150.165.85.77:8101/health` | 200 | 23,5 ms |
| I/O A4 | `http://150.165.85.77:8102/health` | 200 | 21,8 ms |

As três portas novas responderam também a `/work` e `/metrics`, com o perfil correto em cada caso. O perfil de CPU devolveu o hash de dez iterações; o de memória, 32 MiB alocados e o checksum correspondente; o de I/O, 1 MiB lido e 1 MiB escrito.

### 3.5 Teste de falha

Um pod do `cpu-workload` foi excluído enquanto um laço na VDI fazia uma requisição externa a cada 0,2 s. O Deployment criou a réplica substituta e o rollout terminou em 1 s. A segunda réplica atendeu durante toda a troca.

O laço completou 232 requisições em 70 s, todas com código 200. O consumo após o teste ficou em 411 m de CPU e 700 MiB no nó, com os pods entre 1 m e 37 m de CPU e entre 13 MiB e 15 MiB de memória.

Um `minikube stop` seguido de `minikube start` interrompeu as URLs por alguns minutos. Após a sincronização do kubelet, os seis pods voltaram a `Running` e as três portas responderam. O intervalo exato de indisponibilidade não foi medido.

## 4. Dificuldades e limitações

O balanceador compartilhado tem duas instâncias com o mesmo nome, uma `ACTIVE` e outra em `ERROR`. A referência por nome era ambígua, e a solução foi resolver a instância ativa e usar o ID em todas as chamadas. A porta 8201, prevista no rascunho inicial, já pertencia a outro grupo; a A5 passou a usar 8600 a 8602, sem alterar listeners alheios.

A primeira execução do script de imagens herdou `IMAGE_TAG=1.0.0` do ambiente da Atividade 3 e republicou as imagens da A4. A variável passou a se chamar `A5_IMAGE_TAG` e a tag `1.0.0` foi restaurada a partir das imagens originais, com conferência de digest. As três imagens da A4 voltaram aos identificadores `443fa9abcd`, `f50ee3166072` e `f019ca3425f6`.

O acesso direto à rede `provider` não funciona a partir da VDI. Por isso, a administração da VM passa pelo listener SSH na porta 2223. A limitação vale para a conferência e para a demonstração: qualquer teste externo precisa sair da VDI ou de outra máquina com rota para a VIP.

O cluster tem um único nó. O teste de falha remove uma réplica, não o nó; a queda do nó interrompe as três aplicações até o reinício do Minikube. A persistência foi verificada com `minikube stop` e `minikube start`, mas não há réplica em outro host.

## Referências

KUBERNETES. *Deployments*. [S. l.]: Kubernetes Authors, 2026. Disponível em: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/. Acesso em: 23 nov. 2026.

KUBERNETES. *Service*. [S. l.]: Kubernetes Authors, 2026. Disponível em: https://kubernetes.io/docs/concepts/services-networking/service/. Acesso em: 23 nov. 2026.

KUBERNETES. *Configure Liveness, Readiness and Startup Probes*. [S. l.]: Kubernetes Authors, 2026. Disponível em: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/. Acesso em: 23 nov. 2026.

MINIKUBE. *Docker driver*. [S. l.]: Minikube Authors, 2026. Disponível em: https://minikube.sigs.k8s.io/docs/drivers/docker/. Acesso em: 23 nov. 2026.

OPENSTACK. *Octavia documentation*. [S. l.]: OpenStack Foundation, 2026. Disponível em: https://docs.openstack.org/octavia/latest/. Acesso em: 23 nov. 2026.

DOCKER. *docker build*. [S. l.]: Docker Inc., 2026. Disponível em: https://docs.docker.com/reference/cli/docker/buildx/build/. Acesso em: 23 nov. 2026.
