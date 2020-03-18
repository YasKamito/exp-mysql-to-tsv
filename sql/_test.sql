select * from user where id=12345

select * from users where user_id in (select id from user where id=12345)

select * from user_book where user_id in (select id from user where id=12345)

select * from book where id in (select book_id from user_book where user_id in (select id from user where id=12345))
