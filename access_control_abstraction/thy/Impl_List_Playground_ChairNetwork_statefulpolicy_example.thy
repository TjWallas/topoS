theory Impl_List_Playground_ChairNetwork_statefulpolicy_example
imports Impl_List_Interface
begin


text{*An example of our chair network [simplified]*}

abbreviation "V\<equiv>NetworkModel_Vertices.V"

text{*Our access control view on the network*}
  definition ChairNetwork_empty :: "vString list_graph" where
    "ChairNetwork_empty \<equiv> \<lparr> nodesL = [V ''WebSrv'', V ''FilesSrv'', V ''Printer'',
                                V ''Students'',
                                V ''Employees'',
                                V ''Internet''],
                      edgesL = [] \<rparr>"
  
  lemma "valid_list_graph ChairNetwork_empty" by eval


section{*Our security requirements*}
  subsection{*We have a server with confidential data*}
    definition ConfidentialChairData::"(vString NetworkSecurityModel)" where
      "ConfidentialChairData \<equiv> new_configured_list_NetworkSecurityModel NM_BLPtrusted_impl.NM_LIB_BLPtrusted \<lparr> 
          node_properties = [V ''FilesSrv'' \<mapsto> \<lparr> privacy_level = 1, trusted = False \<rparr>,
                             V ''Employees'' \<mapsto> \<lparr> privacy_level = 0, trusted = True \<rparr>], 
          model_global_properties = () 
          \<rparr>"


  subsection{* accessibly by employees and students*}
    definition "PrintingACL \<equiv> new_configured_list_NetworkSecurityModel NM_LIB_CommunicationPartners \<lparr> 
          node_properties = [V ''Printer'' \<mapsto> Master [V ''Employees'', V ''Students''],
                             V ''Employees'' \<mapsto> Care,
                             V ''Students'' \<mapsto> Care], 
          model_global_properties = () 
          \<rparr>"

  subsection{* Printers are information sinks *}
    definition "PrintingSink \<equiv> new_configured_list_NetworkSecurityModel NM_LIB_Sink \<lparr> 
          node_properties = [V ''Printer'' \<mapsto> Sink], 
          model_global_properties = () 
          \<rparr>"



  subsection{*Students and Employees may access each other but are not accessible from the outside*}
    definition "InternalSubnet \<equiv> new_configured_list_NetworkSecurityModel NM_LIB_SubnetsInGW \<lparr> 
          node_properties = [V ''Students'' \<mapsto> Member, V ''Employees'' \<mapsto> Member], 
          model_global_properties = () 
          \<rparr>"


  subsection{* The files server is only accessibly by employees*}
    definition "FilesSrcACL \<equiv> new_configured_list_NetworkSecurityModel NM_LIB_CommunicationPartners \<lparr> 
          node_properties = [V ''FilesSrv'' \<mapsto> Master [V ''Employees''],
                             V ''Employees'' \<mapsto> Care], 
          model_global_properties = () 
          \<rparr>"


definition "ChairSecurityRequirements = [ConfidentialChairData, PrintingACL, PrintingSink, InternalSubnet, FilesSrcACL]"

lemma "\<forall>m \<in> set ChairSecurityRequirements. implc_eval_model m ChairNetwork_empty" by eval

value[code] "implc_get_offending_flows ChairSecurityRequirements ChairNetwork_empty"
value[code] "generate_valid_topology ChairSecurityRequirements ChairNetwork_empty"

value[code] "List.product (nodesL ChairNetwork_empty) (nodesL ChairNetwork_empty)"

definition "ChairNetwork = generate_valid_topology ChairSecurityRequirements 
      \<lparr>nodesL = nodesL ChairNetwork_empty, edgesL = List.product (nodesL ChairNetwork_empty) (nodesL ChairNetwork_empty) \<rparr>"

value[code] "ChairNetwork"


ML{*
vizualize_graph @{context} @{theory} @{term "ChairSecurityRequirements"} @{term "ChairNetwork"};
*}


definition "ChairNetwork_stateful_IFS = \<lparr> hostsL = nodesL ChairNetwork, flows_fixL = edgesL ChairNetwork, flows_stateL = filter_IFS_no_violations ChairNetwork ChairSecurityRequirements \<rparr>"
value[code] "edgesL ChairNetwork"
value[code] "filter_IFS_no_violations ChairNetwork ChairSecurityRequirements"
value[code] "ChairNetwork_stateful_IFS"
lemma "set (flows_stateL ChairNetwork_stateful_IFS) \<subseteq> (set (flows_fixL ChairNetwork_stateful_IFS))" by eval (*must always hold*)
value[code] "(set (flows_fixL ChairNetwork_stateful_IFS)) - set (flows_stateL ChairNetwork_stateful_IFS)"
(*only problems: printers!!!*)
value[code] "stateful_list_policy_to_list_graph ChairNetwork_stateful_IFS"

definition "ChairNetwork_stateful_ACS = \<lparr> hostsL = nodesL ChairNetwork, flows_fixL = edgesL ChairNetwork, flows_stateL = filter_compliant_stateful_ACS ChairNetwork ChairSecurityRequirements \<rparr>"
value[code] "edgesL ChairNetwork"
value[code] "filter_compliant_stateful_ACS ChairNetwork ChairSecurityRequirements"
value[code] "ChairNetwork_stateful_ACS"
lemma "set (flows_stateL ChairNetwork_stateful_ACS) \<subseteq> (set (flows_fixL ChairNetwork_stateful_ACS))" by eval (*must always hold*)
value[code] "(set (flows_fixL ChairNetwork_stateful_ACS)) - set (flows_stateL ChairNetwork_stateful_ACS)"

(*flows that are already allowed in both directions are not marked as stateful*)
value[code] "((set (flows_fixL ChairNetwork_stateful_ACS)) - set (flows_stateL ChairNetwork_stateful_ACS)) - set (backlinks (flows_fixL ChairNetwork_stateful_ACS))"

(*the new backflows*)
value[code] "set (edgesL (stateful_list_policy_to_list_graph ChairNetwork_stateful_ACS)) - (set (edgesL ChairNetwork))"

(*the resulting ACS graph*)
value[code] "stateful_list_policy_to_list_graph ChairNetwork_stateful_ACS"


value[code] "generate_valid_stateful_policy_IFSACS ChairNetwork ChairSecurityRequirements"
value[code] "generate_valid_stateful_policy_IFSACS_2 ChairNetwork ChairSecurityRequirements"
lemma "set (flows_fixL (generate_valid_stateful_policy_IFSACS ChairNetwork ChairSecurityRequirements)) = set (flows_fixL (generate_valid_stateful_policy_IFSACS_2 ChairNetwork ChairSecurityRequirements))" by eval
lemma "set (flows_stateL (generate_valid_stateful_policy_IFSACS ChairNetwork ChairSecurityRequirements)) = set (flows_stateL (generate_valid_stateful_policy_IFSACS_2 ChairNetwork ChairSecurityRequirements))" by eval


definition "ChairNetwork_stateful = generate_valid_stateful_policy_IFSACS ChairNetwork ChairSecurityRequirements"


ML_val{*
visualize_edges @{context} @{theory} @{term "flows_fixL ChairNetwork_stateful"} [("edge [dir=\"arrow\", style=dashed, color=\"#FF8822\", constraint=false]", @{term "flows_stateL ChairNetwork_stateful"})]; 
*}

section{*An example of bad side-effects in access control policies*}

  definition ACL_not_with::"(vString NetworkSecurityModel)" where
    "ACL_not_with \<equiv> new_configured_list_NetworkSecurityModel NM_ACLnotCommunicateWith_impl.NM_LIB_ACLnotCommunicateWith \<lparr> 
        node_properties = [V ''A'' \<mapsto> {V ''C''},
                           V ''B'' \<mapsto> {},
                           V ''C'' \<mapsto> {}], 
        model_global_properties = () 
        \<rparr>"

  definition simple_network :: "vString list_graph" where
    "simple_network \<equiv> \<lparr> nodesL = [V ''A'', V ''B'', V ''C''],
                      edgesL = [(V ''B'', V ''A''), (V ''B'', V ''C'')] \<rparr>"
  
  lemma "valid_list_graph ChairNetwork_empty" by eval
  lemma "\<forall>m \<in> set [ACL_not_with]. implc_eval_model m simple_network" by eval


  lemma "implc_get_offending_flows [ACL_not_with] simple_network = []" by eval
  lemma "implc_get_offending_flows [ACL_not_with] 
    \<lparr> nodesL = [V ''A'', V ''B'', V ''C''], edgesL = [(V ''B'', V ''A''), (V ''B'', V ''C''), (V ''A'', V ''B'')] \<rparr> =
      [[(V ''B'', V ''C'')], [(V ''A'', V ''B'')]]" by eval

value[code] "generate_valid_stateful_policy_IFSACS simple_network [ACL_not_with]"
value[code] "generate_valid_stateful_policy_IFSACS_2 simple_network [ACL_not_with]"








section{*performance test*}
(*6 minutes , about 1.8k edges in graph, most of the times, no requirements apply, simply added some nodes, edges to the chair network. topology is valid*)
(*value[code] "generate_valid_stateful_policy_IFSACS biggraph ChairSecurityRequirements"*)

end
