if object_id('[host].[job]') is null begin
  create table [host].[job] (
    [id] bigint not null identity(1,1) primary key,
    [procedure] varchar(100) null,
    [due_date] datetime not null default current_timestamp,
    [description] nvarchar(100) null
  )

  create index ix__host_job__due_date
      on [host].[job] (due_date)
end
go
