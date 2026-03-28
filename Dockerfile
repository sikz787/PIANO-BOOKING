FROM python:3.9-slim
RUN apt-get update && apt-get install -y unixodbc-dev gcc g++ curl gnupg2 \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg \
    && curl -fsSL https://packages.microsoft.com/config/debian/12/prod.list > /etc/apt/sources.list.d/mssql-release.list
RUN apt-get update && ACCEPT_EULA=Y apt-get install -y msodbcsql17
WORKDIR /app
COPY . .
RUN pip install flask pyodbc
EXPOSE 5000
CMD ["python", "app.py"]