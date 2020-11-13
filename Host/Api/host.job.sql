if object_id('[host].[job]') is null begin
  create table [host].[job] (
    [id] bigint not null identity(1,1) primary key,
    [name] varchar(100) not null,
    [procedure] varchar(100) null,
    [due_date] datetime not null default current_timestamp,
    [description] nvarchar(400) null,
    unique ([name], [procedure])
  )

  create index ix__host_job__due_date
      on [host].[job] (due_date)
end
go
