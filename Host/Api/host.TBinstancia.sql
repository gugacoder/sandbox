--
-- TABLE host.TBinstancia
--
if object_id('host.TBinstancia') is null begin
  create table host.TBinstancia (
    DFid_instancia int identity(1,1) primary key,
    DFguid uniqueidentifier not null,
    DFversao varchar(50) not null,
    DFdispositivo nvarchar(255) not null,
    DFip nvarchar(1024) not null,
    DFligado bit not null default (1),
    DFultima_vez_visto datetime not null default (current_timestamp)
  )

  create index ix__host_TBinstancia__DFguid
      on host.TBinstancia (DFguid)
end
go
