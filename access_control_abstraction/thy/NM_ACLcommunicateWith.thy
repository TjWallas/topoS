theory NM_ACLcommunicateWith
imports NetworkModel_Interface NetworkModel_Helper vertex_example_simps
begin

text{*Warning: transitive model is slow model*}

section {* NetworkModel *}
text{*An access control list strategy that says that hosts must only transitively access each other if allowed*}

datatype 'v access_list = AccessList "'v list"

definition default_node_properties :: "'v access_list"
  where  "default_node_properties \<equiv> AccessList []"

fun accesses_okay :: "'v access_list \<Rightarrow> 'v set \<Rightarrow> bool" where
  "accesses_okay (AccessList ACL) accesses = (\<forall> a \<in> accesses. a \<in> set ACL)"

fun eval_model :: "'v graph \<Rightarrow> ('v \<Rightarrow> 'v access_list) \<Rightarrow> bool" where
  "eval_model G nP = (\<forall> v \<in> nodes G. accesses_okay (nP v) (succ_tran G v))"

fun verify_globals :: "'v graph \<Rightarrow> ('v \<Rightarrow> 'v access_list) \<Rightarrow> 'b \<Rightarrow> bool" where
  "verify_globals _ _ _ = True"

definition target_focus :: "bool" where 
  "target_focus \<equiv> False"


lemma eval_model_mono: "NetworkModel_withOffendingFlows.eval_model_mono eval_model"
  apply(simp only: NetworkModel_withOffendingFlows.eval_model_mono_def)
  apply(rule)+
  apply(clarify)
  proof -
    fix nP::"('v \<Rightarrow> 'v access_list)" and N E' E
    assume a1: "valid_graph \<lparr>nodes = N, edges = E\<rparr>"
    and    a2: "E' \<subseteq> E"
    and    a3: "eval_model \<lparr>nodes = N, edges = E\<rparr> nP"

    from a3 have "\<And>v ACL. v \<in> N \<Longrightarrow> nP v = AccessList ACL \<Longrightarrow> accesses_okay (nP v) (succ_tran \<lparr>nodes = N, edges = E\<rparr> v)" by fastforce
    hence "\<And>v ACL. v \<in> N \<Longrightarrow> nP v = AccessList ACL \<Longrightarrow> (\<forall> a \<in> (succ_tran \<lparr>nodes = N, edges = E\<rparr> v). a \<in> set ACL)" by simp
    from this a2 have g2: "\<And>v ACL. v \<in> N \<Longrightarrow> nP v = AccessList ACL \<Longrightarrow> (\<forall> a \<in> (succ_tran \<lparr>nodes = N, edges = E'\<rparr> v). a \<in> set ACL)"
      using succ_tran_mono[OF a1] by blast

    thus "eval_model \<lparr>nodes = N, edges = E'\<rparr> nP"
      apply(clarsimp)
      apply(rename_tac v)
      apply(case_tac "(nP v)")
      apply(simp)
      done
qed
  


lemma accesses_okay_empty: "accesses_okay (nP v) {}"
  by(case_tac "nP v", simp_all)


interpretation NetworkModel_preliminaries
where eval_model = eval_model
and verify_globals = verify_globals
  apply unfold_locales
    apply(frule_tac finite_distinct_list[OF valid_graph.finiteE])
    apply(erule_tac exE)
    apply(rename_tac list_edges)
    apply(rule_tac ff="list_edges" in NetworkModel_withOffendingFlows.mono_imp_set_offending_flows_not_empty[OF eval_model_mono])
        apply(auto)[5]
    apply(auto simp add: NetworkModel_withOffendingFlows.is_offending_flows_def graph_ops False_set succ_tran_empty accesses_okay_empty)[1]
   apply(fact NetworkModel_withOffendingFlows.eval_model_mono_imp_eval_model_mono[OF eval_model_mono])
  apply(fact NetworkModel_withOffendingFlows.eval_model_mono_imp_is_offending_flows_mono[OF eval_model_mono])
 done


lemma unique_default_example: "succ_tran \<lparr>nodes = {vertex_1, vertex_2}, edges = {(vertex_1, vertex_2)}\<rparr> vertex_2 = {}"
apply (simp add: succ_tran_def)
by (metis Domain.DomainI Domain_empty Domain_insert distince_vertices12 singleton_iff trancl_domain)

interpretation ACLcommunicateWith: NetworkModel
where default_node_properties = NM_ACLcommunicateWith.default_node_properties
and eval_model = NM_ACLcommunicateWith.eval_model
and verify_globals = verify_globals
and target_focus = target_focus
  unfolding target_focus_def
  unfolding NM_ACLcommunicateWith.default_node_properties_def
  apply unfold_locales
  
   apply simp
   apply(subst(asm) NetworkModel_withOffendingFlows.set_offending_flows_simp, simp)
   apply(clarsimp)
   apply (metis accesses_okay_empty)


  apply(case_tac "otherbot")
  apply(simp)
  apply (simp add: NetworkModel_withOffendingFlows.set_offending_flows_def
      NetworkModel_withOffendingFlows.is_offending_flows_min_set_def
      NetworkModel_withOffendingFlows.is_offending_flows_def)
  apply (simp add:graph_ops)
  apply (simp split: split_split_asm split_split add:prod_case_beta)
  thm List.neq_Nil_conv
  apply(simp add: List.neq_Nil_conv)
  apply(erule exE)
  apply(rename_tac canAccessThis)
  apply(case_tac "canAccessThis = vertex_1")
   apply(rule_tac x="\<lparr> nodes={canAccessThis,vertex_2}, edges = {(vertex_2,canAccessThis)} \<rparr>" in exI, simp)
   apply(rule conjI)
    apply(simp add: valid_graph_def)
   apply(rule_tac x="(\<lambda> x. AccessList [])(vertex_1 := AccessList [], vertex_2 := AccessList [])" in exI, simp)
   apply(simp add: example_simps)
   apply(rule_tac x="{(vertex_2,vertex_1)}" in exI, simp)
   apply(simp add: example_simps)
   apply(fastforce)

  apply(rule_tac x="\<lparr> nodes={vertex_1,canAccessThis}, edges = {(vertex_1,canAccessThis)} \<rparr>" in exI, simp)
  apply(rule conjI)
   apply(simp add: valid_graph_def)
  apply(rule_tac x="(\<lambda> x. AccessList [])(vertex_1 := AccessList [], canAccessThis := AccessList [])" in exI, simp)
  apply(simp add: example_simps)
  apply(rule_tac x="{(vertex_1,canAccessThis)}" in exI, simp)
  apply(simp add: example_simps)
  apply(fastforce)
 done

hide_const (open) eval_model verify_globals target_focus default_node_properties

end
