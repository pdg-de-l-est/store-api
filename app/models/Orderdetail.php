<?php
namespace models;

use Ubiquity\attributes\items\Id;
use Ubiquity\attributes\items\Column;
use Ubiquity\attributes\items\Validator;
use Ubiquity\attributes\items\Table;
use Ubiquity\attributes\items\ManyToOne;
use Ubiquity\attributes\items\JoinColumn;

#[Table(name: "orderdetail")]
class Orderdetail{
	
	#[Id()]
	#[Column(name: "idOrder",dbType: "int(11)")]
	#[Validator(type: "id",constraints: ["autoinc"=>true])]
	private $idOrder;

	
	#[Id()]
	#[Column(name: "idProduct",dbType: "int(11)")]
	#[Validator(type: "id",constraints: ["autoinc"=>true])]
	private $idProduct;

	
	#[Column(name: "quantity",dbType: "decimal(6,2)")]
	#[Validator(type: "notNull",constraints: [])]
	private $quantity;

	
	#[Column(name: "prepared",dbType: "tinyint(1)")]
	#[Validator(type: "isBool",constraints: ["notNull"=>true])]
	private $prepared;

	
	#[ManyToOne()]
	#[JoinColumn(className: "models\\Order",name: "idOrder")]
	private $order;

	
	#[ManyToOne()]
	#[JoinColumn(className: "models\\Product",name: "idProduct")]
	private $product;

	public function getIdOrder(){
		return $this->idOrder;
	}

	public function setIdOrder($idOrder){
		$this->idOrder=$idOrder;
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

	public function getPrepared(){
		return $this->prepared;
	}

	public function setPrepared($prepared){
		$this->prepared=$prepared;
	}

	public function getOrder(){
		return $this->order;
	}

	public function setOrder($order){
		$this->order=$order;
	}

	public function getProduct(){
		return $this->product;
	}

	public function setProduct($product){
		$this->product=$product;
	}

	 public function __toString(){
		return ($this->prepared??'no value').'';
	}

}