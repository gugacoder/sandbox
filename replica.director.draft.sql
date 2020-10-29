declare @servidor varchar(100), @database varchar(100)
 select @servidor = DFservidor, @database = DFdatabase
   from DBdirector_MAC_29.dbo.TBempresa_mercadologic where DFcod_empresa = 7

--drop table if exists replica.caixa
exec replica.clonar_tabela_mercadologic 7, 'usuario', @servidor, @database
exec replica.clonar_tabela_mercadologic 7, 'sessao', @servidor, @database
exec replica.clonar_tabela_mercadologic 7, 'pdv', @servidor, @database
exec replica.clonar_tabela_mercadologic 7, 'caixa', @servidor, @database

select * from replica.usuario
select * from replica.sessao
select * from replica.pdv
select * from replica.caixa

