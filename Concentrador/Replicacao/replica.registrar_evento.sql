--
-- FUNCTION replica.registrar_evento
--
create or replace function replica.registrar_evento()
returns trigger as $$
declare
  aplicativo varchar;
begin

  aplicativo := 
    case when length(coalesce(current_setting('application_name'),'')) > 0
      then current_setting('application_name')
      else ''
    end;
  
  --
  -- CADASTRANDO O NOME DO ESQUEMA E DA TABELA NA TABELA DE TEXTO
  --
  insert into replica.texto (texto)
  values (TG_TABLE_SCHEMA), (TG_TABLE_NAME), (aplicativo)
  on conflict do nothing;

  --
  -- REALIZANDO O REGISTRO DO EVENTO INSERT, UPDATE OU DELETE
  --
  if tg_op = 'DELETE' then
    insert into replica.evento (id_esquema, id_tabela, id_origem, cod_registro, acao)
    values (
           (select id from replica.texto where texto = TG_TABLE_SCHEMA)
         , (select id from replica.texto where texto = TG_TABLE_NAME)
         , (select id from replica.texto where texto = aplicativo)
         , (select id  from (select old.*) as t(id))
         , 'D'
         );
    return old;
  elsif tg_op = 'INSERT' then
    insert into replica.evento (id_esquema, id_tabela, id_origem, cod_registro, acao)
    values (
           (select id from replica.texto where texto = TG_TABLE_SCHEMA)
         , (select id from replica.texto where texto = TG_TABLE_NAME)
         , (select id from replica.texto where texto = aplicativo)
         , (select id  from (select new.*) as t(id))
         , 'I'
         );
    return new;
  elsif tg_op = 'UPDATE' then
    -- Ignorando UPDATE caso nenhum campo tenha sido realmente alterado.
    -- Se algum campo tiver sido alterado entaum o UNION entre OLD E NEW conterá dois registros.
    if 2 = (select count(1) from (select old.* union select new.*) as t) then
      insert into replica.evento (id_esquema, id_tabela, id_origem, cod_registro, acao)
      values (
             (select id from replica.texto where texto = TG_TABLE_SCHEMA)
           , (select id from replica.texto where texto = TG_TABLE_NAME)
           , (select id from replica.texto where texto = aplicativo)
           , (select id  from (select new.*) as t(id))
           , 'U'
           );
    end if;
    return new;
  end if;

  RAISE NOTICE '%: % EM %.% MARCADO PARA REPLICACAO', TG_NAME, TG_OP, TG_TABLE_SCHEMA, TG_TABLE_NAME;
end
$$ language plpgsql;
