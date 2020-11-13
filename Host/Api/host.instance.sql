if object_id('[host].[instance]') is null begin
  create table [host].[instance] (
    [id] int identity(1,1) primary key,
    [guid] uniqueidentifier not null,
    [version] varchar(50) not null,
    [device] nvarchar(255) not null,
    [ip] nvarchar(1024) not null,
    [on] bit not null default (1),
    [last_seen] datetime not null default (current_timestamp)
  )

  create index ix__host_instance__guid
      on [host].[instance] ([guid])
end
go
