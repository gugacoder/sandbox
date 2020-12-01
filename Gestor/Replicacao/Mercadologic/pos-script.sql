--
-- TODO: FIXME: Correções de objetos renomeados ou alterados durante a fase de
-- desenvolvimento.
--
drop procedure if exists replica.replicar_mercadologic_tabelas_pendentes
drop procedure if exists replica.replicar_mercadologic_tabela
alter table replica.evento
alter column cod_registro bigint not null
go

