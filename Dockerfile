FROM python:3.12-slim

WORKDIR /opt/requestbin

# System build/runtime dependencies for gevent and related packages
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        libevent-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies first for better layer caching
COPY requirements.txt /opt/requestbin/
RUN pip install --no-cache-dir -r requirements.txt

# Application code
COPY requestbin /opt/requestbin/requestbin/

EXPOSE 8000

CMD ["gunicorn", "-b", "0.0.0.0:8000", "--worker-class", "gevent", "--workers", "2", "--max-requests", "1000", "requestbin:app"]
