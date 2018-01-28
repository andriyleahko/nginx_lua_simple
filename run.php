<?php

for ($i=1;$i<=10;$i++) {
    //sleep(1);

        $curl = curl_init() ;
        curl_setopt($curl, CURLOPT_URL, 'http://test.local/hellolua');
        //curl_setopt($curl, CURLOPT_URL, 'http://localhost/db.php');
        curl_setopt($curl, CURLOPT_RETURNTRANSFER,true);
        $out = curl_exec($curl);
        //echo $out;
        curl_close($curl);
    //file_get_contents('http://test.local/hellolua');
}
