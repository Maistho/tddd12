drop table if exists jbcheap;
drop view if exists jbsale_supply, jbcheapview, jbsaleview, jbsaleview2;


select * from jbemployee;

select name from jbdept
order by name;

select * from jbparts
where qoh = 0;

select * from jbemployee
where salary < 10001 and salary > 8999;

select name, startyear from jbemployee;

select name from jbemployee
where name like '%son,%';

select * from jbitem
where supplier = (
	select id from jbsupplier
	where name = 'Fisher-Price'
);

select jbitem.* from jbsupplier
inner join jbitem
on jbitem.supplier = jbsupplier.id
where jbsupplier.name = 'Fisher-Price';

select * from jbparts
where weight > (
	select weight from jbparts
	where name = 'card reader'
);

select t1.* from jbparts t1
join jbparts t2
on t1.weight > t2.weight
where t2.name = 'card reader';

select AVG(weight) from jbparts where color = 'black';

select jbsupplier.name, SUM(jbsupply.quan * jbparts.weight)
from jbparts
join jbsupply
on jbsupply.part = jbparts.id
join jbsupplier
on jbsupplier.id = jbsupply.supplier
join jbcity
on jbsupplier.city = jbcity.id
where jbcity.state = 'Mass'
group by jbsupplier.name;

create table jbcheap(
	id int auto_increment, item int,
	primary key (id),
	constraint fk_item foreign key (item) references jbitem(id)
);
insert into jbcheap(item)
select id from jbitem
where jbitem.price < (
	select avg(price)
	from jbitem
);
select jbitem.* from jbitem
join jbcheap
on jbitem.id = jbcheap.item;

create view jbcheapview as
select * from jbitem
where jbitem.price < (
	select avg(price)
	from jbitem
);
select * from jbcheapview;

create view jbsaleview as
select debit, sum(price * quantity)
from jbsale, jbitem
where jbsale.item = jbitem.id
group by debit;
select * from jbsaleview;

create view jbsaleview2 as
select debit, sum(price * quantity)
from jbsale
inner join jbitem
on item = id
group by debit;
select * from jbsaleview2;

delete from jbsupplier
where city = (
	select id from jbcity
	where name = 'Los Angeles'
);

create view jbsale_supply(supplier, item, quantity) as
select jbsupplier.name, jbitem.name, jbsale.quantity
from jbsupplier
join jbitem
on jbitem.supplier = jbsupplier.id
left join jbsale
on jbsale.item = jbitem.id;
select supplier, sum(quantity) sum from jbsale_supply
group by supplier;

