--
-- VIEW replica.vw_tabela_monitorada
--
create or replace view replica.vw_tabela_monitorada as 
select distinct 
       esquema.texto as esquema
     , tabela.texto as tabela
  from replica.evento
 inner join replica.texto as esquema on esquema.id = evento.id_esquema
 inner join replica.texto as tabela  on tabela .id = evento.id_tabela;

