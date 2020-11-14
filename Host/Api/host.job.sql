if object_id('[host].[job]') is null begin
  create table [host].[job] (
    [id] bigint not null identity(1,1) primary key,
    [name] varchar(100) not null,
    [procedure] varchar(100) null,
    [description] nvarchar(400) null,
    [disabled_at] datetime null,
    -- Data de execu��o.
    -- Quando indicado `days` deve ser 0
    [due_date] datetime null,
    -- nenhum=0 <- Somente se `due_date` for indicado
    -- dom=1
    -- seg=2
    -- ter=4
    -- qua=8
    -- qui=16
    -- sex=32
    -- sab=64
    -- weekdays=62
    -- weekends=65
    -- everyday=127
    [days] int not null,
    -- Hora de execu��o.
    [time] time not null,
    -- Muda a interpreta��o de `time` para per�odo de execu��o.
    -- O JOB � executado no per�odo, depois 2 * per�odo, etc.
    [repeat] bit not null default (0),
    -- Se aplica apenas quanto `repeat` � indicado.
    -- Muda a interpreta��o de `time` para atraso entre execu��es.
    -- O JOB � executado seguidamente com um atraso entre cada execu��o.
    [delayed] bit not null default (0),
    [start_date] datetime null,
    [end_date] datetime null,
    unique ([name], [procedure])
  )
end
go

/*
drop table host.job_history
drop table host.job_parameter
drop table host.job
*/
