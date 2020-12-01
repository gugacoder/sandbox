--
-- TRIGGER public.tg__cupomfiscal__historico_venda
--
do $$ begin

  if not exists (select 1 from information_schema.triggers
    where trigger_schema = 'public' and trigger_name = 'tg__cupomfiscal__historico_venda__insert'
  ) then

    create trigger tg__cupomfiscal__historico_venda__insert
    after insert
    on public.cupomfiscal
    referencing
      new table as new_table 
    for statement
    execute procedure public.fn__cupomfiscal__historico_venda();

  end if;

  if not exists (select 1 from information_schema.triggers
    where trigger_schema = 'public' and trigger_name = 'tg__cupomfiscal__historico_venda__delete'
  ) then

    create trigger tg__cupomfiscal__historico_venda__delete
    after delete
    on public.cupomfiscal
    referencing
      old table as old_table
    for statement
    execute procedure public.fn__cupomfiscal__historico_venda();
    
  end if;

  if not exists (select 1 from information_schema.triggers
    where trigger_schema = 'public' and trigger_name = 'tg__cupomfiscal__historico_venda__update'
  ) then
    create trigger tg__cupomfiscal__historico_venda__update
    after update
    on public.cupomfiscal
    referencing
      old table as old_table
      new table as new_table
    for statement
    execute procedure public.fn__cupomfiscal__historico_venda();
  end if;

end $$;
