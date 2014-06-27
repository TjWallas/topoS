theory TopoS_ENF
imports Main TopoS_Interface TopoS_Util TopoS_withOffendingFlows_lemmata
begin



section {* NetworkModel theory: Often the @{term "sinvar"} function has a common structure.
  We call this the ll edges normal form (ENF). This file provides some theory for 
  @{term "sinvar"} functions in ENF. Helps instantiation of new models in ENF.*}


(*TODO most could be inherited from ENF_sr*)




section {* edges normal form ENF *}
  definition (in SecurityInvariant_withOffendingFlows) sinvar_all_edges_normal_form :: "('a \<Rightarrow> 'a \<Rightarrow> bool) \<Rightarrow> bool" where
    "sinvar_all_edges_normal_form P \<equiv> \<forall> G nP. sinvar G nP = (\<forall> (e1, e2)\<in> edges G. P (nP e1) (nP e2))"
  

  (* reflexivity is needed for convenience. If a network security model is not refexive, that means that all nodes with the default
    parameter \<bottom> are not allowed to communicate with each other *)
  definition (in SecurityInvariant_withOffendingFlows)  ENF_refl :: "('a \<Rightarrow> 'a \<Rightarrow> bool) \<Rightarrow> bool" where
    "ENF_refl P \<equiv> sinvar_all_edges_normal_form P \<and> (\<forall> p1. P p1 p1)"

    
  lemma (in SecurityInvariant_withOffendingFlows) monotonicity_sinvar_mono: "\<lbrakk> sinvar_all_edges_normal_form P \<rbrakk> \<Longrightarrow>
    sinvar_mono"
    apply(simp add: sinvar_all_edges_normal_form_def sinvar_mono_def)
    by blast

section {* offending flows:*}
  
  lemma (in SecurityInvariant_withOffendingFlows) ENF_is_offending_flow_ex_not_P:
    "\<lbrakk> sinvar_all_edges_normal_form P;
    is_offending_flows f G nP \<rbrakk>
    \<Longrightarrow> (\<exists> (e1, e2) \<in> edges G. \<not> P (nP e1) (nP e2))"
    unfolding sinvar_all_edges_normal_form_def
    unfolding is_offending_flows_def
    apply blast
    done
  lemma (in SecurityInvariant_withOffendingFlows) "sinvar_all_edges_normal_form P \<Longrightarrow>
    (f \<in> set_offending_flows G nP) \<and> f \<noteq> {} 
    \<Longrightarrow> (\<exists> (e1, e2) \<in> f.  \<not> P (nP e1) (nP e2))"
    unfolding sinvar_all_edges_normal_form_def
    apply(simp add: set_offending_flows_def is_offending_flows_def is_offending_flows_min_set_def graph_ops)
    apply clarify
    apply(blast)
  done
  
  
  lemma (in SecurityInvariant_withOffendingFlows) ENF_offending_imp_not_P: "sinvar_all_edges_normal_form P \<Longrightarrow>
    f \<in> set_offending_flows G nP \<Longrightarrow> (e1, e2) \<in> f 
    \<Longrightarrow> \<not> P (nP e1) (nP e2)"
    unfolding sinvar_all_edges_normal_form_def
    apply(simp add: set_offending_flows_def is_offending_flows_def is_offending_flows_min_set_def graph_ops)
    apply clarify
    by fastforce
  
  
  lemma (in SecurityInvariant_withOffendingFlows) ENF_offending_set_P_representation: 
    "sinvar_all_edges_normal_form P \<Longrightarrow> 
    f \<in> set_offending_flows G nP
    \<Longrightarrow> f = {(e1,e2). (e1, e2) \<in> edges G \<and> \<not> P (nP e1) (nP e2)}"
    apply rule
     apply rule
     apply clarify
     apply(rename_tac a b)
     apply rule
      apply(auto simp add:set_offending_flows_def)[1]
     apply(simp add: ENF_offending_imp_not_P[of P f G nP])
    unfolding sinvar_all_edges_normal_form_def
    apply(simp add:set_offending_flows_def is_offending_flows_def is_offending_flows_min_set_def graph_ops)
    apply clarify
    apply(rename_tac a b a1 b1)
    apply(blast)
  done
  
  
  (* We can show an overapproximation already: *)
  lemma (in SecurityInvariant_withOffendingFlows) ENF_offending_subseteq_lhs:
    "sinvar_all_edges_normal_form P \<Longrightarrow> 
    (set_offending_flows G nP) \<subseteq>
    { {(e1,e2). (e1, e2) \<in> edges G \<and> \<not> P (nP e1) (nP e2)} }"
    apply rule
    by(simp add: ENF_offending_set_P_representation[of P _ G nP])
  
  
  (* if offending flows not empty, we have the other direction *)
  lemma (in SecurityInvariant_withOffendingFlows) ENF_offenindg_not_empty_imp_ENF_offending_subseteq_rhs:
    "sinvar_all_edges_normal_form P \<Longrightarrow> 
    set_offending_flows G nP \<noteq> {}  \<Longrightarrow>
    { {(e1,e2). (e1, e2) \<in> edges G \<and> \<not> P (nP e1) (nP e2)} } \<subseteq> set_offending_flows G nP"
    apply rule
    apply(insert ENF_offending_set_P_representation[of P _ G nP],simp)[1]
    apply blast
   done
  
  
  
  
  lemma (in SecurityInvariant_withOffendingFlows) ENF_notevalmodel_offending_imp_ex_offending_min:
   "sinvar_all_edges_normal_form P \<Longrightarrow> 
   is_offending_flows f G nP \<Longrightarrow> f \<subseteq> edges G 
   \<Longrightarrow> \<exists>f'. f' \<subseteq> edges G \<and> is_offending_flows_min_set f' G nP"
    unfolding sinvar_all_edges_normal_form_def
    apply(simp only:is_offending_flows_def is_offending_flows_min_set_def)
    apply(simp only:graph_ops)
    apply simp
    (* select f' as the list of all edges of f which violate P *)
    apply(rule_tac x="{(e1,e2). (e1,e2) \<in> (edges G) \<and> \<not>P (nP e1) (nP e2)}" in exI) (* f better than edges G but proof harder *)
    apply simp
    apply force
  done
  
  lemma (in SecurityInvariant_withOffendingFlows) ENF_notevalmodel_imp_ex_offending:
  "\<lbrakk> sinvar_all_edges_normal_form P;
    \<not> sinvar G nP \<rbrakk> \<Longrightarrow>
    \<exists>f. f \<subseteq> (edges G) \<and> is_offending_flows f G nP"
    unfolding sinvar_all_edges_normal_form_def
    apply(simp add: Set.Ball_def)
    apply(simp only:is_offending_flows_def)
    apply(simp only:graph_ops)
    apply simp
    apply(rule_tac x="{(e1,e2). (e1,e2) \<in> (edges G) \<and> \<not>P (nP e1) (nP e2)}" in exI)
    apply(rule conjI)
     apply blast
    apply blast
  done
  
  lemma (in SecurityInvariant_withOffendingFlows) ENF_notevalmodel_imp_ex_offending_min:
  "\<lbrakk> sinvar_all_edges_normal_form P;
    \<not> sinvar G nP \<rbrakk> \<Longrightarrow>
    \<exists>f. f \<subseteq> edges G \<and> is_offending_flows_min_set f G nP"
    apply(frule ENF_notevalmodel_imp_ex_offending[of P G nP], simp)
    apply(erule exE)
    using ENF_notevalmodel_offending_imp_ex_offending_min[of P _ G nP] by fast
  
  lemma (in SecurityInvariant_withOffendingFlows) ENF_notevalmodel_imp_offending_not_empty:
  "sinvar_all_edges_normal_form P \<Longrightarrow> 
    \<not> sinvar G nP \<Longrightarrow>
    set_offending_flows G nP \<noteq> {}"
    apply(drule ENF_notevalmodel_imp_ex_offending_min[of P G nP], simp)
    apply(simp add: set_offending_flows_def)
   done
  
  lemma (in SecurityInvariant_withOffendingFlows) ENF_offending_case1:
    "\<lbrakk> sinvar_all_edges_normal_form P;  \<not> sinvar G nP \<rbrakk> \<Longrightarrow>
    { {(e1,e2). (e1, e2) \<in> (edges G) \<and> \<not> P (nP e1) (nP e2)} } = set_offending_flows G nP"
    apply(rule)
     apply(frule ENF_notevalmodel_imp_offending_not_empty, simp)
     apply(rule ENF_offenindg_not_empty_imp_ENF_offending_subseteq_rhs, simp)
     apply simp
    apply(rule ENF_offending_subseteq_lhs)
    apply simp
  done
  
  lemma (in SecurityInvariant_withOffendingFlows) ENF_offending_case2:
    "\<lbrakk> sinvar_all_edges_normal_form P; sinvar G nP \<rbrakk> \<Longrightarrow>
    {} = set_offending_flows G nP"
    apply(drule sinvar_no_offending[of G nP])
    apply simp
  done
  
  
  theorem (in SecurityInvariant_withOffendingFlows) ENF_offending_set:
    "\<lbrakk> sinvar_all_edges_normal_form P \<rbrakk> \<Longrightarrow>
    set_offending_flows G nP = (if sinvar G nP then
      {}
     else 
      { {(e1,e2). (e1, e2) \<in> edges G \<and> \<not> P (nP e1) (nP e2)} })"
  by(simp add: ENF_offending_case1 ENF_offending_case2)


section {* lemata *}

  lemma (in SecurityInvariant_withOffendingFlows)  ENF_offending_members:
    "\<lbrakk> \<not> sinvar G nP; sinvar_all_edges_normal_form P; f \<in> set_offending_flows G nP\<rbrakk> \<Longrightarrow> 
    f \<subseteq> (edges G) \<and> (\<forall> (e1, e2)\<in> f. \<not> P (nP e1) (nP e2))"
  by(auto simp add: ENF_offending_set)
 


section {* instance helper *}
  
  lemma (in SecurityInvariant_withOffendingFlows) ENF_refl_not_offedning:
        "\<lbrakk> \<not> sinvar G nP; f \<in> set_offending_flows G nP; 
          ENF_refl P\<rbrakk> \<Longrightarrow>
          \<forall>(e1,e2) \<in> f. e1 \<noteq> e2"
  proof -
  assume a_not_eval: "\<not> sinvar G nP"
    and   a_enf_refl: "ENF_refl P"
    and   a_offedning: "f \<in> set_offending_flows G nP"
  
    from a_enf_refl have a_enf: "sinvar_all_edges_normal_form P" using ENF_refl_def by simp
    hence a_ENF: "\<And> G nP. sinvar G nP  = (\<forall> (e1, e2) \<in> edges G. P (nP e1) (nP e2))" using sinvar_all_edges_normal_form_def by simp
    
    from a_enf_refl ENF_refl_def have a_refl: "\<forall> (e1,e1) \<in> f. P (nP e1) (nP e1)" by simp
    from ENF_offending_members[OF a_not_eval a_enf a_offedning] have "\<forall> (e1, e2) \<in> f. \<not> P (nP e1) (nP e2)" by fast
    from this a_refl show "\<forall>(e1,e2) \<in> f. e1 \<noteq> e2" by fast
  qed
  
  (* declare	[[show_types]] *)
  lemma (in SecurityInvariant_withOffendingFlows) ENF_default_update_fst: 
  fixes "default_node_properties" :: "'a" ("\<bottom>")
  assumes modelInv: "\<not> sinvar G nP"
    and   ENFdef: "sinvar_all_edges_normal_form P"
    and   secdef: "\<forall> (nP::'v \<Rightarrow> 'a) e1 e2. \<not> (P (nP e1) (nP e2)) \<longrightarrow> \<not> (P \<bottom> (nP e2))"
  shows
    "\<not> (\<forall> (e1, e2) \<in> edges G. P ((nP(i := \<bottom>)) e1) (nP e2))"
  proof -
    from ENFdef have ENF: "\<And> G nP. sinvar G nP  = (\<forall> (e1, e2)\<in> edges G. P (nP e1) (nP e2))" 
      using sinvar_all_edges_normal_form_def by simp
    from modelInv ENF have modelInv': "\<not> (\<forall> (e1, e2)\<in> edges G. P (nP e1) (nP e2))" by simp
    from this secdef have modelInv'': "\<not> (\<forall> (e1, e2)\<in> edges G. P \<bottom> (nP e2))" by blast
      have simpUpdateI: "\<And> e1 e2. \<not> P (nP e1) (nP e2) \<Longrightarrow> \<not> P \<bottom> (nP e2) \<Longrightarrow> \<not> P ((nP(i := \<bottom>)) e1) (nP e2)" by simp
      hence "\<And> X. \<exists>(e1,e2) \<in> X. \<not> P (nP e1) (nP e2) \<Longrightarrow> \<exists>(e1,e2) \<in> X.\<not> P \<bottom> (nP e2) \<Longrightarrow> \<exists>(e1,e2) \<in> X.\<not> P ((nP(i := \<bottom>)) e1) (nP e2)" 
        using secdef by blast
    from this modelInv' modelInv'' show "\<not> (\<forall> (e1, e2) \<in> edges G. P ((nP(i := \<bottom>)) e1) (nP e2))" by blast
  qed

  
  lemma (in SecurityInvariant_withOffendingFlows) 
    fixes "default_node_properties" :: "'a" ("\<bottom>")
    shows "\<not> sinvar G nP \<Longrightarrow> sinvar_all_edges_normal_form P \<Longrightarrow>
    (\<forall> (nP::'v \<Rightarrow> 'a) e1 e2. \<not> (P (nP e1) (nP e2)) \<longrightarrow>  \<not> (P \<bottom> (nP e2))) \<Longrightarrow>
    (\<forall> (nP::'v \<Rightarrow> 'a) e1 e2. \<not> (P (nP e1) (nP e2)) \<longrightarrow> \<not> (P (nP e1) \<bottom>)) \<Longrightarrow>
    (\<forall> (nP::'v \<Rightarrow> 'a) e1 e2. \<not> P \<bottom> \<bottom>)
    \<Longrightarrow> \<not> sinvar G (nP(i := \<bottom>))"
  proof -
    assume a1: "\<not> sinvar G nP"
    and   a2d: "sinvar_all_edges_normal_form P"
    and    a3: "\<forall> (nP::'v \<Rightarrow> 'a) e1 e2. \<not> (P (nP e1) (nP e2)) \<longrightarrow> \<not> (P \<bottom> (nP e2))"
    and    a4: "\<forall> (nP::'v \<Rightarrow> 'a) e1 e2. \<not> (P (nP e1) (nP e2)) \<longrightarrow> \<not> (P (nP e1) \<bottom>)"
    and    a5: "\<forall> (nP::'v \<Rightarrow> 'a) e1 e2. \<not> P \<bottom> \<bottom>"
  
    from a2d have a2: "\<And> G nP. sinvar G nP  = (\<forall> (e1, e2) \<in> edges G. P (nP e1) (nP e2))" 
      using sinvar_all_edges_normal_form_def by simp
  
    from ENF_default_update_fst[OF a1 a2d] a3 have subgoal1: "\<not> (\<forall> (e1, e2) \<in> edges G. P ((nP(i := \<bottom>)) e1) (nP e2))" by blast
    (*next asm*)
    
    let ?nP' = "(nP(i := \<bottom>))"
  
    from subgoal1 have "\<exists> (e1, e2) \<in> edges G. \<not> P (?nP' e1) (nP e2)" by blast
    from this obtain e11 e21 where s1cond: "(e11, e21) \<in> edges G \<and> \<not> P (?nP' e11) (nP e21)" by blast
  
    from s1cond have "i \<noteq> e11 \<Longrightarrow> \<not> P (nP e11) (nP e21)" by simp
    from s1cond have "e11 \<noteq> e21 \<Longrightarrow> \<not> P (?nP' e11) (?nP' e21)"
      apply simp
      apply(rule conjI)
       apply blast
      apply(insert a4)
      by force
    from s1cond a4 fun_upd_apply have ex1: "e11 \<noteq> e21 \<Longrightarrow> \<not> P (?nP' e11) (?nP' e21)" by metis
    from s1cond a5 have ex2: "e11 = e21 \<Longrightarrow> \<not> P (?nP' e11) (?nP' e21)" by auto
  
    from ex1 ex2 s1cond have "\<exists> (e1, e2) \<in> edges G. \<not> P (?nP' e1) (?nP' e2)" by blast
    hence "\<not> (\<forall> (e1, e2) \<in> edges G. P ((nP(i := \<bottom>)) e1) ((nP(i := \<bottom>)) e2))" by fast
    from this a2 show "\<not> sinvar G (nP(i := \<bottom>))" by presburger
  qed
  
  (* fsts version *)
  lemma (in SecurityInvariant_withOffendingFlows)  ENF_fsts_refl_instance:
    fixes "default_node_properties" :: "'a" ("\<bottom>")
    assumes a_enf_refl: "ENF_refl P"
    and   a3: "\<forall> (nP::'v \<Rightarrow> 'a) e1 e2. \<not> (P (nP e1) (nP e2)) \<longrightarrow> \<not> (P \<bottom> (nP e2))" (*changed \<And> to \<forall>*)
    and   a_offending: "f \<in> set_offending_flows G nP"
    and   a_i_fsts: "i \<in> fst ` f"
    shows
          "\<not> sinvar G (nP(i := \<bottom>))"
  proof -
    from a_offending have a_not_eval: "\<not> sinvar G nP" by (metis equals0D sinvar_no_offending)
    from valid_without_offending_flows[OF a_offending] have a_offending_rm: "sinvar (delete_edges G f) nP" .

    from a_enf_refl have a_enf: "sinvar_all_edges_normal_form P" using ENF_refl_def by simp
    hence a2: "\<And> G nP. sinvar G nP  = (\<forall> (e1, e2) \<in> edges G. P (nP e1) (nP e2))" using sinvar_all_edges_normal_form_def by simp
  
    from ENF_offending_members[OF a_not_eval a_enf a_offending] have a_f_3_in_f: "\<And> e1 e2. (e1, e2) \<in> f \<Longrightarrow> \<not> P (nP e1) (nP e2)" by fast
  
    let ?nP' = "(nP(i := \<bottom>))"
  
    (* obain from f *)
    from offending_not_empty[OF a_offending] ENF_offending_members[OF a_not_eval a_enf a_offending] a_i_fsts hd_in_set
      obtain e1 e2 where e1e2cond: "(e1, e2) \<in> f \<and> e1 = i" by force
  
    from conjunct1[OF e1e2cond] a_f_3_in_f have e1e2notP: "\<not> P (nP e1) (nP e2)" by simp
    from this a3 have "\<not> P \<bottom> (nP e2)" by simp
    from this e1e2notP have e1e2subgoal1: "\<not> P (?nP' e1) (nP e2)" by simp
  
    from ENF_refl_not_offedning[OF a_not_eval a_offending a_enf_refl] conjunct1[OF e1e2cond] have ENF_refl: "e1 \<noteq> e2" by fast
  
    from e1e2subgoal1 have "e1 \<noteq> e2 \<Longrightarrow> \<not> P (?nP' e1) (?nP' e2)"
      apply simp
      apply(rule conjI)
       apply blast
      apply(insert conjunct2[OF e1e2cond])
      by simp
  
    from this ENF_refl ENF_offending_members[OF a_not_eval a_enf a_offending]  conjunct1[OF e1e2cond] have 
      "\<exists> (e1, e2) \<in> edges G. \<not> P (?nP' e1) (?nP' e2)" by blast
    hence "\<not> (\<forall> (e1, e2) \<in> edges G. P ((nP(i := \<bottom>)) e1) ((nP(i := \<bottom>)) e2))" by fast
    from this a2 show "\<not> sinvar G (nP(i := \<bottom>))" by presburger
  qed

  (* snds version *)
  lemma (in SecurityInvariant_withOffendingFlows)  ENF_snds_refl_instance:
    fixes "default_node_properties" :: "'a" ("\<bottom>")
    assumes a_enf_refl: "ENF_refl P"
    and   a3: "\<forall> (nP::'v \<Rightarrow> 'a) e1 e2. \<not> (P (nP e1) (nP e2)) \<longrightarrow> \<not> (P (nP e1) \<bottom>)"
    and   a_offending: "f \<in> set_offending_flows G nP"
    and   a_i_snds: "i \<in> snd ` f"
    shows
          "\<not> sinvar G (nP(i := \<bottom>))"
  proof -
    from a_offending have a_not_eval: "\<not> sinvar G nP" by (metis equals0D sinvar_no_offending)
    from valid_without_offending_flows[OF a_offending] have a_offending_rm: "sinvar (delete_edges G f) nP" .
    from a_enf_refl have a_enf: "sinvar_all_edges_normal_form P" using ENF_refl_def by simp
    hence a2: "\<And> G nP. sinvar G nP  = (\<forall> (e1, e2) \<in> edges G. P (nP e1) (nP e2))" using sinvar_all_edges_normal_form_def by simp
  
    from ENF_offending_members[OF a_not_eval a_enf a_offending] have a_f_3_in_f: "\<And> e1 e2. (e1, e2) \<in> f \<Longrightarrow> \<not> P (nP e1) (nP e2)" by fast
  
    let ?nP' = "(nP(i := \<bottom>))"
  
    (* obain from f *)
    from offending_not_empty[OF a_offending] ENF_offending_members[OF a_not_eval a_enf a_offending] a_i_snds hd_in_set
      obtain e1 e2 where e1e2cond: "(e1, e2) \<in> f \<and> e2 = i" by force
  
    from conjunct1[OF e1e2cond] a_f_3_in_f have e1e2notP: "\<not> P (nP e1) (nP e2)" by simp
    from this a3 have "\<not> P (nP e1) \<bottom>" by auto
    from this e1e2notP have e1e2subgoal1: "\<not> P (nP e1) (?nP' e2)" by simp
  
    from ENF_refl_not_offedning[OF a_not_eval a_offending a_enf_refl] e1e2cond have ENF_refl: "e1 \<noteq> e2" by fast
  
    from e1e2subgoal1 have "e1 \<noteq> e2 \<Longrightarrow> \<not> P (?nP' e1) (?nP' e2)"
      apply simp
      apply(rule conjI)
       apply(insert conjunct2[OF e1e2cond])
       by simp_all
  
    from this ENF_refl e1e2cond ENF_offending_members[OF a_not_eval a_enf a_offending]  conjunct1[OF e1e2cond] have 
      "\<exists> (e1, e2) \<in> edges G. \<not> P (?nP' e1) (?nP' e2)" by blast
    hence "\<not> (\<forall> (e1, e2) \<in> edges G. P ((nP(i := \<bottom>)) e1) ((nP(i := \<bottom>)) e2))" by fast
    from this a2 show "\<not> sinvar G (nP(i := \<bottom>))" by presburger
  qed





(*ENF_sr*)


section {* edges normal form ENF with sender and receiver names *}
  definition (in SecurityInvariant_withOffendingFlows) sinvar_all_edges_normal_form_sr :: "('a \<Rightarrow> 'v \<Rightarrow> 'a \<Rightarrow> 'v \<Rightarrow> bool) \<Rightarrow> bool" where
    "sinvar_all_edges_normal_form_sr P \<equiv> \<forall> G nP. sinvar G nP = (\<forall> (s, r)\<in> edges G. P (nP s) s (nP r) r)"
  

  lemma (in SecurityInvariant_withOffendingFlows) ENFsr_monotonicity_sinvar_mono: "\<lbrakk> sinvar_all_edges_normal_form_sr P \<rbrakk> \<Longrightarrow>
    sinvar_mono"
    apply(simp add: sinvar_all_edges_normal_form_sr_def sinvar_mono_def)
    by blast

section {* offending flows:*}
  
  theorem (in SecurityInvariant_withOffendingFlows) ENFsr_offending_set:
    assumes ENFsr: "sinvar_all_edges_normal_form_sr P"
    shows "set_offending_flows G nP = (if sinvar G nP then
      {}
     else 
      { {(s,r). (s, r) \<in> edges G \<and> \<not> P (nP s) s (nP r) r} })" (is "?A = ?B")
  proof(cases "sinvar G nP")
  case True thus "?A = ?B" 
    by(simp add: set_offending_flows_def is_offending_flows_min_set_def is_offending_flows_def)
  next
  case False
   from ENFsr have ENFsr_offending_imp_not_P: "\<And> F s r. F \<in> set_offending_flows G nP \<Longrightarrow> (s, r) \<in> F  \<Longrightarrow> \<not> P (nP s) s (nP r) r"
     unfolding sinvar_all_edges_normal_form_sr_def
     apply(simp add: set_offending_flows_def is_offending_flows_def is_offending_flows_min_set_def graph_ops)
     apply clarify
     by fastforce
   from ENFsr have  ENFsr_offending_set_P_representation: 
    "\<And> F. F \<in> set_offending_flows G nP  \<Longrightarrow> F = {(s,r). (s, r) \<in> edges G \<and> \<not> P (nP s) s (nP r) r}"
      apply -
      apply rule
       apply rule
       apply clarify
       apply(rename_tac a b)
       apply rule
        apply(auto simp add:set_offending_flows_def)[1]
       apply(simp add: ENFsr_offending_imp_not_P)
      unfolding sinvar_all_edges_normal_form_sr_def
      apply(simp add:set_offending_flows_def is_offending_flows_def is_offending_flows_min_set_def graph_ops)
      apply clarify
      apply(rename_tac a b a1 b1)
      apply(blast)
    done
  

    from ENFsr False have ENFsr_offending_flows_exist: "set_offending_flows G nP \<noteq> {}"
      apply(simp add: set_offending_flows_def is_offending_flows_min_set_def is_offending_flows_def sinvar_all_edges_normal_form_sr_def
            delete_edges_def add_edge_def)
      apply(clarify)
      apply(rename_tac s r)
      apply(rule_tac x="{(s,r). (s,r) \<in> (edges G) \<and> \<not>P (nP s) s (nP r) r}" in exI)
      apply(simp)
      by blast

    from ENFsr have ENFsr_offenindg_not_empty_imp_ENF_offending_subseteq_rhs:
      "set_offending_flows G nP \<noteq> {}  \<Longrightarrow>
      { {(s,r). (s, r) \<in> edges G \<and> \<not> P (nP s) s (nP r) r} } \<subseteq> set_offending_flows G nP"
      apply -
      apply rule
      using ENFsr_offending_set_P_representation
      by blast

    from ENFsr have ENFsr_offending_subseteq_lhs:
      "(set_offending_flows G nP) \<subseteq> { {(s,r). (s, r) \<in> edges G \<and> \<not> P (nP s) s (nP r) r} }"
      apply -
      apply rule
      by(simp add: ENFsr_offending_set_P_representation)

    from False ENFsr_offenindg_not_empty_imp_ENF_offending_subseteq_rhs[OF ENFsr_offending_flows_exist] ENFsr_offending_subseteq_lhs show "?A = ?B"
      by force
  qed
  



(*ENFnrSR*)

section {* edges normal form not refl ENFnrSR *}
  definition (in SecurityInvariant_withOffendingFlows) sinvar_all_edges_normal_form_not_refl_SR :: "('a \<Rightarrow> 'v \<Rightarrow> 'a \<Rightarrow> 'v \<Rightarrow> bool) \<Rightarrow> bool" where
    "sinvar_all_edges_normal_form_not_refl_SR P \<equiv> 
    \<forall> G nP. sinvar G nP = (\<forall> (s, r) \<in> edges G. s \<noteq> r \<longrightarrow> P (nP s) s (nP r) r)"



  text{* we derive everything from the ENFnrSR form *}
  lemma (in SecurityInvariant_withOffendingFlows) ENFnrSR_to_ENFsr: 
    "sinvar_all_edges_normal_form_not_refl_SR P \<Longrightarrow> sinvar_all_edges_normal_form_sr (\<lambda> p1 v1 p2 v2. v1 \<noteq> v2 \<longrightarrow> P p1 v1 p2 v2)"
    by(simp add: sinvar_all_edges_normal_form_sr_def sinvar_all_edges_normal_form_not_refl_SR_def)
    


section {*offending flows*}
   theorem (in SecurityInvariant_withOffendingFlows) ENFnrSR_offending_set:
    "\<lbrakk> sinvar_all_edges_normal_form_not_refl_SR P \<rbrakk> \<Longrightarrow>
    set_offending_flows G nP = (if sinvar G nP then
      {}
     else 
      { {(e1,e2). (e1, e2) \<in> edges G \<and> e1 \<noteq> e2 \<and> \<not> P (nP e1) e1 (nP e2) e2} })"
    by(auto dest: ENFnrSR_to_ENFsr simp: ENFsr_offending_set)


section {* Instance helper*}

  (* fsts version *)
  lemma (in SecurityInvariant_withOffendingFlows)  ENFnrSR_fsts_weakrefl_instance:
    fixes "default_node_properties" :: "'a" ("\<bottom>")
    assumes a_enf: "sinvar_all_edges_normal_form_not_refl_SR P"
    and   a_weakrefl: "\<forall> s r. P \<bottom> s \<bottom> r"
    and   a_botdefault: "\<forall> s r. (nP r) \<noteq> \<bottom> \<longrightarrow> \<not> P (nP s) s (nP r) r \<longrightarrow> \<not> P \<bottom> s (nP r) r"
    and   a_alltobot: "\<forall> s r. P (nP s) s \<bottom> r"
    and   a_offending: "f \<in> set_offending_flows G nP"
    and   a_i_fsts: "i \<in> fst` f"
    shows
          "\<not> sinvar G (nP(i := \<bottom>))"
  proof -
    from a_offending have a_not_eval: "\<not> sinvar G nP" by (metis ex_in_conv sinvar_no_offending)
    from valid_without_offending_flows[OF a_offending] have a_offending_rm: "sinvar (delete_edges G f) nP" .
    from a_enf have a_enf': "\<And> G nP. sinvar G nP  = (\<forall> (e1, e2)\<in> (edges G). e1 \<noteq> e2 \<longrightarrow> P (nP e1) e1 (nP e2) e2)" 
      using sinvar_all_edges_normal_form_not_refl_SR_def by simp
  
    from ENFnrSR_offending_set[OF a_enf] a_not_eval a_offending have a_f_3_in_f: "\<And> e1 e2. (e1, e2)\<in>f \<Longrightarrow> \<not> P (nP e1) e1 (nP e2) e2" by(simp)
    from ENFnrSR_offending_set[OF a_enf] a_not_eval a_offending have a_f_3_neq: "\<And> e1 e2. (e1, e2)\<in>f \<Longrightarrow> e1 \<noteq> e2" by simp
  
    let ?nP' = "(nP(i := \<bottom>))"

    from ENFnrSR_offending_set[OF a_enf] a_not_eval a_offending a_i_fsts
      obtain e1 e2 where e1e2cond: "(e1, e2) \<in> f \<and> e1 = i" by fastforce

    from conjunct1[OF e1e2cond] a_offending have "(e1, e2) \<in> edges G"
      by (metis (lifting, no_types) SecurityInvariant_withOffendingFlows.set_offending_flows_def mem_Collect_eq set_rev_mp)
  
    from conjunct1[OF e1e2cond] a_f_3_in_f have e1e2notP: "\<not> P (nP e1) e1 (nP e2) e2" by simp
    from e1e2notP a_weakrefl have e1ore2neqbot: "(nP e1) \<noteq> \<bottom> \<or> (nP e2) \<noteq> \<bottom>" by fastforce
    from e1e2notP a_alltobot have "(nP e2) \<noteq> \<bottom>" by fastforce
    from this e1e2notP a_botdefault have "\<not> P \<bottom> e1 (nP e2) e2" by simp
    from this e1e2notP have e1e2subgoal1: "\<not> P (?nP' e1) e1 (nP e2) e2" by auto

    from a_f_3_neq e1e2cond have "e2 \<noteq> e1" by blast
  
    from e1e2subgoal1 have "e1 \<noteq> e2 \<Longrightarrow> \<not> P (?nP' e1) e1 (?nP' e2) e2"
      apply simp
      apply(rule conjI)
       apply blast
      apply(insert e1e2cond)
      by simp
    from this `e2 \<noteq> e1` have "\<not> P (?nP' e1) e1 (?nP' e2) e2" by simp
  
    from this `e2 \<noteq> e1` ENFnrSR_offending_set[OF a_enf] a_offending `(e1, e2) \<in> edges G` have 
      "\<exists> (e1, e2)\<in>(edges G). e2 \<noteq> e1 \<and> \<not> P (?nP' e1) e1 (?nP' e2) e2" by blast
    hence "\<not> (\<forall> (e1, e2)\<in>(edges G). e2 \<noteq> e1 \<longrightarrow> P ((nP(i := \<bottom>)) e1) e1 ((nP(i := \<bottom>)) e2) e2)" by fast
    from this a_enf' show "\<not> sinvar G (nP(i := \<bottom>))" by fast
  qed



  (* snds version *)
  lemma (in SecurityInvariant_withOffendingFlows)  ENFnrSR_snds_weakrefl_instance:
    fixes "default_node_properties" :: "'a" ("\<bottom>")
    assumes a_enf: "sinvar_all_edges_normal_form_not_refl_SR P"
    and   a_weakrefl: "\<forall> s r. P \<bottom> s \<bottom> r"
    and   a_botdefault: "\<forall> s r. (nP s) \<noteq> \<bottom> \<longrightarrow> \<not> P (nP s) s (nP r) r \<longrightarrow> \<not> P (nP s) s \<bottom> r"
    and   a_bottoall: "\<forall> s r. P \<bottom> s (nP r) r"
    and   a_offending: "f \<in> set_offending_flows G nP"
    and   a_i_snds: "i \<in> snd` f"
    shows
          "\<not> sinvar G (nP(i := \<bottom>))"
  proof -
    from a_offending have a_not_eval: "\<not> sinvar G nP" by (metis equals0D sinvar_no_offending)
    from valid_without_offending_flows[OF a_offending] have a_offending_rm: "sinvar (delete_edges G f) nP" .
    from a_enf have a_enf': "\<And> G nP. sinvar G nP  = (\<forall> (e1, e2)\<in>(edges G). e1 \<noteq> e2 \<longrightarrow> P (nP e1) e1 (nP e2) e2)" 
      using sinvar_all_edges_normal_form_not_refl_SR_def by simp
  
    from ENFnrSR_offending_set[OF a_enf] a_not_eval a_offending have a_f_3_in_f: "\<And> s r. (s, r)\<in>f \<Longrightarrow> \<not> P (nP s) s (nP r) r" by simp
    from ENFnrSR_offending_set[OF a_enf] a_not_eval a_offending have a_f_3_neq: "\<And> s r. (s, r)\<in>f \<Longrightarrow> s \<noteq> r" by simp
  
    let ?nP' = "(nP(i := \<bottom>))"

    from ENFnrSR_offending_set[OF a_enf] a_not_eval a_offending a_i_snds
      obtain e1 e2 where e1e2cond: "(e1, e2)\<in>f \<and> e2 = i" by fastforce

    from conjunct1[OF e1e2cond] a_offending have "(e1, e2) \<in> edges G"
      by (metis (lifting, no_types) SecurityInvariant_withOffendingFlows.set_offending_flows_def mem_Collect_eq set_rev_mp)
  
    from conjunct1[OF e1e2cond] a_f_3_in_f have e1e2notP: "\<not> P (nP e1) e1 (nP e2) e2" by simp
    from e1e2notP a_weakrefl have e1ore2neqbot: "(nP e1) \<noteq> \<bottom> \<or> (nP e2) \<noteq> \<bottom>" by fastforce
    from e1e2notP a_bottoall have x1: "(nP e1) \<noteq> \<bottom>" by fastforce
    from this e1e2notP a_botdefault have x2: "\<not> P (nP e1) e1 \<bottom> e2" by fast
    from this e1e2notP have e1e2subgoal1: "\<not> P (nP e1) e1 (?nP' e2) e2" by auto

    from a_f_3_neq e1e2cond have "e2 \<noteq> e1" by blast
  
    from e1e2subgoal1 have "e1 \<noteq> e2 \<Longrightarrow> \<not> P (?nP' e1) e1 (?nP' e2) e2" by(simp add: e1e2cond)
  
    from this `e2 \<noteq> e1` ENFnrSR_offending_set[OF a_enf] a_offending `(e1, e2) \<in> edges G` have 
      "\<exists> (e1, e2)\<in>(edges G). e2 \<noteq> e1 \<and> \<not> P (?nP' e1) e1 (?nP' e2) e2" by fastforce
    hence "\<not> (\<forall> (e1, e2)\<in>(edges G). e2 \<noteq> e1 \<longrightarrow> P ((nP(i := \<bottom>)) e1) e1 ((nP(i := \<bottom>)) e2) e2)" by fast
    from this a_enf' show "\<not> sinvar G (nP(i := \<bottom>))" by fast
  qed




(*ENFnr*)



section {* edges normal form not refl ENFnr *}
  definition (in SecurityInvariant_withOffendingFlows) sinvar_all_edges_normal_form_not_refl :: "('a \<Rightarrow> 'a \<Rightarrow> bool) \<Rightarrow> bool" where
    "sinvar_all_edges_normal_form_not_refl P \<equiv> \<forall> G nP. sinvar G nP = (\<forall> (e1, e2) \<in> edges G. e1 \<noteq> e2 \<longrightarrow> P (nP e1) (nP e2))"
  

  text{* we derive everything from the ENFnrSR form *}
  lemma (in SecurityInvariant_withOffendingFlows) ENFnr_to_ENFnrSR: 
    "sinvar_all_edges_normal_form_not_refl P \<Longrightarrow> sinvar_all_edges_normal_form_not_refl_SR (\<lambda> v1 _ v2 _. P v1 v2)"
    by(simp add: sinvar_all_edges_normal_form_not_refl_def sinvar_all_edges_normal_form_not_refl_SR_def)

  (*most of results are now implied from previous lemma*)

section {*offending flows*}
   theorem (in SecurityInvariant_withOffendingFlows) ENFnr_offending_set:
    "\<lbrakk> sinvar_all_edges_normal_form_not_refl P \<rbrakk> \<Longrightarrow>
    set_offending_flows G nP = (if sinvar G nP then
      {}
     else 
      { {(e1,e2). (e1, e2) \<in> edges G \<and> e1 \<noteq> e2 \<and> \<not> P (nP e1) (nP e2)} })"
    apply(drule ENFnr_to_ENFnrSR)
    by(drule(1) ENFnrSR_offending_set)


section {* Instance helper*}
  (* fsts version *)
  lemma (in SecurityInvariant_withOffendingFlows)  ENFnr_fsts_weakrefl_instance:
    fixes "default_node_properties" :: "'a" ("\<bottom>")
    assumes a_enf: "sinvar_all_edges_normal_form_not_refl P"
    and   a_botdefault: "\<forall> e1 e2. e2 \<noteq> \<bottom> \<longrightarrow> \<not> P e1 e2 \<longrightarrow> \<not> P \<bottom> e2"
    and   a_alltobot: "\<forall> e1. P e1 \<bottom>"
    and   a_offending: "f \<in> set_offending_flows G nP"
    and   a_i_fsts: "i \<in> fst` f"
    shows
          "\<not> sinvar G (nP(i := \<bottom>))"
  proof -
    from assms show ?thesis
    apply -
    apply(drule ENFnr_to_ENFnrSR)
    apply(drule ENFnrSR_fsts_weakrefl_instance)
         by auto
  qed
  
  (* snds version *)
  lemma (in SecurityInvariant_withOffendingFlows)  ENFnr_snds_weakrefl_instance:
    fixes "default_node_properties" :: "'a" ("\<bottom>")
    assumes a_enf: "sinvar_all_edges_normal_form_not_refl P"
    and   a_botdefault: "\<forall> e1 e2. \<not> P e1 e2 \<longrightarrow> \<not> P e1 \<bottom>"
    and   a_bottoall: "\<forall> e2. P \<bottom> e2"
    and   a_offending: "f \<in> set_offending_flows G nP"
    and   a_i_snds: "i \<in> snd` f"
    shows
          "\<not> sinvar G (nP(i := \<bottom>))"
  proof -
    from assms show ?thesis
    apply -
    apply(drule ENFnr_to_ENFnrSR)
    apply(drule ENFnrSR_snds_weakrefl_instance)
         by auto
  qed
 



  (* snds version DRAFT*)
  lemma (in SecurityInvariant_withOffendingFlows)  ENF_weakrefl_instance_FALSE:
    fixes "default_node_properties" :: "'a" ("\<bottom>")
    assumes a_validG: "valid_graph G"
    and   a_not_eval: "\<not> sinvar G nP"
    and   a_enf: "sinvar_all_edges_normal_form P"
    and   a_weakrefl: "P \<bottom> \<bottom>"
    and   a_botisolated: "\<And> e2. e2 \<noteq> \<bottom> \<Longrightarrow> \<not> P \<bottom> e2"
    and   a_botdefault: "\<And> e1 e2. e1 \<noteq> \<bottom> \<Longrightarrow> \<not> P e1 e2 \<Longrightarrow> \<not> P e1 \<bottom>"
    and   a_offending: "f \<in> set_offending_flows G nP"
    and   a_offending_rm: "sinvar (delete_edges G f) nP"
    and   a_i_fsts: "i \<in> snd` f"
    and   a_not_eval_upd: "\<not> sinvar G (nP(i := \<bottom>))"
    shows "False"
oops



end
