# Roteiro de demonstração — Atividade 5

Sequência para a apresentação de 26/11/2026. O objetivo é mostrar o caminho
externo completo, o estado do cluster e uma prova de resiliência sem depender do
ambiente da Atividade 4.

## Antes da aula

Executar na VDI, com a CLI do OpenStack carregada.

```bash
# 0. cluster de pé (se a VM reiniciou, rodar minikube start antes)
ssh -i ~/.ssh/atividade5 -p 2223 ubuntu@150.165.85.77 \
  'minikube status; kubectl get node'

# 1. cluster e pods
ssh -i ~/.ssh/atividade5 -p 2223 ubuntu@150.165.85.77 \
  'kubectl -n workloads get deploy,pods,svc,pdb -o wide'

# 2. balanceador
openstack loadbalancer listener list --name app-cpu-atividade5
openstack loadbalancer member list c336436d-7bea-473f-a92d-fd57024d02f2

# 3. URLs externas da A5
for p in 8600 8601 8602; do
  curl -sS -o /dev/null -w "$p %{http_code} %{time_total}\n" \
    http://150.165.85.77:$p/health
done

# 4. estado dos membros no balanceador
openstack loadbalancer status show 57c2b14a-b746-4f34-8719-d0627e409609
```

Critério para apresentar: três códigos 200 da A5 e os três membros da A5
`ONLINE`. As portas 8100 a 8102 pertencem à Atividade 4, responderam em 23/11
(T8.1) e não fazem parte deste critério.

Os passos 2 e 4 dependem de uma sessão ativa do OpenStack. Sem sessão, o comando
`openstack` falha e a demonstração segue pelos passos 0, 1 e 3, que bastam para
mostrar cluster e acesso externo.

## Durante a apresentação

1. Abrir `docs/apresentacao.md` ou o PDF exportado.
2. Mostrar a figura da arquitetura e explicar o caminho cliente, VIP, Octavia,
   NodePort, Service e pod.
3. Executar as três URLs no navegador ou no terminal.
4. Executar `/work` com tamanhos pequenos, para não alongar a demonstração.

```bash
curl -sS "http://150.165.85.77:8600/work?size=10"
curl -sS "http://150.165.85.77:8601/work?size=32"
curl -sS "http://150.165.85.77:8602/work?size=1024"
curl -sS http://150.165.85.77:8600/metrics
```

5. Mostrar o estado do cluster e os objetos de política.

```bash
ssh -i ~/.ssh/atividade5 -p 2223 ubuntu@150.165.85.77 \
  'kubectl -n workloads get deploy,pods,svc,pdb,limitrange'
```

6. Mostrar o consumo por `kubectl top`.

```bash
ssh -i ~/.ssh/atividade5 -p 2223 ubuntu@150.165.85.77 \
  'kubectl -n workloads top pods'
```
7. Se o professor pedir uma falha, excluir um pod e acompanhar a reposição. Não
   derrubar as duas réplicas nem o nó durante a aula.

```bash
# escolher um pod da lista e excluir apenas ele
ssh -i ~/.ssh/atividade5 -p 2223 ubuntu@150.165.85.77 \
  'kubectl -n workloads get pods -l app.kubernetes.io/name=cpu-workload'
ssh -i ~/.ssh/atividade5 -p 2223 ubuntu@150.165.85.77 \
  'kubectl -n workloads delete pod <nome-do-pod>'
```

8. Mostrar a atualização sem interrupção. O `rollout restart` recria os pods de
   CPU um a um, e `maxUnavailable: 0` mantém uma réplica pronta. Em outro
   terminal, um laço de uma requisição por segundo registra os códigos.

```bash
# terminal 1
while true; do
  curl -s -o /dev/null -w "%{http_code}\n" --max-time 3 \
    http://150.165.85.77:8600/health
  sleep 1
done

# terminal 2
ssh -i ~/.ssh/atividade5 -p 2223 ubuntu@150.165.85.77 \
  'kubectl -n workloads rollout restart deployment/cpu-workload && kubectl -n workloads rollout status deployment/cpu-workload --timeout=180s'
```

9. Demonstrar o reinício por liveness com uma sonda temporariamente inválida. O
   pod continua pronto para o Service, mas o kubelet reinicia o container depois
   de três falhas, e o `RESTARTS` sobe. Desfazer a alteração em seguida.

```bash
ssh -i ~/.ssh/atividade5 -p 2223 ubuntu@150.165.85.77 \
  "kubectl -n workloads patch deployment cpu-workload --type=json -p='[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/livenessProbe/httpGet/path\",\"value\":\"/sem-sonda\"}]'"
# aguardar cerca de 2 min e conferir o contador
ssh -i ~/.ssh/atividade5 -p 2223 ubuntu@150.165.85.77 \
  'kubectl -n workloads get pods -l app.kubernetes.io/name=cpu-workload'
ssh -i ~/.ssh/atividade5 -p 2223 ubuntu@150.165.85.77 \
  'kubectl -n workloads rollout undo deployment/cpu-workload && kubectl -n workloads rollout status deployment/cpu-workload --timeout=180s'
```

## Se a VDI não tiver rota para a VIP

A VDI é o caminho previsto. Sem rota, o teste externo não é possível a partir
dela. Alternativas, em ordem:

1. Usar outra máquina da rede que alcance `150.165.85.77`.
2. Mostrar a resposta local na VM e a evidência externa já gravada.

```bash
ssh -i ~/.ssh/atividade5 -p 2223 ubuntu@150.165.85.77 \
  'for p in 8000 8001 8002; do curl -sS http://127.0.0.1:$p/health; done'
```

3. Abrir `docs/evidencias/T6.3-external.txt` e `T6.8-latencia.txt`.

## Se o balanceador estiver indisponível

1. Conferir o estado dos membros. Um membro em `ERROR` com pods prontos indica
   falha do monitor ou do listener.

```bash
openstack loadbalancer status show poi-atividades
```

2. Se a instância `ACTIVE` estiver saudável, aguardar um ciclo do monitor, que
   tem 5 s de intervalo e três tentativas.
3. Se o listener não existir, recriar apenas os objetos da A5.

```bash
export SUBNET_ID=17de9c72-e5dc-4da0-ae0a-013f7e42400e
bash scripts/50-loadbalancer.sh
```

O script não altera os listeners 8100 a 8102 nem a instância em `ERROR`.

## Se o cluster não responder

```bash
ssh -i ~/.ssh/atividade5 -p 2223 ubuntu@150.165.85.77 \
  'minikube status; docker ps --filter name=minikube'
```

Se o container estiver parado, `minikube start` restaura os pods. Não usar
`docker start` no lugar dele: o container sobe, o nó fica `Ready`, mas as
NodePorts param de responder porque as entradas de DNS do nó só são recriadas no
`minikube start` (T7.12). A cota de CPU precisa ser reaplicada; o `20-cluster.sh`
faz isso e falha se `CpuQuota` for zero. Enquanto o cluster reinicia, usar as
evidências T3.1, T3.2 e T7.3.

## Depois da aula

```bash
ssh -i ~/.ssh/atividade5 -p 2223 ubuntu@150.165.85.77 \
  'kubectl -n workloads get pods; kubectl -n workloads rollout status deployment/cpu-workload'
```

Confirmar que os seis pods estão `Running` e que as três URLs da A5 voltaram a
200. Não deixar pod de teste, escala reduzida ou listener temporário.
