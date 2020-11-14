if object_id('[host].[job]') is null begin
  create table [host].[job] (
    [id] bigint not null identity(1,1) primary key,
    [name] varchar(100) not null,
    [procedure] varchar(100) null,
    [description] nvarchar(400) null,
    [disabled_at] datetime null,
    -- seg=1
    -- ter=2
    -- qua=4
    -- qui=8
    -- sex=16
    -- sab=32
    -- dom=64
    -- weekdays=31
    -- weekends=96
    [days] int not null,
    [time] time not null,
    -- Trata a data como um intervalo de repeticao.
    [repeat] bit not null default (0),
    -- Quando sequencial o intervalo de repeticao é contado somente
    -- depois da execução anterior ter terminado.
    [sequential] bit not null default (0),
    [start_date] datetime null,
    [end_date] datetime null,
    unique ([name], [procedure])
  )
end
go

/*
drop table host.job_schedule
drop table host.job_history_parameter
drop table host.job_history
drop table host.job_parameter
drop table host.job
*/
