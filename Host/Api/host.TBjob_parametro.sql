--
-- TABLE host.TBjob_parametro
--
if object_id('host.TBjob_parametro') is null begin
--     DFcod_empresa int null,
--     DFnome_usuario nvarchar(100) null,
--     DFid_referente sql_variant null,
  create table host.TBjob_parametro (
    DFid_job_parametro bigint not null identity(1, 1) primary key,
    DFid_job bigint not null
      foreign key references host.TBjob (DFid_job)
           on delete cascade,
    DFparametro varchar(100) not null,
    DFvalor sql_variant null
  )

  create index IX__host_TBjob_parametro__DFid_job_DFparametro
      on host.TBjob_parametro (DFid_job, DFparametro)
end
go
