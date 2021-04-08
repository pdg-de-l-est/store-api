<?php
namespace models;

use Ubiquity\attributes\items\Id;
use Ubiquity\attributes\items\Column;
use Ubiquity\attributes\items\Validator;
use Ubiquity\attributes\items\Transformer;
use Ubiquity\attributes\items\Table;
use Ubiquity\attributes\items\OneToMany;

#[Table(name: "user")]
class User{
	
	#[Id()]
	#[Column(name: "id",dbType: "int(11)")]
	#[Validator(type: "id",constraints: ["autoinc"=>true])]
	private $id;

	
	#[Column(name: "name",dbType: "varchar(60)")]
	#[Validator(type: "length",constraints: ["max"=>60,"notNull"=>true])]
	private $name;

	
	#[Column(name: "email",dbType: "varchar(100)")]
	#[Validator(type: "email",constraints: ["notNull"=>true])]
	#[Validator(type: "length",constraints: ["max"=>100])]
	private $email;

	
	#[Column(name: "password",dbType: "varchar(100)")]
	#[Validator(type: "length",constraints: ["max"=>100,"notNull"=>true])]
	#[Transformer(name: "password")]
	private $password;

	
	#[OneToMany(mappedBy: "user",className: "models\\Basket")]
	private $baskets;

	
	#[OneToMany(mappedBy: "user",className: "models\\Order")]
	private $orders;

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

	public function getEmail(){
		return $this->email;
	}

	public function setEmail($email){
		$this->email=$email;
	}

	public function getPassword(){
		return $this->password;
	}

	public function setPassword($password){
		$this->password=$password;
	}

	public function getBaskets(){
		return $this->baskets;
	}

	public function setBaskets($baskets){
		$this->baskets=$baskets;
	}

	 public function addBasket($basket){
		$this->baskets[]=$basket;
	}

	public function getOrders(){
		return $this->orders;
	}

	public function setOrders($orders){
		$this->orders=$orders;
	}

	 public function addOrder($order){
		$this->orders[]=$order;
	}

	 public function __toString(){
		return ($this->email??'no value').'';
	}

}