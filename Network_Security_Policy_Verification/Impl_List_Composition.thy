theory Impl_List_Composition
imports NetworkModel_Lists_Impl_Interface NetworkModel_Composition_Theory
begin

(*the packed network model record from the list implementation*)
term "X::('v::vertex, 'a, 'b) NetworkModel_packed"


section{*Generating instantiated (configured) network security models*}

  --"a configured network security model in list implementaion"
  (*very minimal version, no eval, ...*)
  record ('v) NetworkSecurityModel =
    implc_eval_model::"('v) list_graph \<Rightarrow> bool"
    implc_offending_flows::"('v) list_graph \<Rightarrow> ('v \<times> 'v) list list"
    implc_isIFS::"bool"

  text{* Test if this definition is compliant with the formal definition on sets. *}
  definition NetworkSecurityModel_complies_formal_def :: 
    "('v) NetworkSecurityModel \<Rightarrow> 'v NetworkModel_Composition_Theory.NetworkSecurityModel_configured \<Rightarrow> bool" where
    "NetworkSecurityModel_complies_formal_def impl spec \<equiv> 
      (\<forall> G. valid_list_graph G \<longrightarrow> implc_eval_model impl G = c_eval_model spec (list_graph_to_graph G)) \<and>
      (\<forall> G. valid_list_graph G \<longrightarrow> set`set (implc_offending_flows impl G) = c_offending_flows spec (list_graph_to_graph G)) \<and>
      (implc_isIFS impl = c_isIFS spec)"
    

  fun new_configured_list_NetworkSecurityModel :: 
    "('v::vertex, 'a, 'b) NetworkModel_packed \<Rightarrow> ('v::vertex, 'a, 'b) NetworkModel_Params \<Rightarrow> 
        ('v NetworkSecurityModel)" where 
      "new_configured_list_NetworkSecurityModel m C = 
        (let nP = nm_node_props m C in
         \<lparr> 
            implc_eval_model = (\<lambda>G. (nm_eval_model m) G nP),
            implc_offending_flows = (\<lambda>G. (nm_offending_flows m) G nP),
            implc_isIFS = nm_target_focus m
          \<rparr>)"

  text{* the @{term NetworkModel_Composition_Theory.new_configured_NetworkSecurityModel} must give a result if we have the NetworkModel modelLibrary*}
  lemma NetworkModel_modelLibrary_yields_new_configured_NetworkSecurityModel:
    assumes NetModelLib: "NetworkModel_modelLibrary m eval_model_spec verify_gloabls_spec"
    and     nPdef:       "nP = nm_node_props m C"
    and formalSpec:      "Spec = \<lparr> 
                              c_eval_model = (\<lambda>G. eval_model_spec G nP),
                              c_offending_flows = (\<lambda>G. NetworkModel_withOffendingFlows.set_offending_flows eval_model_spec G nP),
                              c_isIFS = nm_target_focus m
                            \<rparr>"
    shows "new_configured_NetworkSecurityModel (eval_model_spec, nm_default m, nm_target_focus m, nP) = Some Spec"
    proof -
      from NetModelLib have NetModel: "NetworkModel eval_model_spec (nm_default m) (nm_target_focus m)"
        by(simp add: NetworkModel_modelLibrary_def NetworkModel_List_Impl_def)

      have Spec: "\<lparr>c_eval_model = \<lambda>G. eval_model_spec G nP,
             c_offending_flows = \<lambda>G. NetworkModel_withOffendingFlows.set_offending_flows eval_model_spec G nP,
             c_isIFS = nm_target_focus m\<rparr> = Spec"
      by(simp add: formalSpec)
      show ?thesis
        unfolding new_configured_NetworkSecurityModel.simps
        by(simp add: NetModel Spec)
    qed
    thm NetworkModel_modelLibrary_yields_new_configured_NetworkSecurityModel[simplified] (*todo fold in Spec*)


  (* The new_* functions comply, i.e. we can instance network security models that are executable. *)
  lemma new_configured_list_NetworkSecurityModel_complies:
    assumes NetModelLib: "NetworkModel_modelLibrary m eval_model_spec verify_gloabls_spec"
    and     nPdef:       "nP = nm_node_props m C"
    and formalSpec:      "Spec = new_configured_NetworkSecurityModel (eval_model_spec, nm_default m, nm_target_focus m, nP)"
    and implSpec:        "Impl = new_configured_list_NetworkSecurityModel m C"
    shows "NetworkSecurityModel_complies_formal_def Impl (the Spec)"
    proof -
      from NetworkModel_modelLibrary_yields_new_configured_NetworkSecurityModel[OF NetModelLib nPdef]
      have SpecUnfolded: "new_configured_NetworkSecurityModel (eval_model_spec, nm_default m, nm_target_focus m, nP) =
        Some \<lparr>c_eval_model = \<lambda>G. eval_model_spec G nP,
             c_offending_flows = \<lambda>G. NetworkModel_withOffendingFlows.set_offending_flows eval_model_spec G nP,
             c_isIFS = nm_target_focus m\<rparr>" by simp
      
      from NetModelLib show ?thesis
        apply(simp add: SpecUnfolded formalSpec implSpec Let_def)
        apply(simp add: NetworkSecurityModel_complies_formal_def_def)
        apply(simp add: NetworkModel_modelLibrary_def NetworkModel_List_Impl_def)
        apply(simp add: nPdef)
        done
    qed


  corollary new_configured_list_NetworkSecurityModel_complies':
    "\<lbrakk> NetworkModel_modelLibrary m eval_model_spec verify_gloabls_spec \<rbrakk> \<Longrightarrow> 
    NetworkSecurityModel_complies_formal_def (new_configured_list_NetworkSecurityModel m C) (the (new_configured_NetworkSecurityModel (eval_model_spec, nm_default m, nm_target_focus m,  nm_node_props m C)))"
    apply(drule new_configured_list_NetworkSecurityModel_complies)
    by(simp_all)

  --"From"
  thm new_configured_NetworkSecurityModel_sound
  --"we get that new_configured_list_NetworkSecurityModel has all the necessary properties (modulo NetworkSecurityModel_complies_formal_def)"

section{*About valid network security requirements*}

   type_synonym 'v security_models_spec_impl="('v NetworkSecurityModel \<times> 'v NetworkModel_Composition_Theory.NetworkSecurityModel_configured) list"
   
   definition get_spec :: "'v security_models_spec_impl \<Rightarrow> ('v NetworkModel_Composition_Theory.NetworkSecurityModel_configured) list" where
    "get_spec M \<equiv> [snd m. m \<leftarrow> M]"
   definition get_impl :: "'v security_models_spec_impl \<Rightarrow> ('v NetworkSecurityModel) list" where
    "get_impl M \<equiv> [fst m. m \<leftarrow> M]"

section{*Calculating offending flows*}
  fun implc_get_offending_flows :: "('v) NetworkSecurityModel list \<Rightarrow> 'v list_graph \<Rightarrow> (('v \<times> 'v) list list)" where
    "implc_get_offending_flows [] G = []"  |
    "implc_get_offending_flows (m#Ms) G = (implc_offending_flows m G)@(implc_get_offending_flows Ms G)"  
  

  lemma implc_get_offending_flows_fold: 
    "implc_get_offending_flows M G = fold (\<lambda>m accu. accu@(implc_offending_flows m G)) M []"
    proof- 
    { fix accu
      have "accu@(implc_get_offending_flows M G) = fold (\<lambda>m accu. accu@(implc_offending_flows m G)) M accu"
      apply(induction M arbitrary: accu)
      apply(simp_all)
      by(metis append_eq_appendI) }
    from this[where accu2="[]"] show ?thesis by simp
  qed

  lemma implc_get_offending_flows_Un: "set`set (implc_get_offending_flows M G) = (\<Union>m\<in>set M. set`set (implc_offending_flows m G))"
    apply(induction M)
    apply(simp_all)
    by (metis image_Un)


  lemma implc_get_offending_flows_map_concat: "(implc_get_offending_flows M G) = concat [implc_offending_flows m G. m \<leftarrow> M]"
    apply(induction M)
    by(simp_all)

  
  theorem implc_get_offending_flows_complies:
    assumes a1: "\<forall> (m_impl, m_spec) \<in> set M. NetworkSecurityModel_complies_formal_def m_impl m_spec"
    and     a2: "valid_list_graph G"
    shows   "set`set (implc_get_offending_flows (get_impl M) G) = (get_offending_flows (get_spec M) (list_graph_to_graph G))"
    proof -
      from a1 have "\<forall> (m_impl, m_spec) \<in> set M. set ` set (implc_offending_flows m_impl G) = c_offending_flows m_spec (list_graph_to_graph G)"
        apply(simp add: NetworkSecurityModel_complies_formal_def_def)
        using a2 by blast
      hence "\<forall> m \<in> set M. set ` set (implc_offending_flows (fst m) G) = c_offending_flows (snd m) (list_graph_to_graph G)" by fastforce
      thus ?thesis
        by(simp add: get_impl_def get_spec_def implc_get_offending_flows_Un get_offending_flows_def)
   qed



section{*Accessors*}
  definition get_IFS :: "'v NetworkSecurityModel list \<Rightarrow> 'v NetworkSecurityModel list" where
    "get_IFS M \<equiv> [m \<leftarrow> M. implc_isIFS m]"
  definition get_ACS :: "'v NetworkSecurityModel list \<Rightarrow> 'v NetworkSecurityModel list" where
    "get_ACS M \<equiv> [m \<leftarrow> M. \<not> implc_isIFS m]"

  lemma get_IFS_get_ACS_complies:
  assumes a: "\<forall> (m_impl, m_spec) \<in> set M. NetworkSecurityModel_complies_formal_def m_impl m_spec"
    shows "\<forall> (m_impl, m_spec) \<in> set (zip (get_IFS (get_impl M)) (NetworkModel_Composition_Theory.get_IFS (get_spec M))).
      NetworkSecurityModel_complies_formal_def m_impl m_spec"
    and "\<forall> (m_impl, m_spec) \<in> set (zip (get_ACS (get_impl M)) (NetworkModel_Composition_Theory.get_ACS (get_spec M))).
      NetworkSecurityModel_complies_formal_def m_impl m_spec"
    proof -
      from a have "\<forall> (m_impl, m_spec) \<in> set M. implc_isIFS m_impl = c_isIFS m_spec"
        apply(simp add: NetworkSecurityModel_complies_formal_def_def) by fastforce
      hence set_zip_IFS: "set (zip (filter implc_isIFS (get_impl M)) (filter c_isIFS (get_spec M))) \<subseteq> set M"
        apply(simp add: get_impl_def get_spec_def)
        apply(induction M)
        apply(simp_all) by (metis (lifting, mono_tags) prod_case_beta subset_insertI2)
      from set_zip_IFS a show "\<forall> (m_impl, m_spec) \<in> set (zip (get_IFS (get_impl M)) (NetworkModel_Composition_Theory.get_IFS (get_spec M))).
          NetworkSecurityModel_complies_formal_def m_impl m_spec"
        apply(simp add: get_IFS_def get_ACS_def
          NetworkModel_Composition_Theory.get_IFS_def NetworkModel_Composition_Theory.get_ACS_def) by blast
      next
      from a have "\<forall> (m_impl, m_spec) \<in> set M. implc_isIFS m_impl = c_isIFS m_spec"
        apply(simp add: NetworkSecurityModel_complies_formal_def_def) by fastforce
      hence set_zip_ACS: "set (zip [m\<leftarrow>get_impl M . \<not> implc_isIFS m] [m\<leftarrow>get_spec M . \<not> c_isIFS m]) \<subseteq> set M"
        apply(simp add: get_impl_def get_spec_def)
        apply(induction M)
        apply(simp_all) by (metis (lifting, mono_tags) prod_case_beta subset_insertI2)
      from this a show "\<forall> (m_impl, m_spec) \<in> set (zip (get_ACS (get_impl M)) (NetworkModel_Composition_Theory.get_ACS (get_spec M))).
        NetworkSecurityModel_complies_formal_def m_impl m_spec"
        apply(simp add: get_IFS_def get_ACS_def
          NetworkModel_Composition_Theory.get_IFS_def NetworkModel_Composition_Theory.get_ACS_def) by fast
     qed



   lemma get_IFS_get_ACS_select_simps:
    assumes a1: "\<forall> (m_impl, m_spec) \<in> set M. NetworkSecurityModel_complies_formal_def m_impl m_spec"
    shows "\<forall> (m_impl, m_spec) \<in> set (zip (get_IFS (get_impl M)) (NetworkModel_Composition_Theory.get_IFS (get_spec M))). NetworkSecurityModel_complies_formal_def m_impl m_spec" (is "\<forall> (m_impl, m_spec) \<in> set ?zippedIFS. NetworkSecurityModel_complies_formal_def m_impl m_spec")
    and   "(get_impl (zip (Impl_List_Composition.get_IFS (get_impl M)) (NetworkModel_Composition_Theory.get_IFS (get_spec M)))) = Impl_List_Composition.get_IFS (get_impl M)"
    and   "(get_spec (zip (Impl_List_Composition.get_IFS (get_impl M)) (NetworkModel_Composition_Theory.get_IFS (get_spec M)))) = NetworkModel_Composition_Theory.get_IFS (get_spec M)"
    and   "\<forall> (m_impl, m_spec) \<in> set (zip (get_ACS (get_impl M)) (NetworkModel_Composition_Theory.get_ACS (get_spec M))). NetworkSecurityModel_complies_formal_def m_impl m_spec" (is "\<forall> (m_impl, m_spec) \<in> set ?zippedACS. NetworkSecurityModel_complies_formal_def m_impl m_spec")
    and   "(get_impl (zip (Impl_List_Composition.get_ACS (get_impl M)) (NetworkModel_Composition_Theory.get_ACS (get_spec M)))) = Impl_List_Composition.get_ACS (get_impl M)"
    and   "(get_spec (zip (Impl_List_Composition.get_ACS (get_impl M)) (NetworkModel_Composition_Theory.get_ACS (get_spec M)))) = NetworkModel_Composition_Theory.get_ACS (get_spec M)"
    proof -
        from get_IFS_get_ACS_complies(1)[OF a1]
        show "\<forall> (m_impl, m_spec) \<in> set (?zippedIFS). NetworkSecurityModel_complies_formal_def m_impl m_spec" by simp
      next
        from a1 show "(get_impl ?zippedIFS) = Impl_List_Composition.get_IFS (get_impl M)"
          apply(simp add: Impl_List_Composition.get_IFS_def get_spec_def get_impl_def NetworkModel_Composition_Theory.get_IFS_def)
          apply(induction M)
          apply(simp)
          apply(simp)
          apply(rule conjI)
          apply(clarify)
          using NetworkSecurityModel_complies_formal_def_def apply (auto)[1]
          apply(clarify)
          using NetworkSecurityModel_complies_formal_def_def apply (auto)[1]
          done
      next
        from a1 show "(get_spec ?zippedIFS) = NetworkModel_Composition_Theory.get_IFS (get_spec M)"
          apply(simp add: Impl_List_Composition.get_IFS_def get_spec_def get_impl_def NetworkModel_Composition_Theory.get_IFS_def)
          apply(induction M)
          apply(simp)
          apply(simp)
          apply(rule conjI)
          apply(clarify)
          using NetworkSecurityModel_complies_formal_def_def apply (auto)[1]
          apply(clarify)
          using NetworkSecurityModel_complies_formal_def_def apply (auto)[1]
          done
      next
        from get_IFS_get_ACS_complies(2)[OF a1]
        show "\<forall> (m_impl, m_spec) \<in> set (?zippedACS). NetworkSecurityModel_complies_formal_def m_impl m_spec" by simp
      next
        from a1 show "(get_impl ?zippedACS) = Impl_List_Composition.get_ACS (get_impl M)"
          apply(simp add: Impl_List_Composition.get_ACS_def get_spec_def get_impl_def NetworkModel_Composition_Theory.get_ACS_def)
          apply(induction M)
          apply(simp)
          apply(simp)
          apply(rule conjI)
          apply(clarify)
          using NetworkSecurityModel_complies_formal_def_def apply (auto)[1]
          apply(clarify)
          using NetworkSecurityModel_complies_formal_def_def apply (auto)[1]
          done
      next
        from a1 show "(get_spec ?zippedACS) = NetworkModel_Composition_Theory.get_ACS (get_spec M)"
          apply(simp add: Impl_List_Composition.get_ACS_def get_spec_def get_impl_def NetworkModel_Composition_Theory.get_ACS_def)
          apply(induction M)
          apply(simp)
          apply(simp)
          apply(rule conjI)
          apply(clarify)
          using NetworkSecurityModel_complies_formal_def_def apply (auto)[1]
          apply(clarify)
          using NetworkSecurityModel_complies_formal_def_def apply (auto)[1]
          done
      qed 
 
   thm get_IFS_get_ACS_select_simps

section{*All security requirements fulfilled*}
   definition all_security_requirements_fulfilled :: "'v NetworkSecurityModel list \<Rightarrow> 'v list_graph \<Rightarrow> bool" where
      "all_security_requirements_fulfilled M G \<equiv> \<forall>m \<in> set M. (implc_eval_model m) G"

  lemma all_security_requirements_fulfilled_complies:
    "\<lbrakk> \<forall> (m_impl, m_spec) \<in> set M. NetworkSecurityModel_complies_formal_def m_impl m_spec; 
       valid_list_graph (G::('v::vertex) list_graph) \<rbrakk> \<Longrightarrow>
    all_security_requirements_fulfilled (get_impl M) G <-> NetworkModel_Composition_Theory.all_security_requirements_fulfilled (get_spec M) (list_graph_to_graph G)"
    apply(simp add: all_security_requirements_fulfilled_def NetworkModel_Composition_Theory.all_security_requirements_fulfilled_def)
    apply(simp add: get_impl_def get_spec_def)
    using NetworkSecurityModel_complies_formal_def_def by fastforce

section{*generate valid topology*}
  value "concat [[1::int,2,3], [4,6,5]]"

  fun generate_valid_topology :: "('v) NetworkSecurityModel list \<Rightarrow> 'v list_graph \<Rightarrow> ('v list_graph)" where
    "generate_valid_topology M G = delete_edges G (concat (implc_get_offending_flows M G))"


  lemma generate_valid_topology_complies:
    "\<lbrakk> \<forall> (m_impl, m_spec) \<in> set M. NetworkSecurityModel_complies_formal_def m_impl m_spec;
       valid_list_graph (G::('v::vertex) list_graph) \<rbrakk> \<Longrightarrow> 
       list_graph_to_graph (generate_valid_topology (get_impl M) G) = 
       NetworkModel_Composition_Theory.generate_valid_topology (get_spec M) (list_graph_to_graph G)"
    apply(subst generate_valid_topology_def_alt)
    apply(drule(1) implc_get_offending_flows_complies)
    apply(simp)
    apply(simp add: delete_edges_correct[symmetric])
    apply(simp add: list_graph_to_graph_def FiniteGraph.delete_edges_simp2)
    apply(simp)
    by blast
    
end
