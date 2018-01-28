<?php

$con = new mysqli('localhost','root','root','test1','3306');

$con->query("insert users(name) values('aaa');");

