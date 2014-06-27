theory NM_Dependability_norefl
imports "../TopoS_Helper"
begin

section {* NetworkModel *}

text{*A version of the Dependability model but if a node reaches itself, it is ignored*}


type_synonym dependability_level = nat

definition default_node_properties :: "dependability_level"
  where  "default_node_properties \<equiv> 0"

text {* Less-equal other nodes depend on the output of a node than its dependability level. *}
fun sinvar :: "'v graph \<Rightarrow> ('v \<Rightarrow> dependability_level) \<Rightarrow> bool" where
  "sinvar G nP = (\<forall> (e1,e2) \<in> edges G. (num_reachable_norefl G e1) \<le> (nP e1))"

fun verify_globals :: "'v graph \<Rightarrow> ('v \<Rightarrow> dependability_level) \<Rightarrow> 'b \<Rightarrow> bool" where
  "verify_globals _ _ _ = True"

definition target_focus :: "bool" where 
  "target_focus \<equiv> False"




lemma unique_default_example: "succ_tran \<lparr>nodes = {vertex_1, vertex_2}, edges = {(vertex_1, vertex_2)}\<rparr> vertex_1 = {vertex_2}"
apply (simp add: succ_tran_def)
by (metis (lifting, no_types) Collect_cong Range.intros Range_empty Range_insert mem_Collect_eq singleton_conv singleton_iff trancl.r_into_trancl trancl_range)
lemma unique_default_example_simp1: "{(e1, e2). e1 = vertex_1 \<and> e2 = vertex_2 \<and> (e1 = vertex_1 \<longrightarrow> e2 \<noteq> vertex_2)} = {}" by blast
lemma unique_default_example_simp2: "{(vertex_1, vertex_2)}\<^sup>+ = {(vertex_1, vertex_2)}"
 apply(rule)
  apply(rule)
  apply(clarify)
  apply(rule_tac P="\<lambda> a b. a = vertex_1 \<and> b = vertex_2" in trancl.induct)
      apply auto
done



lemma sinvar_mono: "SecurityInvariant_withOffendingFlows.sinvar_mono sinvar"
  apply(rule_tac SecurityInvariant_withOffendingFlows.sinvar_mono_I_proofrule)
   apply(auto)
  apply(rename_tac nP e1 e2 N E' e1' e2' E)
  apply(drule_tac E'="E'" and v="e1'" in num_reachable_norefl_mono)
   apply simp
  apply(subgoal_tac "(e1', e2') \<in> E")
   apply(force)
  apply(blast)
 done
  

interpretation TopoS_preliminaries
where sinvar = sinvar
and verify_globals = verify_globals
  apply unfold_locales
    apply(frule_tac finite_distinct_list[OF valid_graph.finiteE])
    apply(erule_tac exE)
    apply(rename_tac list_edges)
    apply(rule_tac ff="list_edges" in SecurityInvariant_withOffendingFlows.mono_imp_set_offending_flows_not_empty[OF sinvar_mono])
        apply(auto)[5]
    apply(auto simp add: SecurityInvariant_withOffendingFlows.is_offending_flows_def graph_ops)[1]
   apply(fact SecurityInvariant_withOffendingFlows.sinvar_mono_imp_sinvar_mono[OF sinvar_mono])
  apply(fact SecurityInvariant_withOffendingFlows.sinvar_mono_imp_is_offending_flows_mono[OF sinvar_mono])
 done


interpretation Dependability: TopoS_ACS
where default_node_properties = NM_Dependability_norefl.default_node_properties
and sinvar = NM_Dependability_norefl.sinvar
and verify_globals = verify_globals
  unfolding NM_Dependability_norefl.default_node_properties_def
  apply unfold_locales
   apply simp
   apply (simp add: SecurityInvariant_withOffendingFlows.set_offending_flows_def
    SecurityInvariant_withOffendingFlows.is_offending_flows_min_set_def
    SecurityInvariant_withOffendingFlows.is_offending_flows_def)
   apply (simp split: split_split_asm split_split add:prod_case_beta)
   apply (simp add:graph_ops)
   apply(clarify)
   apply (metis gr0I le0)
  apply(erule default_uniqueness_by_counterexample_ACS)
  apply(simp)
  apply (simp add: SecurityInvariant_withOffendingFlows.set_offending_flows_def
      SecurityInvariant_withOffendingFlows.is_offending_flows_min_set_def
      SecurityInvariant_withOffendingFlows.is_offending_flows_def)
  apply (simp add:graph_ops)
  apply (simp split: split_split_asm split_split add:prod_case_beta)
  apply(rule_tac x="\<lparr> nodes={vertex_1,vertex_2}, edges = {(vertex_1,vertex_2)} \<rparr>" in exI, simp)
  apply(rule conjI)
   apply(simp add: valid_graph_def)
  apply(rule_tac x="(\<lambda> x. 0)(vertex_1 := 0, vertex_2 := 0)" in exI, simp)
  apply(rule conjI)
   apply(simp add: unique_default_example num_reachable_norefl_def)
  apply(rule_tac x="vertex_1" in exI, simp)
  apply(rule_tac x="{(vertex_1,vertex_2)}" in exI, simp)
  apply(simp add: unique_default_example num_reachable_norefl_def)
  apply(simp add: succ_tran_def unique_default_example_simp1 unique_default_example_simp2)
  done

  lemma TopoS_Dependability_norefl: "NetworkModel sinvar default_node_properties target_focus"
  unfolding target_focus_def by unfold_locales  

hide_const (open) sinvar verify_globals target_focus default_node_properties

end
