--
-- TABLE replica.texto
--
if object_id('replica.texto') is null
  create table replica.texto (
    id int not null primary key identity(1,1),
    texto varchar(400) not null
  )
go

if not exists(select 1 from sys.indexes where name = 'IX_replica_texto_texto')
  create index IX_replica_texto_texto on replica.texto (texto)
go