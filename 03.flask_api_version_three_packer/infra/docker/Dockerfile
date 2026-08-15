FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5001

HEALTHCHECK --interval=30s --timeout=50s --start-period=20s --retries=3 CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5001/healthz')"

CMD [ "python","-m","gunicorn","-w","4","-b","0.0.0.0:5001","--access-logfile","-","--error-logfile","-","--timeout" ,"30","wsgi:app"]