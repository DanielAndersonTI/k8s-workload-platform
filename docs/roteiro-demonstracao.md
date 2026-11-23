# Roteiro de demonstração — Atividade 5

Sequência para a apresentação de 26/11/2026. O objetivo é mostrar o caminho
externo completo, o estado do cluster e uma prova de resiliência sem alterar o
ambiente da Atividade 4.

## Antes da aula

Executar na VDI, com a CLI do OpenStack carregada.

```bash
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

# 4. URLs da A4, que devem continuar respondendo
for p in 8100 8101 8102; do
  curl -sS -o /dev/null -w "$p %{http_code}\n" http://150.165.85.77:$p/health
done
```

Critério para apresentar: seis códigos 200 e os três membros da A5 `ONLINE`.

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
```

5. Mostrar o estado do cluster e os objetos de política.

```bash
ssh -i ~/.ssh/atividade5 -p 2223 ubuntu@150.165.85.77 \
  'kubectl -n workloads get deploy,pods,svc,pdb,limitrange'
```

6. Mostrar o consumo por `kubectl top`.
7. Se o professor pedir uma falha, excluir um pod e acompanhar a reposição. Não
   derrubar as duas réplicas nem o nó durante a aula.

```bash
# escolher um pod da lista e excluir apenas ele
ssh -i ~/.ssh/atividade5 -p 2223 ubuntu@150.165.85.77 \
  'kubectl -n workloads get pods -l app.kubernetes.io/name=cpu-workload'
ssh -i ~/.ssh/atividade5 -p 2223 ubuntu@150.165.85.77 \
  'kubectl -n workloads delete pod <nome-do-pod>'
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

Se o container estiver parado, `minikube start` restaura os pods. A cota de CPU
precisa ser reaplicada; o `20-cluster.sh` faz isso e falha se `CpuQuota` for
zero. Enquanto o cluster reinicia, usar as evidências T3.1, T3.2 e T7.3.

## Depois da aula

```bash
ssh -i ~/.ssh/atividade5 -p 2223 ubuntu@150.165.85.77 \
  'kubectl -n workloads get pods; kubectl -n workloads rollout status deployment/cpu-workload'
```

Confirmar que os seis pods estão `Running` e que as seis URLs voltaram a 200.
Não deixar pod de teste, escala reduzida ou listener temporário.
