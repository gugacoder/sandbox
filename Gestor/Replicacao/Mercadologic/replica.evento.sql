--
-- TABLE replica.evento
--
if object_id('replica.evento') is null
  create table replica.evento (
    id_evento bigint not null identity(1,1)
      constraint PK__replica_evento primary key,
    id_remoto int not null,
    id_esquema int not null
      constraint FK__replica_evento__replica_texto__esquema
      foreign key references replica.texto(id),
    id_tabela int not null
      constraint FK__replica_evento__replica_texto__tabela
      foreign key references replica.texto(id),
    id_origem int not null
      constraint FK__replica_evento__replica_texto__origem
      foreign key references replica.texto(id),
    cod_empresa int not null,
    cod_registro bigint not null,
    acao char(1) not null,
    data datetime not null,
    --  1: Replicado com sucesso
    --  0: Pendente
    -- -1: Falha durante tentativa de replicação
    -- -2: Falha durante de revisão da falha anterior
    status int not null default 0,
    falha varchar(400) null,
    falha_detalhada varchar(max) null,
    constraint UQ__replica_evento__cod_empresa__id_remoto
        unique (cod_empresa, id_remoto),
  )
go

if not exists(select 1 from sys.indexes where name = 'IX__replica_evento__id_esquema')
  create index IX__replica_evento__id_esquema on replica.evento (id_esquema)
go

if not exists(select 1 from sys.indexes where name = 'IX__replica_evento__id_tabela')
  create index IX__replica_evento__id_tabela on replica.evento (id_tabela)
go

if not exists(select 1 from sys.indexes where name = 'IX__replica_evento__id_origem')
  create index IX__replica_evento__id_origem on replica.evento (id_origem)
go

if not exists(select 1 from sys.indexes where name = 'IX__replica_evento__status')
  create index IX__replica_evento__status on replica.evento (status)
go

if not exists(select 1 from sys.indexes where name = 'IX__replica_evento__cod_registro')
  create index IX__replica_evento__cod_registro on replica.evento (cod_registro)
go
