<?php
namespace models;

use Ubiquity\attributes\items\Id;
use Ubiquity\attributes\items\Column;
use Ubiquity\attributes\items\Validator;
use Ubiquity\attributes\items\Table;
use Ubiquity\attributes\items\OneToMany;

#[Table(name: "section")]
class Section{
	
	#[Id()]
	#[Column(name: "id",dbType: "int(11)")]
	#[Validator(type: "id",constraints: ["autoinc"=>true])]
	private $id;

	
	#[Column(name: "name",dbType: "varchar(60)")]
	#[Validator(type: "length",constraints: ["max"=>60,"notNull"=>true])]
	private $name;

	
	#[Column(name: "description",nullable: true,dbType: "text")]
	private $description;

	
	#[OneToMany(mappedBy: "section",className: "models\\Product")]
	private $products;

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

	public function getDescription(){
		return $this->description;
	}

	public function setDescription($description){
		$this->description=$description;
	}

	public function getProducts(){
		return $this->products;
	}

	public function setProducts($products){
		$this->products=$products;
	}

	 public function addProduct($product){
		$this->products[]=$product;
	}

	 public function __toString(){
		return ($this->name??'no value').'';
	}

}