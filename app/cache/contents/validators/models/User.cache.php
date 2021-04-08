<?php
return array("id"=>[["type"=>"id","constraints"=>["autoinc"=>true]]],"name"=>[["type"=>"length","constraints"=>["max"=>60,"notNull"=>true]]],"email"=>[["type"=>"email","constraints"=>["notNull"=>true]],["type"=>"length","constraints"=>["max"=>100]]],"password"=>[["type"=>"length","constraints"=>["max"=>100,"notNull"=>true]]]);
