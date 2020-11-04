--
-- TABELA replica.evento
--
create table if not exists replica.evento (
  id serial not null primary key,
  id_esquema int not null,
  id_tabela int not null,
  chave int not null,
  acao char(1) not null,
  data timestamp default current_timestamp not null,
  versao xid not null,
  id_origem int not null
);

create index if not exists ix_evento_tabela
    on replica.evento (id_esquema,id_tabela);

