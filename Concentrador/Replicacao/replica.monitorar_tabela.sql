--
-- FUNCTION replica.monitorar_tabela
--
create or replace function replica.monitorar_tabela(tabela varchar)
returns void as $$
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

  RAISE NOTICE 'TRIGGER `tg_%s` ANEXADA A TABELA `%.%` PARA MONITORAMENTO DE EVENTOS.',
    tabela, esquema, tabela;
    
end;
$$ language plpgsql;
