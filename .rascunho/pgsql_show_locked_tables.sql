
select pid, state, usename, query, query_start, application_name, client_addr
-- select pg_terminate_backend(pid)
-- select pg_cancel_backend(pid)
from pg_stat_activity 
where pid in (
  select pid from pg_locks l 
  join pg_class t on l.relation = t.oid 
  and t.relkind = 'r' 
  where t.relname in (
      'cestabasicacupom'
    , 'cupomfiscal'
    , 'dadostefdedicado'
    , 'formapagamentoefetuada'
    , 'itemcupomfiscal'
    , 'prevenda'
  )
);
