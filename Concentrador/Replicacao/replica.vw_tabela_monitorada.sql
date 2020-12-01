--
-- VIEW replica.vw_tabela_monitorada
--
create or replace view replica.vw_tabela_monitorada as 
select distinct
       cast(event_object_schema as character varying) as esquema
     , cast(event_object_table as character varying) as tabela
  from information_schema.triggers
 where trigger_name like 'tg_%'
   and action_statement = 'EXECUTE PROCEDURE replica.registrar_evento()'
;
