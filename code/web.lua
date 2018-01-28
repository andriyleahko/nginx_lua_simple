 local mysql = require "resty.mysql"
 local db, err = mysql:new()




 local ok, err, errcode, sqlstate = db:connect{
     host = "172.20.0.3",
     database = "test1",
     user = "root",
     password = "root",


 }




res, err, errcode, sqlstate = db:query("insert users(name) values('aaa');")


