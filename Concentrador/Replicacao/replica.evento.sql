--
-- TABELA replica.evento
--
create table if not exists replica.evento (
  id serial not null primary key,
  id_esquema int not null
    constraint fk__replica_evento__replica_texto__esquema
    references replica.texto (id),
  id_tabela int not null
    constraint fk__replica_evento__replica_texto__tabela
    references replica.texto (id),
  id_origem int not null
    constraint fk__replica_evento__replica_texto__origem
    references replica.texto (id),
  cod_registro int not null,
  acao char(1) not null,
  data timestamp default current_timestamp not null
);

create index if not exists ix__replica_evento__id_esquema
    on replica.evento (id_esquema);

create index if not exists ix__replica_evento__id_tabela
    on replica.evento (id_tabela);

create index if not exists ix__replica_evento__id_origem
    on replica.evento (id_origem);
