open Lexparse
open Cfg_analysis
open Format

let usage_msg = "wcec [-verbose] -a <app.apk> [-p <powermodel>]"
let verbose = ref false
let input_app = ref ""
let input_pm = ref ""
let given_t = ref 500.
let given_e = ref 100000.
let unrefined = ref false
let progress = ref false
let speclist =
  [
    ("--verbose", Arg.Set verbose, "Output debug information");
    ("-a", Arg.Set_string input_app, "Set .apk file to analyse");
    ("-p", Arg.Set_string input_pm, "Set power model file to use");
    ("--given-time", Arg.Set_float given_t, "Set value to the given time in the analysis");
    ("--given-energy", Arg.Set_float given_e, "Set value to the given energy in the analysis");
    ("--unrefined", Arg.Set unrefined, "Analyse without refinement through static analysis of the execution bounds" );
    ("--progress", Arg.Set progress, "Show progress");
  ]

let anon_fun = 
  Format.printf "unknown argument: %s\n"




let () = 
  Arg.parse speclist anon_fun usage_msg;
  let cfg = 
    match !input_app with 
    |""->failwith "no .apk argument was given"
    |s when not (Filename.check_suffix s ".apk")->failwith (sprintf "the argument %s is not an apk" s)
    |file-> begin
      let f = Zip.open_in file in 
      let l  = Zip.entries f 
      |>List.filter (fun e -> Filename.check_suffix Zip.(e.filename) ".dex") in
      List.iter (fun e -> Zip.copy_entry_to_file f e e.filename ) l; 
      match Sys.command "dexdump -gdo g.dot *.dex" with 
      |0->let c = open_in "g.dot" in
        let lb = Lexing.from_channel c in 
        let cfg = Loadcfg.cfg lb in 
        let _ = Sys.command "rm *.dex g.dot" in 
        close_in c;
        cfg
      |_->failwith "couldnt execute dexdump"
    end in
  let p_m = 
    match !input_pm with 
    |""-> Power_model.empty_m,Power_model.empty_m
    |file->let c = open_in file in 
      let lb = Lexing.from_channel c in 
      let model = Loadmodel.model lb in 
      close_in c; model
  in
  let module S_key = Set.Make(Block_id) in
  let module M_key = Map.Make(Block_id) in 
  let def_meths = Icfg.Block_Icfg.defined_methods cfg in 
  let icfg = Icfg.Block_Icfg.create cfg def_meths in 
  let module M_c = struct 
    let mt = fst @@ p_m
    let me = snd @@ p_m
    let given_t = !given_t
    let given_e = !given_e
  end in 
  let module ILP_construct = Construct_ilp.Build(M_c) in

  printf "analysis of %s %s\ngiven_t = %f\n" !input_app (if !unrefined then "without refinment" else "with refinment") !given_t; flush stdout;
  let bound_map  = if !unrefined then M_key.empty  else AI.cnst_map icfg def_meths in 
  ILP_construct.analyze_icfg ~out:(None) ~progress:(!progress) icfg bound_map def_meths 