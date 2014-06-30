theory SINVAR_CommunicationPartners
imports "../TopoS_Helper"
begin

subsection {* SecurityInvariant CommunicationPartners *}


text{*
Idea of this security requirement model:
  Only some nodes can communicate with Master nodes.
    It constraints who may access master nodes, Master nodes cann access the world (except other prohibited master nodes).
  A node configured as Master has a list of nodes that can access it.
  Also, in order to be able to access a Master node, the sender must be denoted as a node we Care about.
  By default, all nodes are set to DonTCare, thus they can no access Master nodes. But they can access 
  all other DontCare nodes and Care nodes.

  TL;DR: An access control list determines who can access a master node.
*}
datatype 'v node_config = DontCare | Care | Master "'v list"

definition default_node_properties :: "'v node_config"
  where  "default_node_properties = DontCare"

text{* Unrestricted accesses among DontCare nodes! *}

fun allowed_flow :: "'v node_config \<Rightarrow> 'v \<Rightarrow> 'v node_config \<Rightarrow> 'v \<Rightarrow> bool" where
  "allowed_flow DontCare s DontCare r = True" |
  "allowed_flow DontCare s Care r = True" |
  "allowed_flow DontCare s (Master _) r = False" |
  "allowed_flow Care s Care r = True" |
  "allowed_flow Care s DontCare r = True" |
  "allowed_flow Care s (Master M) r = (s \<in> set M)" |
  "allowed_flow (Master _) s (Master M) r = (s \<in> set M)" |
  "allowed_flow (Master _) s Care r = True" |
  "allowed_flow (Master _) s DontCare r = True" 


fun sinvar :: "'v graph \<Rightarrow> ('v \<Rightarrow> 'v node_config) \<Rightarrow> bool" where
  "sinvar G nP = (\<forall> (s,r) \<in> edges G. s \<noteq> r \<longrightarrow> allowed_flow (nP s) s (nP r) r)"

fun verify_globals :: "'v graph \<Rightarrow> ('v \<Rightarrow> 'v node_config) \<Rightarrow> 'b \<Rightarrow> bool" where
  "verify_globals _ _ _ = True"

definition receiver_violation :: "bool" where "receiver_violation = False"



subsubsection {*Preliminaries*}
  lemma sinvar_mono: "SecurityInvariant_withOffendingFlows.sinvar_mono sinvar"
    apply(simp only: SecurityInvariant_withOffendingFlows.sinvar_mono_def)
    apply(clarify)
    by auto
  
  interpretation SecurityInvariant_preliminaries
  where sinvar = sinvar
  and verify_globals = verify_globals
    apply unfold_locales
      apply(frule_tac finite_distinct_list[OF valid_graph.finiteE])
      apply(erule_tac exE)
      apply(rename_tac list_edges)
      apply(rule_tac ff="list_edges" in SecurityInvariant_withOffendingFlows.mono_imp_set_offending_flows_not_empty[OF sinvar_mono])
          apply(auto)[6]
     apply(auto simp add: SecurityInvariant_withOffendingFlows.is_offending_flows_def graph_ops)[1]
    apply(fact SecurityInvariant_withOffendingFlows.sinvar_mono_imp_is_offending_flows_mono[OF sinvar_mono])
   done


subsubsection {*ENRnr*}
  lemma CommunicationPartners_ENRnrSR: "SecurityInvariant_withOffendingFlows.sinvar_all_edges_normal_form_not_refl_SR sinvar allowed_flow"
    by(simp add: SecurityInvariant_withOffendingFlows.sinvar_all_edges_normal_form_not_refl_SR_def)
  lemma Unassigned_weakrefl: "\<forall> s r. allowed_flow DontCare s DontCare r"
    by(simp)
  lemma Unassigned_botdefault: "\<forall> s r. (nP r) \<noteq> DontCare \<longrightarrow> \<not> allowed_flow (nP s) s (nP r) r \<longrightarrow> \<not> allowed_flow DontCare s (nP r) r"
    apply(rule allI)+
    apply(case_tac "nP r")
      apply(simp_all)
    apply(case_tac "nP s")
      apply(simp_all)
    done
  lemma  "\<not> allowed_flow DontCare s (Master M) r" by(simp)
    
  lemma All_to_Unassigned: "\<forall> s r. allowed_flow (nP s) s DontCare r"
    by (rule allI, rule allI, case_tac "nP s", simp_all)
  lemma Unassigned_default_candidate: "\<forall> s r. \<not> allowed_flow (nP s) s (nP r) r \<longrightarrow> \<not> allowed_flow DontCare s (nP r) r"
    apply(rule allI)+
    apply(case_tac "nP s")
      apply(simp_all)
     apply(case_tac "nP r")
       apply(simp_all)
    apply(case_tac "nP r")
      apply(simp_all)
    done
  
  definition CommunicationPartners_offending_set:: "'v graph \<Rightarrow> ('v \<Rightarrow> 'v node_config) \<Rightarrow> ('v \<times> 'v) set set" where
  "CommunicationPartners_offending_set G nP = (if sinvar G nP then
      {}
     else 
      { {e \<in> edges G. case e of (e1,e2) \<Rightarrow> e1 \<noteq> e2 \<and> \<not> allowed_flow (nP e1) e1 (nP e2) e2} })"
  lemma CommunicationPartners_offending_set: 
  "SecurityInvariant_withOffendingFlows.set_offending_flows sinvar = CommunicationPartners_offending_set"
    apply(simp only: fun_eq_iff ENFnrSR_offending_set[OF CommunicationPartners_ENRnrSR] CommunicationPartners_offending_set_def)
    apply(rule allI)+
    apply(rename_tac G nP)
    apply(auto)
  done


interpretation CommunicationPartners: SecurityInvariant_ACS
where default_node_properties = default_node_properties
and sinvar = sinvar
and verify_globals = verify_globals
where "SecurityInvariant_withOffendingFlows.set_offending_flows sinvar = CommunicationPartners_offending_set"
  unfolding receiver_violation_def
  unfolding default_node_properties_def
  apply unfold_locales
    apply(rule ballI)
    apply (rule_tac f="f" in SecurityInvariant_withOffendingFlows.ENFnrSR_fsts_weakrefl_instance[OF CommunicationPartners_ENRnrSR Unassigned_weakrefl Unassigned_botdefault All_to_Unassigned])
     apply(simp)
    apply(simp)
  apply(erule default_uniqueness_by_counterexample_ACS)
  apply(rule_tac x="\<lparr> nodes={vertex_1,vertex_2}, edges = {(vertex_1,vertex_2)} \<rparr>" in exI, simp)
  apply(rule conjI)
   apply(simp add: valid_graph_def)
  apply(simp add: CommunicationPartners_offending_set CommunicationPartners_offending_set_def delete_edges_simp2)
  apply(case_tac otherbot, simp_all)
   apply(rule_tac x="(\<lambda> x. DontCare)(vertex_1 := DontCare, vertex_2 := Master [vertex_1])" in exI, simp)
   apply(rule_tac x="vertex_1" in exI, simp)
   apply(simp split: split_split)
   apply(clarify)
   apply force
  apply(rename_tac M) (*case Master M*)
  apply(rule_tac x="(\<lambda> x. DontCare)(vertex_1 := DontCare, vertex_2 := (Master (vertex_1#M')))" in exI, simp)
  apply(simp split: split_split)
  apply(clarify)
  apply force
 apply(fact CommunicationPartners_offending_set)
done


  lemma TopoS_SubnetsInGW: "SecurityInvariant sinvar default_node_properties receiver_violation"
  unfolding receiver_violation_def by unfold_locales


hide_fact (open) sinvar_mono   
hide_const (open) sinvar verify_globals receiver_violation default_node_properties


end
