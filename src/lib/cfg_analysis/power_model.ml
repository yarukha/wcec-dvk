open Instructions
open Instr_tools

module M_s = Map.Make(String)
let empty_m = M_s.empty

module type Value_Type = sig 
  type t =float
  val compare : t -> t -> int
  val min : t -> t -> t
  val max : t -> t -> t
  val zero : t
  val range : t
  val add : t -> t -> t
  val minus : t -> t -> t
  val (<=) : t -> t -> bool
  val max_v : t 
  val to_string : t-> string
end

module type PowerModel = sig 
  include Value_Type
  val from_instr : instruction ->t 
  
  val from_native : string -> t M_s.t -> t 
end

module Value : Value_Type with type t = float = struct
  type t = float
  let compare = Float.compare
  let min = min 
  let max = max
  let zero = 0.
  let range = 1.
  let add = (+.)
  let minus = (-.)
  let (<=) = fun x y -> x<= y
  let max_v = max_float
  let to_string = Format.sprintf "%f"
end


module T : PowerModel= struct 
  include Value
  let from_instr instr= 
    let t= Array.make number_instructions 0. in 
    Random.init 32;
    for i = 0 to number_instructions -1 do 
      t.(i)<-Random.float 10.
    done;
    t.(instruction_id instr)
  let from_native s m = 
    match M_s.find_opt s m with 
    |None->20.
    |Some(x)->x
end

module E : PowerModel= struct 
  include Value
  let from_instr instr= 
    let t= Array.make number_instructions 0. in 
    Random.init 33;
    for i = 0 to number_instructions -1 do 
      t.(i)<-Random.float 20. 
    done;
    t.(instruction_id instr)
    let from_native s m = 
    match M_s.find_opt s m with 
    |None->50.
    |Some(x)->x
end

type p_m = Value.t M_s.t* Value.t M_s.t

module Block_Model(Et:PowerModel)(M: sig val m: Et.t M_s.t val given_value :Et.t end) = struct 
  include Et
  let given_value = M.given_value
  module S = Icfg.Block_Icfg.S_Meth 
  module T(Ord: Set.OrderedType ) = struct 
    type t = {t:Et.t;z:Ord.t}
    let compare (x:t) (y:t) = 
      let a = Et.compare x.t y.t in 
      if a=0 then Ord.compare x.z y.z else a
    end
  module Make_Value_set(Ord:Set.OrderedType)= struct 
    module X = T(Ord)
    include Set.Make(X)
    let add_v t z = add {z;t} 
    let value (x:X.t) = x.t
    let label (x:X.t) = x.z 
  end
  let over_max x = given_value <= x 
  let from_block def_meths (b:block) = 
    List.fold_left (
      fun t i -> match i.op with 
      |Opn(Invoke(_),_)->
        let m_id = List.hd i.args in 
        if S.mem (Block_id.from_meth_string m_id) def_meths
          then Et.add t (from_instr i) 
        else
          Et.add t (Et.add (from_native m_id M.m) (from_instr i))
      |_->Et.add t (from_instr i)
    ) zero b 
  let lt x y =
    Et.compare x y <0
  let lez x = 
    Et.(<=) x Et.zero
end