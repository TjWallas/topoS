theory NM_Dependability_norefl_impl
imports NM_Dependability_norefl "../TopoS_Lists_Impl_Interface"
begin


code_identifier code_module NM_Dependability_norefl_impl => (Scala) NM_Dependability_norefl


section {* NetworkModel Dependability implementation *}


text {* Less-equal other nodes depend on the output of a node than its dependability level. *}
fun sinvar :: "'v list_graph \<Rightarrow> ('v \<Rightarrow> dependability_level) \<Rightarrow> bool" where
  "sinvar G nP = (\<forall> (e1,e2) \<in> set (edgesL G). (num_reachable_norefl G e1) \<le> (nP e1))"

fun verify_globals :: "'v list_graph \<Rightarrow> ('v \<Rightarrow> dependability_level) \<Rightarrow> unit \<Rightarrow> bool" where
  "verify_globals _ _ _ = True"


value "sinvar 
    \<lparr> nodesL = [1::nat,2,3,4], edgesL = [(1,2), (2,3), (3,4), (8,9),(9,8)] \<rparr>
    (\<lambda>e. 3)"
value "sinvar 
    \<lparr> nodesL = [1::nat,2,3,4,8,9,10], edgesL = [(1,2), (2,3), (3,4), (8,9),(9,8)] \<rparr>
    (\<lambda>e. 2)"



definition Dependability_norefl_offending_list:: "'v list_graph \<Rightarrow> ('v \<Rightarrow> dependability_level) \<Rightarrow> ('v \<times> 'v) list list" where
  "Dependability_norefl_offending_list = Generic_offending_list sinvar"



definition "NetModel_node_props P = (\<lambda> i. (case (node_properties P) i of Some property \<Rightarrow> property | None \<Rightarrow> NM_Dependability_norefl.default_node_properties))"
lemma[code_unfold]: "NetworkModel.node_props NM_Dependability_norefl.default_node_properties P = NetModel_node_props P"
apply(simp add: NetModel_node_props_def)
done

definition "Dependability_norefl_eval G P = (valid_list_graph G \<and> 
  verify_globals G (NetworkModel.node_props NM_Dependability_norefl.default_node_properties P) (model_global_properties P) \<and> 
  sinvar G (NetworkModel.node_props NM_Dependability_norefl.default_node_properties P))"



lemma sinvar_correct: "valid_list_graph G \<Longrightarrow> NM_Dependability_norefl.sinvar (list_graph_to_graph G) nP = sinvar G nP"
   apply(simp)
   apply(rule all_edges_list_I)
   apply(simp add: fun_eq_iff)
   apply(clarify)
   apply(rename_tac x)
   apply(drule_tac v="x" in  num_reachable_norefl_correct)
   apply presburger
done



interpretation Dependability_norefl_impl:TopoS_List_Impl 
  where default_node_properties=NM_Dependability_norefl.default_node_properties
  and sinvar_spec=NM_Dependability_norefl.sinvar
  and sinvar_impl=sinvar
  and verify_globals_spec=NM_Dependability_norefl.verify_globals
  and verify_globals_impl=verify_globals
  and target_focus=NM_Dependability_norefl.target_focus
  and offending_flows_impl=Dependability_norefl_offending_list
  and node_props_impl=NetModel_node_props
  and eval_impl=Dependability_norefl_eval
 apply(unfold TopoS_List_Impl_def)
 apply(rule conjI)
  apply(rule conjI)
   apply(simp add: TopoS_Dependability_norefl)
  apply(rule conjI)
   apply(intro allI impI)
   apply(fact sinvar_correct)
  apply(simp)
 apply(rule conjI)
  apply(unfold Dependability_norefl_offending_list_def)
  apply(intro allI impI)
  apply(rule Generic_offending_list_correct)
   apply(assumption)
  apply(intro allI impI)
  apply(simp only: sinvar_correct)
 apply(rule conjI)
  apply(intro allI)
  apply(simp only: NetModel_node_props_def)
  apply(metis Dependability.node_props.simps Dependability.node_props_eq_node_props_formaldef)
 apply(simp only: Dependability_norefl_eval_def)
 apply(intro allI impI)
 apply(rule TopoS_eval_impl_proofrule[OF TopoS_Dependability_norefl])
  apply(simp only: sinvar_correct)
 apply(simp)
done


section {* packing *}
  definition NM_LIB_Dependability_norefl :: "('v::vertex, NM_Dependability_norefl.dependability_level, unit) TopoS_packed" where
    "NM_LIB_Dependability_norefl \<equiv> 
    \<lparr> nm_name = ''Dependability_norefl'', 
      nm_target_focus = NM_Dependability_norefl.target_focus,
      nm_default = NM_Dependability_norefl.default_node_properties, 
      nm_sinvar = sinvar,
      nm_verify_globals = verify_globals,
      nm_offending_flows = Dependability_norefl_offending_list, 
      nm_node_props = NetModel_node_props,
      nm_eval = Dependability_norefl_eval
      \<rparr>"
  interpretation NM_LIB_Dependability_norefl_interpretation: TopoS_modelLibrary NM_LIB_Dependability_norefl
      NM_Dependability_norefl.sinvar NM_Dependability_norefl.verify_globals
    apply(unfold TopoS_modelLibrary_def NM_LIB_Dependability_norefl_def)
    apply(rule conjI)
     apply(simp)
    apply(simp)
    by(unfold_locales)


hide_fact (open) sinvar_correct
hide_const (open) sinvar verify_globals NetModel_node_props

end
