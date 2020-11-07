--
-- VIEW replica.vw_evento
--
drop view if exists replica.vw_evento
go
create view replica.vw_evento as 
select evento.id_evento
     , evento.cod_empresa
     , evento.replicado
     , evento.id_remoto
     , esquema.texto as esquema
     , tabela.texto as tabela
     , evento.chave
     , case evento.acao
         when 'I' then 'INSERT'
         when 'U' then 'UPDATE'
         when 'D' then 'DELETE'
         when 'T' then 'TRUNCATE'
       end as acao
     , evento.data
     , evento.versao
     , origem.texto as origem
  from replica.evento
 inner join replica.texto as esquema on esquema.id = evento.id_esquema
 inner join replica.texto as tabela  on tabela .id = evento.id_tabela
 inner join replica.texto as origem  on origem .id = evento.id_origem
go
