FROM mcr.microsoft.com/azure-sql-edge

ENV ACCEPT_EULA=Y
ENV SA_PASSWORD=Slava_IU_lab_ps

WORKDIR /app

EXPOSE 1433

USER root
RUN echo "root:slava" | chpasswd

CMD ["/opt/mssql/bin/sqlservr"]

# Запуск:
# Собираю образ
# docker build -t mssql-server .
# Запускаю контейнер
# docker run -d -p 1433:1433 --name my-msssql-container mssql-server
