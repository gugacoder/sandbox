drop function replica.get_pdv;
create or replace function replica.get_pdv(tabela varchar(100), valor_chave bigint)
returns int
as $$
declare
  pdv int;
  esquema varchar(100);
  sql varchar(4000);
  campo_chave varchar(100);
  campo_seletor_pdv varchar(100);
  query_seletor_pdv varchar(4000);
begin
  if tabela like '%.%' then
    esquema := SPLIT_PART(tabela,'.',1);
    tabela := SPLIT_PART(tabela,'.',2);
  else
    esquema := 'public';
  end if;

  select column_name
    into campo_chave
    from information_schema.columns
   where table_schema = esquema
     and table_name = tabela
   order by ordinal_position 
   limit 1;

  if (campo_chave is null) then
    raise exception 'A tabela não existe: %', tabela;
  end if;

  select coluna_ideal
       , 'select '||coluna_real||' 
            from '||esquema||'.'||tabela||'
           where '||campo_chave||' = '||valor_chave
    into campo_seletor_pdv, query_seletor_pdv
    from (
    select column_name as coluna_real
         , case
             when column_name in ('idpdv', 'id_pdv') then 'id_pdv'
             when column_name in ('idcaixa', 'id_caixa') then 'id_caixa'
             when column_name in ('idsessao', 'id_sessao') then 'id_sessao'
             when column_name in ('idcupom', 'id_cupom', 'idcupomfiscal', 'id_cupom_fiscal') then 'id_cupom'
             when column_name in ('cupom', 'cupomfiscal', 'cupom_fiscal') then 'id_cupom'
           end as coluna_ideal
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
       and table_schema = esquema
       and table_name = tabela
    ) as t
   order by priority
   limit 1;

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
     where '||campo_seletor_pdv||' in ('||query_seletor_pdv||') 
    limit 1';

  execute sql into pdv;

  return pdv;
end 
$$ language plpgsql;
