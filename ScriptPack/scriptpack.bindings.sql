if object_id('scriptpack.bindings') is null begin
  create table scriptpack.bindings (
    kind varchar(400) primary key,
    name varchar(400)
  )
end