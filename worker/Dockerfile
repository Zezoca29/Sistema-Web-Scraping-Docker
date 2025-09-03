FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
# inicia um pequeno HTTP server (FastAPI) para receber lote de URLs e enfileirar
CMD ["uvicorn", "scraper:app", "--host", "0.0.0.0", "--port", "5555"]