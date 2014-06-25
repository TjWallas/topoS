theory example_forte14
imports Impl_List_Interface
begin


abbreviation "V\<equiv>NetworkModel_Vertices.V"


definition policy :: "vString list_graph" where
    "policy \<equiv> \<lparr> nodesL = [V ''CC'', V ''C1'', V ''C2'', V ''IFEsrv'', V ''IFE1'', V ''IFE2'', V ''SAT'', V ''Wifi'', V ''P1'', V ''P2'' ],
                edgesL = [(V ''CC'', V ''C1''), (V ''CC'', V ''C2''), (V ''CC'', V ''IFEsrv''), (V ''C1'', V ''CC''), 
                          (V ''C1'', V ''C2''), (V ''C2'', V ''CC''), (V ''C2'', V ''C1''), 
                          (V ''IFEsrv'', V ''IFE1''), (V ''IFEsrv'', V ''IFE2''), (V ''IFEsrv'', V ''SAT''), (V ''IFEsrv'', V ''Wifi''),
                          (V ''IFE1'', V ''IFEsrv''), (V ''IFE2'', V ''IFEsrv''), 
                          (V ''Wifi'', V ''IFEsrv''), (V ''Wifi'', V ''SAT''), (V ''Wifi'', V ''P1''),
                          (V ''Wifi'', V ''P2''), (V ''P1'', V ''Wifi''), (V ''P1'', V ''P2''), (V ''P2'', V ''Wifi''), (V ''P2'', V ''P1'')
                          ] \<rparr>"

lemma "valid_list_graph policy" by eval

(*21 rules*)
lemma "length (edgesL policy) = 21" by eval


definition DomainHierarchy_m::"(vString NetworkSecurityModel)" where
      "DomainHierarchy_m \<equiv> new_configured_list_NetworkSecurityModel NM_DomainHierarchyNG_impl.NM_LIB_DomainHierarchyNG \<lparr> 
          node_properties = [
            V ''CC'' \<mapsto> DN (''aircraft''--''crew''--Leaf, 1),
            V ''C1'' \<mapsto> DN (''aircraft''--''crew''--Leaf, 0),
            V ''C2'' \<mapsto> DN (''aircraft''--''crew''--Leaf, 0),
            V ''IFEsrv'' \<mapsto> DN (''aircraft''--''entertain''--Leaf, 0),
            V ''IFE1'' \<mapsto> DN (''aircraft''--''entertain''--Leaf, 0),
            V ''IFE2'' \<mapsto> DN (''aircraft''--''entertain''--Leaf, 0),
            V ''SAT'' \<mapsto> DN (''aircraft''--''entertain''--''INET''--Leaf, 0),
            V ''Wifi'' \<mapsto> DN (''aircraft''--''entertain''--''POD''--Leaf, 1),
            V ''P1'' \<mapsto> DN (''aircraft''--''entertain''--''POD''--Leaf, 0),
            V ''P2'' \<mapsto> DN (''aircraft''--''entertain''--''POD''--Leaf, 0)
                            ], 
                          (*At the moment, there is no check whether the assigned node_properties comply with the tree in model_global_properties*)
          model_global_properties = (
            Department ''aircraft'' [
              Department ''entertain'' [
                Department ''POD'' [], Department ''INET'' []
              ],
              Department ''crew'' []
            ]) 
          \<rparr>"


definition SecurityGateway_m::"(vString NetworkSecurityModel)" where
  "SecurityGateway_m \<equiv> new_configured_list_NetworkSecurityModel NM_LIB_SecurityGatewayExtended \<lparr> 
          node_properties = [V ''IFEsrv'' \<mapsto> NM_SecGwExt.SecurityGatewayIN,
                             V ''IFE1'' \<mapsto> NM_SecGwExt.DomainMember,
                             V ''IFE2'' \<mapsto> NM_SecGwExt.DomainMember], 
          model_global_properties = () 
          \<rparr>"


(*
0 - unclassified
1 - confidential
2 - secret
3 - topsecret
*)
definition BLP_m::"(vString NetworkSecurityModel)" where
    "BLP_m \<equiv> new_configured_list_NetworkSecurityModel NM_LIB_BLPtrusted \<lparr> 
          node_properties = [V ''CC'' \<mapsto> \<lparr> privacy_level = 2, trusted = False \<rparr>,
                             V ''C1'' \<mapsto> \<lparr> privacy_level = 2, trusted = False \<rparr>,
                             V ''C2'' \<mapsto> \<lparr> privacy_level = 2, trusted = False \<rparr>,
                             V ''IFE1'' \<mapsto> \<lparr> privacy_level = 1, trusted = False \<rparr>,
                             V ''IFE2'' \<mapsto> \<lparr> privacy_level = 1, trusted = False \<rparr>,
                             V ''IFEsrv'' \<mapsto> \<lparr> privacy_level = 0, trusted = True \<rparr>], 
          model_global_properties = () 
          \<rparr>"

definition "security_invariants = [ DomainHierarchy_m, SecurityGateway_m, BLP_m]"

lemma "all_security_requirements_fulfilled security_invariants policy" by eval

lemma "implc_get_offending_flows security_invariants policy = []" by eval


text{*
Visualization with a violation
*}
ML{*
vizualize_graph @{context} @{theory} @{term "security_invariants"} @{term "policy\<lparr>edgesL := (V ''P1'', V ''CC'')#edgesL policy\<rparr>"};
*}






definition "max_policy = generate_valid_topology security_invariants \<lparr>nodesL = nodesL policy, edgesL = List.product (nodesL policy) (nodesL policy) \<rparr>"


text{*calculating the maximum policy*}
value[code] "max_policy"


text{*
The diff to the maximum policy
*}
ML_val{*
visualize_edges @{context} @{theory} @{term "edgesL policy"} 
    [("edge [dir=\"arrow\", style=dashed, color=\"#FF8822\", constraint=false]", @{term "[e \<leftarrow> edgesL max_policy. e \<notin> set (edgesL policy)]"})]; 
*}


text{*
Visualizing the maximum policy
*}
ML{*
vizualize_graph @{context} @{theory} @{term "security_invariants"} @{term "policy"};
*}

lemma "all_security_requirements_fulfilled security_invariants policy" by eval
lemma "all_security_requirements_fulfilled security_invariants max_policy" by eval


section{*A stateful implementation*}
definition "stateful_policy = generate_valid_stateful_policy_IFSACS policy security_invariants"
value[code] "stateful_policy"

ML_val{*
visualize_edges @{context} @{theory} @{term "flows_fixL stateful_policy"} 
    [("edge [dir=\"arrow\", style=dashed, color=\"#FF8822\", constraint=false]", @{term "flows_stateL stateful_policy"})]; 
*}


end