/*
select idcupomfiscal, * from itemcupomfiscal
order by 1 desc
limit 3
-- id_cupom: 518358
-- id_item_cupom: 2706348
*/

update cupomfiscal set frete = frete + 1
where id = 518358

select * from itemcupomfiscal

begin transaction;
delete from historico_venda_item;
update itemcupomfiscal set desconto = desconto + 1 where id = 2706348;
delete from itemcupomfiscal where id = 2706348;
select * from historico_venda_item;
rollback;
