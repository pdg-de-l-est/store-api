<?php
namespace models;

use Ubiquity\attributes\items\Id;
use Ubiquity\attributes\items\Column;
use Ubiquity\attributes\items\Validator;
use Ubiquity\attributes\items\Table;

#[Table(name: "slot")]
class Slot{
	
	#[Id()]
	#[Column(name: "id",dbType: "int(11)")]
	#[Validator(type: "id",constraints: ["autoinc"=>true])]
	private $id;

	
	#[Column(name: "name",dbType: "time")]
	#[Validator(type: "type",constraints: ["ref"=>"time","notNull"=>true])]
	private $name;

	
	#[Column(name: "days",dbType: "varchar(20)")]
	#[Validator(type: "length",constraints: ["max"=>20,"notNull"=>true])]
	private $days;

	public function getId(){
		return $this->id;
	}

	public function setId($id){
		$this->id=$id;
	}

	public function getName(){
		return $this->name;
	}

	public function setName($name){
		$this->name=$name;
	}

	public function getDays(){
		return $this->days;
	}

	public function setDays($days){
		$this->days=$days;
	}

	 public function __toString(){
		return ($this->days??'no value').'';
	}

}