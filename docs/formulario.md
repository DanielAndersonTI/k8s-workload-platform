# Formulário de entrega — Atividade 5

Valores conferidos contra o repositório e o deploy em 23/11/2026. O formulário
não foi enviado; a transcrição fica pendente da revisão de Ranya.

| # | Campo | Valor |
| --- | --- | --- |
| 1 | E-mail | [VERIFICAR: e-mail de Daniel]; [VERIFICAR: e-mail de Ranya] |
| 2 | Identificador do grupo | `daniel-ranya` |
| 3 | Nome | Daniel Anderson de Souza Silva; Ranya Duran Greco |
| 4 | Matrícula | 0126015852-52M; [VERIFICAR: matrícula de Ranya] |
| 5 | Participação | 50% para Daniel; 50% para Ranya |
| 6 | Link do documento | https://github.com/DanielAndersonTI/k8s-workload-platform/blob/main/docs/relatorio-final.md |
| 7 | Repositório GitHub | https://github.com/DanielAndersonTI/k8s-workload-platform |
| 8 | ID da VM | `8c77dbe6-dd33-43ba-9d96-939ddfd5effa` |
| 9 | YAML da aplicação CPU | https://github.com/DanielAndersonTI/k8s-workload-platform/blob/main/k8s/cpu-deployment.yaml |
| 10 | YAML da aplicação Memória | https://github.com/DanielAndersonTI/k8s-workload-platform/blob/main/k8s/memory-deployment.yaml |
| 11 | YAML da aplicação I/O | https://github.com/DanielAndersonTI/k8s-workload-platform/blob/main/k8s/io-deployment.yaml |
| 12 | YAML de exposição CPU | https://github.com/DanielAndersonTI/k8s-workload-platform/blob/main/k8s/cpu-service.yaml |
| 13 | YAML de exposição Memória | https://github.com/DanielAndersonTI/k8s-workload-platform/blob/main/k8s/memory-service.yaml |
| 14 | YAML de exposição I/O | https://github.com/DanielAndersonTI/k8s-workload-platform/blob/main/k8s/io-service.yaml |
| 15 | URL da aplicação CPU | http://150.165.85.77:8600/health |
| 16 | URL da aplicação Memória | http://150.165.85.77:8601/health |
| 17 | URL da aplicação I/O | http://150.165.85.77:8602/health |
| 18 | Imagem CPU | https://hub.docker.com/r/danielandersonss/poi-cpu |
| 19 | Imagem Memória | https://hub.docker.com/r/danielandersonss/poi-memory |
| 20 | Imagem I/O | https://hub.docker.com/r/danielandersonss/poi-io |

## Observações

- O link do documento aponta para o Markdown no repositório, que é a versão
  atualizada. O PDF em `docs/relatorio-final.pdf` fica como alternativa.
- As URLs das aplicações terminam em `/health`, o mesmo caminho usado pelas
  sondas e pelo monitor do balanceador.
- Os links do Docker Hub apontam para o repositório público, não para uma tag
  fixa. A tag usada no deploy é `1.1.0`.
- A matrícula de Ranya e os e-mails serão preenchidos por ela na revisão.
