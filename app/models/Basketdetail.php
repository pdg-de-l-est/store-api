<?php
namespace models;

use Ubiquity\attributes\items\Id;
use Ubiquity\attributes\items\Column;
use Ubiquity\attributes\items\Validator;
use Ubiquity\attributes\items\Table;
use Ubiquity\attributes\items\ManyToOne;
use Ubiquity\attributes\items\JoinColumn;

#[Table(name: "basketdetail")]
class Basketdetail{
	
	#[Id()]
	#[Column(name: "idBasket",dbType: "int(11)")]
	#[Validator(type: "id",constraints: ["autoinc"=>true])]
	private $idBasket;

	
	#[Id()]
	#[Column(name: "idProduct",dbType: "int(11)")]
	#[Validator(type: "id",constraints: ["autoinc"=>true])]
	private $idProduct;

	
	#[Column(name: "quantity",dbType: "int(11)")]
	#[Validator(type: "notNull",constraints: [])]
	private $quantity;

	
	#[ManyToOne()]
	#[JoinColumn(className: "models\\Basket",name: "idBasket")]
	private $basket;

	
	#[ManyToOne()]
	#[JoinColumn(className: "models\\Product",name: "idProduct")]
	private $product;

	public function getIdBasket(){
		return $this->idBasket;
	}

	public function setIdBasket($idBasket){
		$this->idBasket=$idBasket;
	}

	public function getIdProduct(){
		return $this->idProduct;
	}

	public function setIdProduct($idProduct){
		$this->idProduct=$idProduct;
	}

	public function getQuantity(){
		return $this->quantity;
	}

	public function setQuantity($quantity){
		$this->quantity=$quantity;
	}

	public function getBasket(){
		return $this->basket;
	}

	public function setBasket($basket){
		$this->basket=$basket;
	}

	public function getProduct(){
		return $this->product;
	}

	public function setProduct($product){
		$this->product=$product;
	}

	 public function __toString(){
		return ($this->quantity??'no value').'';
	}

}