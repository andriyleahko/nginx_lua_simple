<?php

for ($i=1;$i<=500;$i++) {
    shell_exec('php run.php > /dev/null 2>/dev/null &');
}