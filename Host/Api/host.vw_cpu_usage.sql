drop view if exists [host].[vw_cpu_usage]
go
create view [host].[vw_cpu_usage]
as
with usage as (
  select
    cpu_idle=record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int'),
    cpu_sql=record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int')
  from (
    select top 1 convert(xml, record) as record
      from sys.dm_os_ring_buffers
     where ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
       and record like '% %'
     order by timestamp desc
  ) as t
)
select 'CPU' as Counter
     , concat(100 - cpu_idle,'%') as Usage from usage
union all
select 'CPU by SQLServer'
     , concat(cpu_sql,'%') from usage
go
-- select * from host.vw_cpu_usage

