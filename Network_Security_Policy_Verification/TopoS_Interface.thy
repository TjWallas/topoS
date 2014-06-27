theory TopoS_Interface
imports Main "Lib/FiniteGraph" TopoS_Vertices TopoS_Util
begin



section {* Security Invariants *}
  text{*
    We define security invariants over a graph.
    The graph corresponds to the network's access control structure.
  *}

  -- {*@{typ "'v"} is the type of the nodes in the graph (hosts in the network). 
     @{typ "'a"} is the type of the host attributes.
     @{typ "'b"} is the type of some additional global attributes (not very important) *}
  record ('v::vertex, 'a, 'b) TopoS_Params =
    node_properties :: "'v::vertex \<Rightarrow> 'a option"
    model_global_properties :: "'b"

text{*
A Security Invariant is defined as locale.

We successively define more and more locales with more and more assumptions.
This clearly depicts which assumptions are necessary to use certain features of a Security Invariant.
In addition, it makes instance proofs of Security Invariants easier, since the lemmata obtained by an (easy, few assumptions) instance proof 
can be used for the complicated (more assumptions) instance proofs.

A security Invariant consists of two functions. A function @{text "sinvar"} and a function @{text "verify_globals"}.
@{text "sinvar"} is the most important function. 
Essentially, it is a predicate over the policy (depiced as graph @{text "G"} and a host attribute mapping (@{text "nP"})).

The second function @{text "verify_globals"} is less important. It can for example be used to check so properties if the global attributes.
It is barely used.
*}

text {* A Security Invariant where the offending flows (flows that invalidate the policy) can be defined and calculated.
No assumptions are necessary for this step.
*}  
  locale SecurityInvariant_withOffendingFlows = 
    fixes sinvar::"('v::vertex) graph \<Rightarrow> ('v::vertex \<Rightarrow> 'a) \<Rightarrow> bool" --{* policy @{text "\<Rightarrow>"} host attribute mapping @{text "\<Rightarrow>"} bool*}
    fixes verify_globals::"('v::vertex) graph \<Rightarrow> ('v::vertex \<Rightarrow> 'a) \<Rightarrow> 'b \<Rightarrow> bool" (*Network Graph (V,E) => V to node_properties => model_global_properties => bool*)
   begin
    -- "Offending Flows definitions:"
    definition is_offending_flows::"('v \<times> 'v) set \<Rightarrow> 'v graph \<Rightarrow> ('v \<Rightarrow> 'a) \<Rightarrow> bool" where
      "is_offending_flows f G nP \<equiv> \<not> sinvar G nP \<and> sinvar (delete_edges G f) nP"
    
    -- "Above definition is not minimal: "
    definition is_offending_flows_min_set::"('v \<times> 'v) set \<Rightarrow> 'v graph \<Rightarrow> ('v \<Rightarrow> 'a) \<Rightarrow> bool" where
      "is_offending_flows_min_set f G nP \<equiv> is_offending_flows f G nP \<and> 
        (\<forall> (e1, e2) \<in> f. \<not> sinvar (add_edge e1 e2 (delete_edges G f)) nP)"
    
    -- "The set of all offending flows."
    definition set_offending_flows::"'v graph \<Rightarrow> ('v \<Rightarrow> 'a) \<Rightarrow> ('v \<times> 'v) set set" where
      "set_offending_flows G  nP = {F. F \<subseteq> (edges G) \<and> is_offending_flows_min_set F G nP}"
  

    text {*Some of the @{const set_offending_flows} definition*}
    lemma offending_not_empty: "\<lbrakk> F \<in> set_offending_flows G nP \<rbrakk> \<Longrightarrow> F \<noteq> {}"
     by(auto simp add: set_offending_flows_def is_offending_flows_def is_offending_flows_min_set_def)
    lemma empty_offending_contra:
       "\<lbrakk> F \<in> set_offending_flows G nP; F = {}\<rbrakk> \<Longrightarrow> False"
     by(simp add: set_offending_flows_def is_offending_flows_def is_offending_flows_min_set_def)
    lemma offending_notevalD: "F \<in> set_offending_flows G nP \<Longrightarrow> \<not> sinvar G nP"
     by(simp add: set_offending_flows_def is_offending_flows_def is_offending_flows_min_set_def)
    lemma sinvar_no_offending: "sinvar G nP \<Longrightarrow> set_offending_flows G nP = {}"
      by(simp add: set_offending_flows_def is_offending_flows_def is_offending_flows_min_set_def)
    theorem removing_offending_flows_makes_invariant_hold:
      "\<forall>F \<in> set_offending_flows G nP. sinvar (delete_edges G F) nP"
      proof(cases "sinvar G nP")
       case True
        hence no_offending: "set_offending_flows G nP = {}" using sinvar_no_offending by simp
        thus "\<forall>F\<in>set_offending_flows G nP. sinvar (delete_edges G F) nP" using empty_iff by simp
       next
       case False thus "\<forall>F\<in>set_offending_flows G nP. sinvar (delete_edges G F) nP"
        by(simp add: set_offending_flows_def is_offending_flows_def is_offending_flows_min_set_def graph_ops)
      qed
  corollary valid_without_offending_flows:
  "\<lbrakk> F \<in> set_offending_flows G nP \<rbrakk> \<Longrightarrow> sinvar (delete_edges G F) nP"
    by(simp add: removing_offending_flows_makes_invariant_hold)

  lemma set_offending_flows_simp: 
    "\<lbrakk> valid_graph G \<rbrakk> \<Longrightarrow>
      set_offending_flows G nP = {F. F \<subseteq> edges G \<and>
        (\<not> sinvar G nP \<and> sinvar \<lparr>nodes = nodes G, edges = edges G - F\<rparr> nP) \<and>
        (\<forall>(e1, e2)\<in>F. \<not> sinvar \<lparr>nodes = nodes G, edges = {(e1, e2)} \<union> (edges G - F)\<rparr> nP)}"
    apply(simp only: set_offending_flows_def is_offending_flows_min_set_def 
      is_offending_flows_def delete_edges_simp2 add_edge_def graph.select_convs)
    apply(subgoal_tac "\<And>F e1 e2. F \<subseteq> edges G \<Longrightarrow> (e1, e2) \<in> F \<Longrightarrow> nodes G \<union> {e1, e2} = nodes G")
     apply fastforce
    apply(simp add: valid_graph_def)
    by (metis fst_conv imageI in_mono insert_absorb snd_conv)

   end



print_locale! SecurityInvariant_withOffendingFlows


text{*
The locale @{text SecurityInvariant_withOffendingFlows} has no assumptions about the security invariant @{text sinvar}.
Undesirable things may happen:
The offending flows can be empty, even for a violated invariant.

We provide an example, the security invariant @{term "(\<lambda>_ _. False)"}.
As host attributes, we simpley use the identity function @{const id}.
*}
lemma "SecurityInvariant_withOffendingFlows.set_offending_flows (\<lambda>_ _. False) \<lparr> nodes = {V ''v1''}, edges={} \<rparr> id = {}"
by(simp add: SecurityInvariant_withOffendingFlows.set_offending_flows_def 
  SecurityInvariant_withOffendingFlows.is_offending_flows_min_set_def SecurityInvariant_withOffendingFlows.is_offending_flows_def)
lemma "SecurityInvariant_withOffendingFlows.set_offending_flows (\<lambda>_ _. False) 
  \<lparr> nodes = {V ''v1'', V ''v2''}, edges = {(V ''v1'', V ''v2'')} \<rparr> id = {}"
by(simp add: SecurityInvariant_withOffendingFlows.set_offending_flows_def 
  SecurityInvariant_withOffendingFlows.is_offending_flows_min_set_def SecurityInvariant_withOffendingFlows.is_offending_flows_def)

text {*In general, there exists a @{term sinvar} such that the invariant does not hold and no offending flows exits.*}
  lemma "\<exists>sinvar. \<not> sinvar G nP \<and> SecurityInvariant_withOffendingFlows.set_offending_flows sinvar G nP = {}"
  apply(simp add: SecurityInvariant_withOffendingFlows.set_offending_flows_def
    SecurityInvariant_withOffendingFlows.is_offending_flows_min_set_def SecurityInvariant_withOffendingFlows.is_offending_flows_def)
  apply(rule_tac x="(\<lambda>_ _. False)" in exI)
  apply(simp)
  done


text{*Thus, we introduce a usefulness property that prohibits such useless invariants*}
text{*Usefullness properties*}

  locale TopoS_preliminaries = SecurityInvariant_withOffendingFlows sinvar verify_globals
    for sinvar::"('v::vertex) graph \<Rightarrow> ('v::vertex \<Rightarrow> 'a) \<Rightarrow> bool"
    and verify_globals::"('v::vertex) graph \<Rightarrow> ('v::vertex \<Rightarrow> 'a) \<Rightarrow> 'b \<Rightarrow> bool"
    +
    assumes 
      defined_offending:
      "\<lbrakk> valid_graph G; \<not> sinvar G nP \<rbrakk> \<Longrightarrow> set_offending_flows G nP \<noteq> {}"
    and
      mono_sinvar:
      "\<lbrakk> valid_graph \<lparr> nodes = N, edges = E \<rparr>; E' \<subseteq> E; sinvar \<lparr> nodes = N, edges = E \<rparr> nP \<rbrakk> \<Longrightarrow> 
        sinvar \<lparr> nodes = N, edges = E' \<rparr> nP"
    and mono_offending:
      "\<lbrakk> valid_graph G; is_offending_flows ff G nP \<rbrakk> \<Longrightarrow> is_offending_flows (ff \<union> f') G nP"
  begin

  text {* TODO: add this to latex document *}
  (*
  For instance proofs:
    Have a look at SecurityInvariant_withOffendingFlows_lemmata.thy
    There is a definition of sinvar_mono. It impplies mono_sinvar and mono_offending
    apply(fact SecurityInvariant_withOffendingFlows.sinvar_mono_imp_sinvar_mono[OF sinvar_mono])
    apply(fact SecurityInvariant_withOffendingFlows.sinvar_mono_imp_is_offending_flows_mono[OF sinvar_mono])
  
    In addition, SecurityInvariant_withOffendingFlows.mono_imp_set_offending_flows_not_empty[OF sinvar_mono] gives a nice proof rule for
    defined_offending
  
    Basically, sinvar_mono. implies almost all assumptions here and is equal to mono_sinvar.
  *)
  end


  text {* The base network model: default-node-properties is a secure default value.*}
  text {* Some notes about the notation:
          @{text "fst ` f"} means to apply the function @{text "fst"} to the set @{text "f"} elementwise.
          In the context of network graphs: If @{text "f"} is a set of directed edges 
          @{text "f = {(s,r) \<in> edges G. s=senders, r=receivers}"}, then @{text "fst ` f"}
          is the set of senders and @{text "snd ` f"} the set of receivers.*}

  locale NetworkModel = TopoS_preliminaries sinvar verify_globals
    for sinvar::"('v::vertex) graph \<Rightarrow> ('v::vertex \<Rightarrow> 'a) \<Rightarrow> bool"
    and verify_globals::"('v::vertex) graph \<Rightarrow> ('v::vertex \<Rightarrow> 'a) \<Rightarrow> 'b \<Rightarrow> bool"
    +
    fixes default_node_properties :: "'a" ("\<bottom>") 
    and target_focus :: "bool"
    assumes 
      -- "default value can never turn an invalid model to valid."
      -- {*Idea: Giving an offending host the default configuration value does not change the validity of the model. 
        I.e this reconfiguration does not remove information, thus preserves all security critical information.
        Thought experiment preliminaries: Can a default configuration ever solve an existing security violation? NO!
        Thought experiment 1: admin forgot to configure host, hence it is handled by default configuration value ..
        Thought experiment 2: new node (attacker) is added to the network. What is its default configuration value ..*}
      default_secure:
      "\<lbrakk> valid_graph G; \<not> sinvar G nP; f \<in> set_offending_flows G nP \<rbrakk> \<Longrightarrow>
        (\<not> target_focus \<longrightarrow> i \<in> fst ` f \<longrightarrow> \<not> sinvar G (nP(i := \<bottom>))) \<and>
        (target_focus \<longrightarrow> i \<in> snd ` f \<longrightarrow> \<not> sinvar G (nP(i := \<bottom>)))"
      and
      default_unique:
      "otherbot \<noteq> \<bottom> \<Longrightarrow> 
        \<exists> G nP i f. valid_graph (G::('v::vertex) graph) \<and> \<not> sinvar G nP \<and> f \<in> set_offending_flows G nP \<and> 
         sinvar (delete_edges G f) nP \<and>
         (\<not> target_focus \<longrightarrow> i \<in> fst ` f \<and> sinvar G (nP(i := otherbot))) \<and>
         (target_focus \<longrightarrow> i \<in> snd ` f \<and> sinvar G (nP(i := otherbot))) "
      (*and
      --{*verify_globals does not depend on graph topology, i.e. semantics is in sinvar*}
      verify_globals_sound:
      "verify_globals G nP gP \<Longrightarrow> 
        (\<forall> v. verify_globals (add_node v G) nP gP) \<and> 
        (\<forall> v \<in> nodes G. verify_globals (delete_node v G) nP gP) \<and> 
        (\<forall> v\<^sub>1 v\<^sub>2. verify_globals (add_edge v\<^sub>1 v\<^sub>2 G) nP gP) \<and> 
        (\<forall> (v\<^sub>1, v\<^sub>2) \<in> edges G. verify_globals (delete_edge v\<^sub>1 v\<^sub>2 G) nP gP)"*)
   begin
    -- "Removes option type, replaces with default node property"
    fun node_props :: "('v, 'a, 'b) TopoS_Params \<Rightarrow> ('v \<Rightarrow> 'a)" where
    "node_props P = (\<lambda> i. (case (node_properties P) i of Some property \<Rightarrow> property | None \<Rightarrow> \<bottom>))"

    definition node_props_formaldef :: "('v, 'a, 'b) TopoS_Params \<Rightarrow> ('v \<Rightarrow> 'a)" where
    "node_props_formaldef P \<equiv>
    (\<lambda> i. (if i \<in> dom (node_properties P) then the (node_properties P i) else \<bottom>))"

    lemma node_props_eq_node_props_formaldef: "node_props_formaldef = node_props"
     apply(simp add: fun_eq_iff node_props_formaldef_def)
     apply(rule allI)+
     by (metis (lifting, mono_tags) domD domIff option.simps(4) option.simps(5) the.simps)


    definition eval::"'v graph \<Rightarrow> ('v, 'a, 'b)TopoS_Params \<Rightarrow> bool" where
    "eval G P \<equiv> valid_graph G \<and> verify_globals G (node_props P) (model_global_properties P) \<and> 
          sinvar G (node_props P)"


    -- "Unbound variables are implicitly all-quantified by mathematical rules. Thus, we require default-secure for all possible graphs, configurations, ..."
    lemma "\<forall> G nP f i. (valid_graph G \<and> \<not> sinvar G nP \<and> f \<in> set_offending_flows G nP \<and> sinvar (delete_edges G f) nP) \<longrightarrow>
        (\<not> target_focus \<longrightarrow> i \<in> fst ` f \<longrightarrow> \<not> sinvar G (nP(i := \<bottom>))) \<and>
        (target_focus \<longrightarrow> i \<in> snd ` f \<longrightarrow>\<not> sinvar G (nP(i := \<bottom>)))"
    by(blast dest:default_secure)

    lemma unique_common_math_notation:
    assumes a: "\<forall>G nP i f. valid_graph (G::('v::vertex) graph) \<and> \<not> sinvar G nP \<and> f \<in> set_offending_flows G nP \<and> 
         sinvar (delete_edges G f) nP \<and> 
         (\<not> target_focus \<longrightarrow> i \<in> fst ` f \<longrightarrow> \<not> sinvar G (nP(i := otherbot))) \<and>
         (target_focus \<longrightarrow> i \<in> snd ` f \<longrightarrow> \<not> sinvar G (nP(i := otherbot)))"
    shows "otherbot = \<bottom>"
    proof -
      have or_imp_eq: "\<And>P Q. \<not> target_focus \<and> P \<or> target_focus \<and> Q \<longleftrightarrow> (\<not>target_focus \<longrightarrow> P) \<and> (target_focus \<longrightarrow> Q)" by blast
      from default_unique have "\<not> ( \<exists>G nP i f.
           valid_graph G \<and>
           \<not> sinvar G nP \<and>
           f \<in> set_offending_flows G nP \<and>
           sinvar (delete_edges G f) nP \<and>
           (\<not> target_focus \<longrightarrow> i \<in> fst ` f \<and> sinvar G (nP(i := otherbot))) \<and> (target_focus \<longrightarrow> i \<in> snd ` f \<and> sinvar G (nP(i := otherbot))))
      \<Longrightarrow> otherbot = \<bottom>" by blast
      from this a have "(\<not> ( \<exists>G nP i f.(
           (\<not> target_focus \<longrightarrow> i \<in> fst` f \<and> sinvar G (nP(i := otherbot))) \<and> (target_focus \<longrightarrow> i \<in> snd` f \<and> sinvar G (nP(i := otherbot))))))
      \<longrightarrow> otherbot = \<bottom>"
      by blast
      hence "(\<forall>G nP i f. (
           (\<not> target_focus \<longrightarrow> i \<in> fst` f \<longrightarrow> \<not> sinvar G (nP(i := otherbot))) \<and> (target_focus \<longrightarrow> i \<in> snd` f \<longrightarrow> \<not> sinvar G (nP(i := otherbot)))))
      \<longrightarrow> otherbot = \<bottom>"
      apply(simp only: HOL.not_ex)
      by(simp add:or_imp_eq)
      from this a show ?thesis by blast
      qed
   end

print_locale! NetworkModel



section{*Information flow Security and Access Control*}
text{*@{term target_focus} defines the offending host. Thus, it defines when the violation happens. 

If the violation happes when the sender sends, we have an access control model. I.e. 
the sender does not have the appropriate rights ro initiate the connection.

If the violation happens at the receiver, we have an information flow security model. I.e. 
the reciever lacks the appropiate security clearance to retrieve the (confidential) information. 
The violations happens only when the receiver reads the data.


We refine our definitions
*}

subsection {*Information flow security*}
  locale TopoS_IFS = TopoS_preliminaries sinvar verify_globals
      for sinvar::"('v::vertex) graph \<Rightarrow> ('v::vertex \<Rightarrow> 'a) \<Rightarrow> bool"
      and verify_globals::"('v::vertex) graph \<Rightarrow> ('v::vertex \<Rightarrow> 'a) \<Rightarrow> 'b \<Rightarrow> bool"
      +
      fixes default_node_properties :: "'a" ("\<bottom>") 
      assumes  default_secure_IFS:
        "\<lbrakk> valid_graph G; f \<in> set_offending_flows G nP \<rbrakk> \<Longrightarrow>
          \<forall>i \<in> snd` f. \<not> sinvar G (nP(i := \<bottom>))"
      and
      --{* If some otherbot fulfills @{text default_secure}, it must be @{term "\<bottom>"} 
             Hence, @{term "\<bottom>"} is uniquely defined *}
      default_unique_IFS:
      "(\<forall>G f nP i. valid_graph G \<and> f \<in> set_offending_flows G nP \<and> i \<in> snd` f 
                \<longrightarrow> \<not> sinvar G (nP(i := otherbot))) \<Longrightarrow> otherbot = \<bottom>"
      begin
        lemma default_unique_EX_notation: "otherbot \<noteq> \<bottom> \<Longrightarrow> 
          \<exists> G nP i f. valid_graph G \<and> \<not> sinvar G nP \<and> f \<in> set_offending_flows G nP \<and> 
           sinvar (delete_edges G f) nP \<and>
           (i \<in> snd` f \<and> sinvar G (nP(i := otherbot)))"
          apply(erule contrapos_pp)
          apply(simp)
          using default_unique_IFS SecurityInvariant_withOffendingFlows.valid_without_offending_flows offending_notevalD
          by metis
      end
  
  sublocale TopoS_IFS \<subseteq> NetworkModel where target_focus=True
  apply(unfold_locales)
   apply(simp add: default_secure_IFS)
  apply(simp only: HOL.simp_thms)
  apply(drule default_unique_EX_notation)
  apply(assumption)
  done

  (*other direction*)
  locale TopoS_IFS_otherDirectrion = NetworkModel where target_focus=True
  sublocale TopoS_IFS_otherDirectrion \<subseteq> TopoS_IFS
  apply(unfold_locales)
   apply (metis default_secure offending_notevalD)
  apply(erule contrapos_pp)
  apply(simp)
  apply(drule default_unique)
  apply(simp)
  apply(blast)
  done
  

lemma default_uniqueness_by_counterexample_IFS:
  assumes "(\<forall>G F nP i. valid_graph G \<and> F \<in> SecurityInvariant_withOffendingFlows.set_offending_flows sinvar G nP \<and> i \<in> snd` F 
                \<longrightarrow> \<not> sinvar G (nP(i := otherbot)))"
  and "otherbot \<noteq> default_value \<Longrightarrow>
    \<exists>G nP i F. valid_graph G \<and> \<not> sinvar G nP \<and> F \<in> (SecurityInvariant_withOffendingFlows.set_offending_flows sinvar G nP) \<and>
       sinvar (delete_edges G F) nP \<and>
        i \<in> snd ` F \<and> sinvar G (nP(i := otherbot)) "
   shows "otherbot = default_value"
   using assms by blast


subsection {*Access Control Strategy*}
  locale TopoS_ACS = TopoS_preliminaries sinvar verify_globals
      for sinvar::"('v::vertex) graph \<Rightarrow> ('v::vertex \<Rightarrow> 'a) \<Rightarrow> bool"
      and verify_globals::"('v::vertex) graph \<Rightarrow> ('v::vertex \<Rightarrow> 'a) \<Rightarrow> 'b \<Rightarrow> bool"
      +
      fixes default_node_properties :: "'a" ("\<bottom>") 
      assumes  default_secure_ACS:
        "\<lbrakk> valid_graph G; f \<in> set_offending_flows G nP \<rbrakk> \<Longrightarrow>
          \<forall>i \<in> fst` f. \<not> sinvar G (nP(i := \<bottom>))"
      and
      default_unique_ACS:
      "(\<forall>G f nP i. valid_graph G \<and> f \<in> set_offending_flows G nP \<and> i \<in> fst` f 
                \<longrightarrow> \<not> sinvar G (nP(i := otherbot))) \<Longrightarrow> otherbot = \<bottom>"
      begin
        lemma default_unique_EX_notation: "otherbot \<noteq> \<bottom> \<Longrightarrow> 
          \<exists> G nP i f. valid_graph G \<and> \<not> sinvar G nP \<and> f \<in> set_offending_flows G nP \<and> 
           sinvar (delete_edges G f) nP \<and>
           (i \<in> fst` f \<and> sinvar G (nP(i := otherbot)))"
          apply(erule contrapos_pp)
          apply(simp)
          using default_unique_ACS SecurityInvariant_withOffendingFlows.valid_without_offending_flows offending_notevalD
          by metis
      end
  
  sublocale TopoS_ACS \<subseteq> NetworkModel where target_focus=False
  apply(unfold_locales)
   apply(simp add: default_secure_ACS)
  apply(simp only: HOL.simp_thms)
  apply(drule default_unique_EX_notation)
  apply(assumption)
  done


  (*other direction*)
  locale TopoS_ACS_otherDirectrion = NetworkModel where target_focus=False
  sublocale TopoS_ACS_otherDirectrion \<subseteq> TopoS_ACS
  apply(unfold_locales)
   apply (metis default_secure offending_notevalD)
  apply(erule contrapos_pp)
  apply(simp)
  apply(drule default_unique)
  apply(simp)
  apply(blast)
  done


lemma default_uniqueness_by_counterexample_ACS:
  assumes "(\<forall>G F nP i. valid_graph G \<and> F \<in> SecurityInvariant_withOffendingFlows.set_offending_flows sinvar G nP \<and> i \<in> fst ` F 
                \<longrightarrow> \<not> sinvar G (nP(i := otherbot)))"
  and "otherbot \<noteq> default_value \<Longrightarrow>
    \<exists>G nP i F. valid_graph G \<and> \<not> sinvar G nP \<and> F \<in> (SecurityInvariant_withOffendingFlows.set_offending_flows sinvar G nP) \<and>
       sinvar (delete_edges G F) nP \<and>
        i \<in> fst ` F \<and> sinvar G (nP(i := otherbot))"
  shows "otherbot = default_value"
  using assms by blast


text{* The sublocale relation ship tells that the simplified @{const TopoS_ACS} and @{const TopoS_IFS} 
  assumptions suffice to do tho whole NetworkModel thing. The other direction is just for completeness.  *}

end
