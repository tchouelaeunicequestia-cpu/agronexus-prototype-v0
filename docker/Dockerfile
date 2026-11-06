FROM pgvector/pgvector:pg17 AS vector

FROM postgis/postgis:17-3.5

COPY --from=vector /usr/lib/postgresql/17/lib/vector.so /usr/lib/postgresql/17/lib/vector.so
COPY --from=vector /usr/share/postgresql/17/extension/vector* /usr/share/postgresql/17/extension/
