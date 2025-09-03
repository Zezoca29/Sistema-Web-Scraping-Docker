# 🕷️ Distributed Web Scraping System

⚡ **Escalável. Observável. Resiliente.**
Um sistema de **Web Scraping distribuído** com **monitoramento em tempo real**, usando **Celery + Redis + Prometheus + Grafana**.

<p align="center">
  <img src="https://img.shields.io/badge/python-3.11-blue?style=for-the-badge&logo=python" />
  <img src="https://img.shields.io/badge/docker-compose-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white" />
  <img src="https://img.shields.io/badge/grafana-%23F46800.svg?style=for-the-badge&logo=grafana&logoColor=white" />
  <img src="https://img.shields.io/badge/prometheus-%23E6522C.svg?style=for-the-badge&logo=prometheus&logoColor=white" />
  <img src="https://img.shields.io/badge/redis-%23DD0031.svg?style=for-the-badge&logo=redis&logoColor=white" />
</p>  

---

## 🚀 Visão Geral

Este projeto resolve o problema de **raspagem massiva de páginas web** de forma:

* 🔥 **Distribuída** – múltiplos workers processando jobs em paralelo.
* 🧠 **Inteligente** – filas controladas via **Redis**.
* 📊 **Monitorada** – métricas em tempo real com **Prometheus + Grafana**.
* 💪 **Resiliente** – tolera falhas de scraping e reprocessa URLs automaticamente.

---

## 🏗️ Arquitetura

```
                 ┌────────────┐
                 │   Cliente   │
                 └──────┬─────┘
                        │
                  HTTP Requests
                        │
                 ┌──────▼─────┐
                 │    API     │  ← expõe métricas (/metrics)
                 └──────┬─────┘
                        │ Envia jobs
                 ┌──────▼─────┐
                 │   Redis    │  ← fila de scraping
                 └──────┬─────┘
          ┌─────────────┴─────────────┐
          │                           │
 ┌────────▼────────┐          ┌───────▼────────┐
 │   Worker 1      │          │   Worker N     │
 │ Celery + Scraper │   ...    │ Celery + Scraper│
 └────────┬────────┘          └───────┬────────┘
          │                           │
     Jobs concluídos            Jobs concluídos
          │                           │
     ┌────▼────┐                 ┌────▼────┐
     │ Database│                 │ Storage │
     └─────────┘                 └─────────┘
```

---

## 📊 Monitoramento

* **Prometheus (9090)** → coleta métricas da API e workers.
* **Grafana (3000)** → dashboards com insights em tempo real.
* **Redis (6379)** → monitoramento de filas e jobs.

### 🔑 Métricas disponíveis

* `api_requests_total` → total de requisições.
* `queue_jobs_total` → jobs enfileirados.
* `scrape_success_total` → scrapes bem-sucedidos.
* `scrape_fail_total` → falhas no scraping.
* `api_request_latency` → latência das requisições.
* `process_resident_memory_bytes` → memória usada.

---

## ⚙️ Como Rodar

### 1. Clone o repositório

```bash
git clone https://github.com/seu-usuario/distributed-web-scraping.git](https://github.com/Zezoca29/Sistema-Web-Scraping-Docker.git
cd distributed-web-scraping
```

### 2. Suba os containers

```bash
docker compose up -d --build
```

### 3. Acesse os serviços

* API → [http://localhost:8000](http://localhost:8000)
* Prometheus → [http://localhost:9090](http://localhost:9090)
* Grafana → [http://localhost:3000](http://localhost:3000) (login: `admin/admin`)

---

## 📈 Dashboard Grafana

<p align="center">
  <img src="https://grafana.com/static/img/logos/grafana/grafana.png" width="120"/>
</p>  

O Grafana já vem configurado com o dashboard **“Distributed Web Scraping System Monitor”**, incluindo:

* 📡 Tráfego da API (requisições/s, latência).
* 🕷️ Jobs processados (sucesso/falha).
* 🔴 Status das filas Redis.
* 🖥️ Uso de memória/CPU dos workers.

---

## 🤖 Scripts Úteis

* **Abrir dashboards de monitoramento**

```powershell
.\open_monitoring.ps1
```

* **Rodar health check**

```powershell
.\monitor_system.ps1
```

* **Gerar métricas de teste**

```powershell
.\test_working.ps1
```

---

## 🔮 Próximos Passos

* [ ] Configurar **alertas no Grafana** (falhas > X%).
* [ ] Adicionar métricas específicas do negócio (tempo médio por domínio).
* [ ] Monitoramento avançado de filas do Redis.
* [ ] Integração com **ELK Stack** para logs centralizados.

---

## 🏆 Por que esse projeto é insano?

* ✅ Arquitetura **real de produção**.
* ✅ **Observabilidade completa** (métricas, dashboards, health checks).
* ✅ Demonstração de **skills avançadas**: DevOps, Python, Distribuição, Monitoramento.

---

🔥 **Distributed Web Scraping System** é mais que um scraper — é um **exemplo de arquitetura escalável e profissional**, pronto para ser usado em projetos reais.

---

