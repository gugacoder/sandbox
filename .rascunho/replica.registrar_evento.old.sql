--
-- FUNCTION replica.registrar_evento
--
create or replace function replica.registrar_evento()
returns trigger as $$
declare
  -- parametros da insercao do evento
  cod_pdv int;
  -- parametros da identificao do pdv relacionado
  sql varchar(4000);
  campo_seletor_pdv_original varchar(100);
  campo_seletor_pdv_padronizado varchar(100);
begin
  RAISE NOTICE '%: % EM %.% MARCADO PARA REPLICACAO', TG_NAME, TG_OP, TG_TABLE_SCHEMA, TG_TABLE_NAME;

  --
  -- DESCOBRINDO O NUMERO DO PDV RELACIONADO AO REGISTRO
  --

  -- 1. Determinando o nome do campo usado na pesquisa do PDV.
  select coluna_original
       , coluna_padronizado
    into campo_seletor_pdv_original, campo_seletor_pdv_padronizado
    from (
    select column_name as coluna_original
         , case
             when column_name in ('idpdv', 'id_pdv') then 'id_pdv'
             when column_name in ('idcaixa', 'id_caixa') then 'id_caixa'
             when column_name in ('idsessao', 'id_sessao') then 'id_sessao'
             when column_name in ('idcupom', 'id_cupom', 'idcupomfiscal', 'id_cupom_fiscal') then 'id_cupom'
             when column_name in ('cupom', 'cupomfiscal', 'cupom_fiscal') then 'id_cupom'
           end as coluna_padronizado
         , case
             when column_name in ('idpdv', 'id_pdv') then 0
             when column_name in ('idcaixa', 'id_caixa') then 1
             when column_name in ('idsessao', 'id_sessao') then 2
             when column_name in ('idcupom', 'id_cupom', 'idcupomfiscal', 'id_cupom_fiscal') then 3
             when column_name in ('cupom', 'cupomfiscal', 'cupom_fiscal') then 4
           end as priority
      from information_schema.columns
     where column_name in (
             'idpdv', 'id_pdv',
             'idcaixa', 'id_caixa',
             'idsessao', 'id_sessao',
             'idcupom', 'id_cupom', 'idcupomfiscal', 'id_cupom_fiscal',
             'cupom', 'cupomfiscal', 'cupom_fiscal'
           )
       and data_type = 'integer'
       and table_schema = TG_TABLE_SCHEMA
       and table_name = TG_TABLE_NAME
    ) as t
   order by priority
   limit 1;

  -- 2. Realizando a consulta dinamica para identificacao do PDV
  sql := '
    select cast(pdv as int) from (
      select pdv.id as id_pdv
           , caixa.id as id_caixa
           , sessao.id as id_sessao
           , cupomfiscal.id as id_cupom
           , pdv.identificador as pdv
        from pdv
        left join caixa
               on caixa.idpdv = pdv.id
        left join sessao
               on sessao.idcaixa = caixa.id
        left join cupomfiscal
               on cupomfiscal.idsessao = sessao.id
      ) as t
     where '||campo_seletor_pdv_padronizado||' in (
             select '||campo_seletor_pdv_original||' from (select $1.*) as t(id)
           ) 
    limit 1';
  if TG_OP = 'DELETE' then
    execute sql into cod_pdv using old;
  else
    execute sql into cod_pdv using new;
  end if;

  --
  -- CADASTRANDO O NOME DO ESQUEMA E DA TABELA NA TABELA DE TEXTO
  --
  insert into replica.texto (texto)
  values (TG_TABLE_SCHEMA)
       , (TG_TABLE_NAME)
       , (current_setting('application_name'))
      on conflict do nothing;

  --
  -- REALIZANDO O REGISTRO DO EVENTO INSERT, UPDATE OU DELETE
  --
  if tg_op = 'DELETE' then
    insert into replica.evento (id_esquema, id_tabela, cod_pdv, cod_registro, acao, id_origem, versao)
    values (
           (select id from replica.texto where texto = TG_TABLE_SCHEMA)
         , (select id from replica.texto where texto = TG_TABLE_NAME)
         , cod_pdv
         , (select id  from (select old.*) as t(id))
         , 'D'
         , (select id from replica.texto where texto = current_setting('application_name'))
         , old.xmin
           );
    return old;
  elsif tg_op = 'INSERT' then
    insert into replica.evento (id_esquema, id_tabela, cod_pdv, cod_registro, acao, id_origem, versao)
    values (
           (select id from replica.texto where texto = TG_TABLE_SCHEMA)
         , (select id from replica.texto where texto = TG_TABLE_NAME)
         , cod_pdv
         , (select id  from (select new.*) as t(id))
         , 'I'
         , (select id from replica.texto where texto = current_setting('application_name'))
         , new.xmin
           );
    return new;
  elsif tg_op = 'UPDATE' then
    -- Ignorando UPDATE caso nenhum campo tenha sido realmente alterado.
    -- Se algum campo tiver sido alterado entaum o UNION entre OLD E NEW conterá dois registros.
    if 2 = (select count(1) from (select old.* union select new.*) as t) then
      insert into replica.evento (id_esquema, id_tabela, cod_pdv, cod_registro, acao, id_origem, versao)
      values (
             (select id from replica.texto where texto = TG_TABLE_SCHEMA)
           , (select id from replica.texto where texto = TG_TABLE_NAME)
           , cod_pdv
           , (select id  from (select new.*) as t(id))
           , 'U'
           , (select id from replica.texto where texto = current_setting('application_name'))
           , new.xmin
             );
    end if;
    return new;
  end if;
end
$$ language plpgsql;
