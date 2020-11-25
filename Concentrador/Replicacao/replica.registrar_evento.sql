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
         , 'D'
         , (select id from replica.texto where texto = current_setting('application_name'))
         , old.xmin
           );
    return old;
  elsif tg_op = 'INSERT' then
    insert into replica.evento (id_esquema, id_tabela, chave, acao, id_origem, versao)
    values (
           (select id from replica.texto where texto = TG_TABLE_SCHEMA)
         , (select id from replica.texto where texto = TG_TABLE_NAME)
         , (select chave from (select new.*) as t(chave))
         , 'I'
         , (select id from replica.texto where texto = current_setting('application_name'))
         , new.xmin
           );
    return new;
  elsif tg_op = 'UPDATE' then
    -- Ignorando UPDATE caso nenhum campo tenha sido realmente alterado.
    -- Se algum campo tiver sido alterado entaum o UNION entre OLD E NEW conterá dois registros.
    if 2 = (select count(1) from (select old.* union select new.*) as t) then
      insert into replica.evento (id_esquema, id_tabela, chave, acao, id_origem, versao)
      values (
             (select id from replica.texto where texto = TG_TABLE_SCHEMA)
           , (select id from replica.texto where texto = TG_TABLE_NAME)
           , (select chave from (select new.*) as t(chave))
           , 'U'
           , (select id from replica.texto where texto = current_setting('application_name'))
           , new.xmin
             );
    end if;
    return new;
  end if;
end
$$ language plpgsql;
