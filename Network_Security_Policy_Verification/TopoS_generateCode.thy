theory TopoS_generateCode
imports TopoS_Library
begin




(* code_identifier code_module TopoS_generateCode => (Scala) TopoS_modelLibrary *)


ML {*
fun scala_header thy =
  let
    val package = "package tum.in.net.psn.log_topo.NetworkModels.GENERATED";   
    val date = Date.toString (Date.fromTimeLocal (Time.now ()));
    val export_file = Context.theory_name thy ^ ".thy";
    val header = package ^ "\n" ^ "// Generated by Isabelle (" ^ Distribution.version ^ ") on " ^ date ^ "\n" ^ "// src: " ^ export_file ^ "\n";
  in
    Code_Target.set_printings (Code_Symbol.Module ("", [("Scala", SOME (header, []))])) thy
  end
*}




  section {* export ALL the code *}

  setup {* scala_header *}
  export_code 
    (*network security requirement models*)
        NM_LIB_BLPbasic
        NM_LIB_Dependability
        (*NM_LIB_DomainHierarchy*)
        NM_LIB_DomainHierarchyNG
        NM_LIB_Subnets
        NM_LIB_BLPtrusted 
        (*NM_LIB_SecurityGateway*)
        NM_LIB_SecurityGatewayExtended
        NM_LIB_Sink
        NM_LIB_NonInterference
        NM_LIB_SubnetsInGW
        NM_LIB_CommunicationPartners
    (* packed model library access*)
        nm_eval
        nm_node_props
        nm_offending_flows
        nm_verify_globals
        nm_sinvar
        nm_default
        nm_target_focus nm_name
    (*TopoS_Params*)
        model_global_properties node_properties
    (*Finite_Graph functions*)
        FiniteListGraph.valid_list_graph
        FiniteListGraph.add_node 
        FiniteListGraph.delete_node
        FiniteListGraph.add_edge
        FiniteListGraph.delete_edge
        FiniteListGraph.delete_edges
    BLPexample1 BLPexample3 
    in Scala
    (*file "code/isabelle_generated.scala"*)
end
