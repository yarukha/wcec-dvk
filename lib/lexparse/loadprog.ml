open Lexing
open Analysis

let print_position outx lb =
  let pos = lb.lex_curr_p in
  Printf.fprintf outx "%s:%d:%d" pos.pos_fname
    pos.pos_lnum (pos.pos_cnum - pos.pos_bol + 1)

let parse_with_errors lexbuf =
  try Dvkparser.program Dvklexer.token lexbuf with 
  |Dvklexer.SyntaxError msg ->
    Printf.fprintf stderr "%a: %s\n" print_position lexbuf msg;
    None
  |Dvk.UnknownInstruction msg-> 
    Printf.fprintf stderr "%a:\nUnknown instruction: %s\n" print_position lexbuf msg;
    None
  |Dvk.NotTranslated msg-> 
    Printf.fprintf stderr "%a:\nNot translated: %s\n" print_position lexbuf msg;
    None
  |Dvkparser.Error ->
    Printf.fprintf stderr "%a: syntax error\n" print_position lexbuf;
    exit (-1)

let prog lb = 
  match parse_with_errors lb with 
  |Some(p)->p 
  |None-> 
    failwith "empty file"
  