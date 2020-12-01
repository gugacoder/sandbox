--
-- TABELA replica.texto
--
create table if not exists replica.texto (
  id serial not null primary key,
  texto varchar null,
  constraint uq_texto unique (texto)
);

create index if not exists ix_texto_texto
    on replica.texto (texto);

-- Inserindo o valor vazio por padrão para ser usado no lugar de texto nulo.
insert into replica.texto (texto)
select '' where not exists (select 1 from replica.texto where texto = '')

