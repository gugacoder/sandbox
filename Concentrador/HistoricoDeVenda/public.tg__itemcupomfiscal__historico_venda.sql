--
-- TRIGGER public.tg__itemcupomfiscal__historico_venda
--
do $$ begin

  if not exists (select 1 from information_schema.triggers
    where trigger_schema = 'public' and trigger_name = 'tg__itemcupomfiscal__historico_venda__insert'
  ) then

    create trigger tg__itemcupomfiscal__historico_venda__insert
    after insert
    on public.itemcupomfiscal
    referencing
      new table as new_table 
    for statement
    execute procedure public.fn__itemcupomfiscal__historico_venda();

  end if;

  if not exists (select 1 from information_schema.triggers
    where trigger_schema = 'public' and trigger_name = 'tg__itemcupomfiscal__historico_venda__delete'
  ) then

    create trigger tg__itemcupomfiscal__historico_venda__delete
    after delete
    on public.itemcupomfiscal
    referencing
      old table as old_table
    for statement
    execute procedure public.fn__itemcupomfiscal__historico_venda();
    
  end if;

  if not exists (select 1 from information_schema.triggers
    where trigger_schema = 'public' and trigger_name = 'tg__itemcupomfiscal__historico_venda__update'
  ) then
    create trigger tg__itemcupomfiscal__historico_venda__update
    after update
    on public.itemcupomfiscal
    referencing
      old table as old_table
      new table as new_table
    for statement
    execute procedure public.fn__itemcupomfiscal__historico_venda();
  end if;

end $$;
