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

