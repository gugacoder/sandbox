--
-- SCHEMA replica
--
create schema if not exists replica;

--
-- TABELA replica.texto
--
create table if not exists replica.texto (
  id serial not null primary key,
  texto varchar not null,
  constraint uq_texto unique (texto)
);

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
create index if not exists ix_evento_tabela on replica.evento (id_esquema,id_tabela);

--
-- VIEW replica.vw_evento
--
create or replace view replica.vw_evento as 
select evento.id
     , esquema.texto as esquema
     , tabela.texto as tabela
     , evento.chave
     , case evento.acao
         when 'I' then 'INSERT'
         when 'U' then 'UPDATE'
         when 'D' then 'DELETE'
         when 'T' then 'TRUNCATE'
       end as acao
     , evento.data
     , evento.versao
     , origem.texto as origem
  from replica.evento
 inner join replica.texto as esquema on esquema.id = evento.id_esquema
 inner join replica.texto as tabela  on tabela .id = evento.id_tabela
 inner join replica.texto as origem  on origem .id = evento.id_origem;

--
-- VIEW replica.vw_tabela_monitorada
--
create or replace view replica.vw_tabela_monitorada as 
select distinct 
       esquema.texto as esquema
     , tabela.texto as tabela
  from replica.evento
 inner join replica.texto as esquema on esquema.id = evento.id_esquema
 inner join replica.texto as tabela  on tabela .id = evento.id_tabela;

--
-- FUNCTION replica.registrar_evento
--
create or replace function replica.registrar_evento()
returns trigger as $$
begin
  RAISE NOTICE '%: % EM %.% MARCADO PARA REPLICACAO', TG_NAME, TG_OP, TG_TABLE_SCHEMA, TG_TABLE_NAME;
  insert into replica.texto (texto)
  values (TG_TABLE_SCHEMA)
       , (TG_TABLE_NAME)
       , (current_setting('application_name'))
      on conflict do nothing;
  if tg_op = 'DELETE' then
    insert into replica.evento (id_esquema, id_tabela, chave, acao, id_origem, versao)
    values (
           (select id from replica.texto where texto = TG_TABLE_SCHEMA)
         , (select id from replica.texto where texto = TG_TABLE_NAME)
         , (select chave from (select old.*) as t(chave))
         , LEFT(TG_OP,1)
         , (select id from replica.texto where texto = current_setting('application_name'))
         , old.xmin
           );
    return old;
  else
    insert into replica.evento (id_esquema, id_tabela, chave, acao, id_origem, versao)
    values (
           (select id from replica.texto where texto = TG_TABLE_SCHEMA)
         , (select id from replica.texto where texto = TG_TABLE_NAME)
         , (select chave from (select new.*) as t(chave))
         , LEFT(TG_OP,1)
         , (select id from replica.texto where texto = current_setting('application_name'))
         , new.xmin
           );
    return new;
  end if;
end
$$ language plpgsql;

--
-- FUNCTION replica.monitorar_tabela
--
create or replace function replica.monitorar_tabela(tabela varchar)
returns varchar as $$
declare
  esquema varchar;
begin
  if tabela like '%.%' then
    esquema := split_part(tabela, '.', 0);
    tabela := split_part(tabela, '.', 1);
  else
    esquema := 'public';
  end if;
  execute '
    drop trigger if exists tg_' || tabela || ' on ' || esquema || '.' || tabela || ';
    create trigger tg_' || tabela || '
    after insert or update or delete
    on ' || esquema || '.' || tabela || '
    for each row
    execute procedure replica.registrar_evento();'
      using tabela;
  return
    'TRIGGER `tg_' || tabela || ''' ' ||
    'ANEXADA A TABELA `' || esquema || '.' || tabela || ''' ' ||
    'PARA MONITORAMENTO DE EVENTOS.';
end;
$$ language plpgsql;

-- exemplo:
-- insert into teste (texto, preco, data) values ('exemplo', 2.85, current_timestamp);
-- 
-- select * from replica.vw_evento
-- select * from cupomfiscal order by 1 desc limit 10
-- update cupomfiscal set codigo = 144 where id = 517053
