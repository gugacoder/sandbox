--
-- TABELA replica.texto
--
create table if not exists replica.texto (
  id serial not null primary key,
  texto varchar not null,
  constraint uq_texto unique (texto)
);

create index if not exists ix_texto_texto
    on replica.texto (texto);
