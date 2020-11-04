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
