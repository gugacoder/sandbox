--
-- TABLE host.TBjob
--
if object_id('host.TBjob') is null begin
  create table host.TBjob (
     DFid_job bigint not null identity(1,1) primary key,
     DFprocedure varchar(100) not null,
     DFdescricao nvarchar(100) null,
     DFdata_execucao datetime not null default current_timestamp
  )

  create index IX__host_TBjob__DFdata_execucao
      on host.TBjob (DFdata_execucao)
end
go
