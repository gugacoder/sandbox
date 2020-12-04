--
-- FUNCTION replica.monitorar_tabela
--
create or replace function replica.monitorar_tabela(tabela varchar)
returns void as $$
declare
  esquema varchar;
begin

  if tabela like '%.%' then
    esquema := split_part(tabela, '.', 1);
    tabela := split_part(tabela, '.', 2);
  else
    esquema := 'public';
  end if;

  --
  -- CRIANDO A TRIGGER DE REGISTRO DE EVENTOS
  --
  execute '
    drop trigger if exists tg_replicar_' || tabela || ' on ' || esquema || '.' || tabela || ';
    create trigger tg_replicar_' || tabela || '
    after insert or update or delete
    on ' || esquema || '.' || tabela || '
    for each row
    execute procedure replica.registrar_evento();'
      using tabela;

  RAISE NOTICE 'TRIGGER `tg_replicar_%s` ANEXADA A TABELA `%.%` PARA MONITORAMENTO DE EVENTOS.',
    tabela, esquema, tabela;
    
end;
$$ language plpgsql;
