--
-- TABLE replica.evento
--
if object_id('replica.evento') is null
  create table replica.evento (
    id_evento bigint not null identity(1,1)
      constraint PK__replica_evento primary key,
    cod_empresa int not null,
    id_remoto int not null,
    id_esquema int not null
      constraint FK__replica_evento__replica_texto__esquema
      foreign key references replica.texto(id),
    id_tabela int not null
      constraint FK__replica_evento__replica_texto__tabela
      foreign key references replica.texto(id),
    chave int not null,
    acao char(1) not null,
    data datetime not null,
    --  0: Pendente
    --  1: Replicado com sucesso
    -- -1: Falha durante tentativa de replicação
    status int not null default 0,
    falha varchar(400) null,
    falha_detalhada varchar(max) null,
    versao int not null,
    id_origem int not null
      constraint FK__replica_evento__replica_texto__origem
      foreign key references replica.texto(id),
    constraint UQ_replica_evento
        unique (cod_empresa, id_remoto),
  )
go

if not exists(select 1 from sys.indexes where name = 'IX_replica_evento_status')
  create index IX_replica_evento_status on replica.evento (status)
go

if not exists(select 1 from sys.indexes where name = 'IX_replica_evento_esquema')
  create index IX_replica_evento_esquema on replica.evento (id_esquema)
go

if not exists(select 1 from sys.indexes where name = 'IX_replica_evento_tabela')
  create index IX_replica_evento_tabela on replica.evento (id_tabela)
go

if not exists(select 1 from sys.indexes where name = 'IX_replica_evento_origem')
  create index IX_replica_evento_origem on replica.evento (id_origem)
go
