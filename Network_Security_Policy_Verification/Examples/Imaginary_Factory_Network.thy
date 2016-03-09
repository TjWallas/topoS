section "Example: Imaginary Factory Network"
theory Imaginary_Factory_Network
imports "../TopoS_Impl"
begin

abbreviation "V\<equiv>TopoS_Vertices.V"

text{*
In this theory, we give an an example of an imaginary factory network. 
The example was chosen to show the interplay of several security invariants. 
Many security invariants are specified to demonstrate their configuration effort. 

The specified security invariants deliberately include some minor specification problems. 
These problems will be used to demonstrate the inner workings of the algorithms and to visualize why 
some computed results will deviate from the expected results. 



The described scenario is an imaginary factory network. 
It consists of sensors and actuators in a cyber-physical system. 
The on-site production units of the factory are completely automated and there are no humans in the production area. 
Sensors are monitoring the building.
As production units, we will assume that there are two robots (abbreviated bots) which manufacture the actual goods. 
The robots are controlled by control systems. 

The network consists of the following hosts which are responsible to monitor the building. 

  \<^item> Statistics: A server which collects, processes, and stores all data from the sensors. 
  \<^item> SensorSink: A device which receives the data from the PresenceSensor, Webcam, TempSensor, and FireSensor.
                It sends the data to the Statistics server. 
  \<^item> PresenceSensor: A sensor which detects whether a human is in the building. 
  \<^item> Webcam: A camera which monitors the building indoors. 
  \<^item> TempSensor: A sensor which measures the temperature in the building. 
  \<^item> FireSensor: A sensor which detects fire and smoke. 


The following hosts are responsible for the production line. 

  \<^item> MissionControl1: An automation device which drives and controls the robots. 
  \<^item> MissionControl2: An automation device which drives and controls the robots. 
                     It contains the logic for a secret production step, carried out only by Bot2.
  \<^item> Watchdog: Regularly checks the health and technical readings of the robots. 
  \<^item> Bot1: Production robot unit 1. 
  \<^item> Bot2: Production robot unit 2. Does a secret production step. 
  \<^item> AdminPc: A human administrator can log into this machine to supervise or troubleshoot the production. 

We model one additional special host. 

  \<^item> INET: A symbolic host which represents all hosts which are not part of this network.


The security policy is defined below.
*}

definition policy :: "vString list_graph" where
  "policy \<equiv> \<lparr> nodesL = [V ''Statistics'',
                        V ''SensorSink'',
                        V ''PresenceSensor'',
                        V ''Webcam'',
                        V ''TempSensor'',
                        V ''FireSensor'',
                        V ''MissionControl1'',
                        V ''MissionControl2'',
                        V ''Watchdog'',
                        V ''Bot1'',
                        V ''Bot2'',
                        V ''AdminPc'',
                        V ''INET''],
              edgesL = [(V ''PresenceSensor'', V ''SensorSink''),
                        (V ''Webcam'', V ''SensorSink''),
                        (V ''TempSensor'', V ''SensorSink''),
                        (V ''FireSensor'', V ''SensorSink''),
                        (V ''SensorSink'', V ''Statistics''),
                        (V ''MissionControl1'', V ''Bot1''),
                        (V ''MissionControl1'', V ''Bot2''),
                        (V ''MissionControl2'', V ''Bot2''),
                        (V ''AdminPc'', V ''MissionControl2''),
                        (V ''AdminPc'', V ''MissionControl1''),
                        (V ''Watchdog'', V ''Bot1''),
                        (V ''Watchdog'', V ''Bot2'')
                        ] \<rparr>"

lemma "wf_list_graph policy" by eval


ML_val{*
visualize_graph @{context} @{term "[]::vString SecurityInvariant list"} @{term "policy"};
*}

text{*Several security invariants are specified.*}

text{*Privacy for employees.
  The sensors in the building may record any employee. 
	Due to privacy requirements, the sensor readings, processing, and storage of the data is treated with high security clearances. 
	The presence sensor does not allow do identify an individual employee, hence produces less critical data, hence has a lower clearance.
*}
context begin
  private definition "BLP_privacy_host_attributes \<equiv> [V ''Statistics'' \<mapsto> 3,
                           V ''SensorSink'' \<mapsto> 3,
                           V ''PresenceSensor'' \<mapsto> 2, (*less critical data*)
                           V ''Webcam'' \<mapsto> 3
                           ]"
  private lemma "dom (BLP_privacy_host_attributes) \<subseteq> set (nodesL policy)"
    by(simp add: BLP_privacy_host_attributes_def policy_def)
  definition "BLP_privacy_m \<equiv> new_configured_list_SecurityInvariant SINVAR_LIB_BLPbasic \<lparr> 
        node_properties = BLP_privacy_host_attributes \<rparr>"
end


text{*Secret corporate knowledge and intellectual property:
  The production process is a corporate trade secret. 
	The mission control devices have the trade secretes in their program. 
	The important and secret step is done by MissionControl2.
*}
context begin
  private definition "BLP_tradesecrets_host_attributes \<equiv> [V ''MissionControl1'' \<mapsto> 1,
                           V ''MissionControl2'' \<mapsto> 2,
                           V ''Bot1'' \<mapsto> 1,
                           V ''Bot2'' \<mapsto> 2
                           ]"
  private lemma "dom (BLP_tradesecrets_host_attributes) \<subseteq> set (nodesL policy)"
    by(simp add: BLP_tradesecrets_host_attributes_def policy_def)
  definition "BLP_tradesecrets_m \<equiv> new_configured_list_SecurityInvariant SINVAR_LIB_BLPbasic \<lparr> 
        node_properties = BLP_tradesecrets_host_attributes \<rparr>"
end


text{*Privacy for employees, exporting aggregated data:
  Monitoring the building while both ensuring privacy of the employees is an important goal for the company. 
	While the presence sensor only collects the single-bit information whether a human is present, the 
  webcam allows to identify individual employees. 
	The data collected by the presence sensor is classified as secret while the data produced by the webcam is top secret. 
	The sensor sink only has the secret security clearance, hence it is not allowed to process the 
  data generated by the webcam. 
	However, the sensor sink aggregates all data and only distributes a statistical average which does 
  not allow to identify individual employees. 
	It does not store the data over long periods. 
	Therefore, it is marked as trusted and may thus receive the webcam's data. 
	The statistics server, which archives all the data, is considered top secret.
*}
context begin
  private definition "BLP_employee_export_host_attributes \<equiv>
                          [V ''Statistics'' \<mapsto> \<lparr> privacy_level = 3, trusted = False \<rparr>,
                           V ''SensorSink'' \<mapsto> \<lparr> privacy_level = 2, trusted = True \<rparr>,
                           V ''PresenceSensor'' \<mapsto> \<lparr> privacy_level = 2, trusted = False \<rparr>,
                           V ''Webcam'' \<mapsto> \<lparr> privacy_level = 3, trusted = False \<rparr>
                           ]"
  private lemma "dom (BLP_employee_export_host_attributes) \<subseteq> set (nodesL policy)"
    by(simp add: BLP_employee_export_host_attributes_def policy_def)
  definition "BLP_employee_export_m \<equiv> new_configured_list_SecurityInvariant SINVAR_LIB_BLPtrusted \<lparr> 
        node_properties = BLP_employee_export_host_attributes \<rparr>"
  (*TODO: what if Sensor sink were not trusted or had lower or higher clearance?*)
end



text{*Who can access bot2?
  Bot2 carries out a mission-critical production step. 
	It must be made sure that Bot2 only receives packets from Bot1, the two mission control devices and the watchdog.
*}
context begin
  private definition "ACL_bot2_host_attributues \<equiv>
                          [V ''Bot2'' \<mapsto> Master [V ''Bot1'',
                                                 V ''MissionControl1'',
                                                 V ''MissionControl2'',
                                                 V ''Watchdog''],
                           V ''MissionControl1'' \<mapsto> Care,
                           V ''MissionControl2'' \<mapsto> Care,
                           V ''Watchdog'' \<mapsto> Care
                           ]"
  private lemma "dom (ACL_bot2_host_attributues) \<subseteq> set (nodesL policy)"
    by(simp add: ACL_bot2_host_attributues_def policy_def)
  definition "ACL_bot2_m \<equiv> new_configured_list_SecurityInvariant SINVAR_LIB_CommunicationPartners
                             \<lparr>node_properties = ACL_bot2_host_attributues \<rparr>"
  text{*
  Note that Bot1 is in the access list of Bot2 but it does not have the @{const Care} attribute. 
	This means, Bot1 can never access Bot2. 
	A tool could automatically detect such inconsistencies and emit a warning. 
	However, a tool should only emit a warning because this setting can be desirable. 
	
	In our factory, this setting is currently desirable: 
	Three months ago, Bot1 had an irreparable hardware error and needed to be removed from the production line. 
	When removing Bot1 physically, all its host attributes were also deleted. 
	The access list of Bot2 was not changed. 
	It was planned that Bot1 will be replaced and later will have the same access rights again. 
	A few weeks later, a replacement for Bot1 arrived. 
	The replacement is also called Bot1. 
	The new robot arrived neither configured nor tested for the production. 
	After carefully testing Bot1, Bot1 has been given back the host attributes for the other security invariants. 
	Despite the ACL entry of Bot2, when Bot1 was added to the network, because of its missing @{const Care} attribute, 
	it was not given automatically access to Bot2. 
	This prevented that Bot1 would accidentally impact Bot2 without being fully configured. 
	In our scenario, once Bot1 will be fully configured, tested, and verified, it will be given the @{const Care} attribute back. 
	
	In general, this design choice of the invariant template prevents that a newly added host may 
	inherit access rights due to stale entries in access lists. 
	At the same time, it does not force administrators to clean up their access lists because a host 
	may only be removed temporarily and wants to be given back its access rights later on. 
	Note that managing access lists scales quadratically in the number of hosts. 
	In contrast, the @{const Care} attribute can be considered as a Boolean flag which allows to 
	temporarily enable or disable the access rights of a host locally without touching the carefully 
	constructed access lists of other hosts. 
	It also prevents that new hosts which have the name of hosts removed long ago (but where stale 
	access rights were not cleaned up) accidentally inherit their access rights. 
*}
end


(*TODO: dependability*)


text{*Hierarchy of fab robots:
  The production line is designed according to a strict command hierarchy. 
	On top of the hierarchy are control terminals which allow a human operator to intervene and supervise the production process. 
	On the level below, one distinguishes between supervision devices and control devices. 
	The watchdog is a typical supervision device whereas the mission control devices are control devices. 
	Directly below the control devices are the robots. 
	This is the structure that is necessary for the example. 
	However, the company defined a few more sub-departments for future use. 
	The full domain hierarchy tree is visualized below. 
*}
text{*
  Apart from the watchdog, only the following linear part of the tree is used: 
  @{text "''Robots'' \<sqsubseteq> ''ControlDevices'' \<sqsubseteq> ''ControlTerminal''"}.
	Because the watchdog is in a different domain, it needs a trust level of $1$ to access the robots it is monitoring. *}
context begin
  private definition "DomainHierarchy_host_attributes \<equiv>
                [(V ''MissionControl1'',
                    DN (''ControlTerminal''--''ControlDevices''--Leaf, 0)),
                 (V ''MissionControl2'',
                    DN (''ControlTerminal''--''ControlDevices''--Leaf, 0)),
                 (V ''Watchdog'',
                    DN (''ControlTerminal''--''Supervision''--Leaf, 1)),
                 (V ''Bot1'',
                    DN (''ControlTerminal''--''ControlDevices''--''Robots''--Leaf, 0)),
                 (V ''Bot2'',
                    DN (''ControlTerminal''--''ControlDevices''--''Robots''--Leaf, 0)),
                 (V ''AdminPc'',
                    DN (''ControlTerminal''--Leaf, 0))
                 ]"
  private lemma "dom (map_of DomainHierarchy_host_attributes) \<subseteq> set (nodesL policy)"
    by(simp add: DomainHierarchy_host_attributes_def policy_def)

  lemma "DomainHierarchyNG_sanity_check_config
    (map snd DomainHierarchy_host_attributes)
        (
        Department ''ControlTerminal'' [
          Department ''ControlDevices'' [
            Department ''Robots'' [],
            Department ''OtherStuff'' [],
            Department ''ThirdSubDomain'' []
          ],
          Department ''Supervision'' [
            Department ''S1'' [],
            Department ''S2'' []
          ]
        ])" by eval

  definition "Control_hierarchy_m \<equiv> new_configured_list_SecurityInvariant
                                    SINVAR_LIB_DomainHierarchyNG
                                    \<lparr> node_properties = map_of DomainHierarchy_host_attributes \<rparr>"
end


text{*Sensor Gateway: 
  The sensors should not communicate among each other; all accesses must be mediated by the sensor sink. *}
context begin
  private definition "SecurityGateway_host_attributes \<equiv>
                [V ''SensorSink'' \<mapsto> SecurityGateway,
                 V ''PresenceSensor'' \<mapsto> DomainMember,
                 V ''Webcam'' \<mapsto> DomainMember,
                 V ''TempSensor'' \<mapsto> DomainMember,
                 V ''FireSensor'' \<mapsto> DomainMember
                 ]"
  private lemma "dom SecurityGateway_host_attributes \<subseteq> set (nodesL policy)"
    by(simp add: SecurityGateway_host_attributes_def policy_def)
  definition "SecurityGateway_m \<equiv> new_configured_list_SecurityInvariant
                                  SINVAR_LIB_SecurityGatewayExtended
                                    \<lparr> node_properties = SecurityGateway_host_attributes \<rparr>"
end


text{*Production Robots are an information sink:
  The actual control program of the robots is a corporate trade secret. 
	The control commands must not leave the robots. 
	Therefore, they are declared information sinks. 
	In addition, the control command must not leave the mission control devices. 
	However, the two devices could possibly interact to synchronize and they must send their commands to the robots. 
	Therefore, they are labeled as sink pools. *}
context begin
  private definition "SinkRobots_host_attributes \<equiv>
                [V ''MissionControl1'' \<mapsto> SinkPool,
                 V ''MissionControl2'' \<mapsto> SinkPool,
                 V ''Bot1'' \<mapsto> Sink,
                 V ''Bot2'' \<mapsto> Sink
                 ]"
  private lemma "dom SinkRobots_host_attributes \<subseteq> set (nodesL policy)"
    by(simp add: SinkRobots_host_attributes_def policy_def)
  definition "SinkRobots_m \<equiv> new_configured_list_SecurityInvariant
                                  SINVAR_LIB_Sink
                                    \<lparr> node_properties = SinkRobots_host_attributes \<rparr>"
end

text{*Subnet of the fab:
  The sensors, including their sink and statistics server are located in their own subnet and must 
  not be accessible from elsewhere. 
	Also, the administrator's PC is in its own subnet. 
	The production units (mission control and robots) are already isolated by the DomainHierarchy 
  and are not added to a subnet explicitly. *}
context begin
  private definition "Subnets_host_attributes \<equiv>
                [V ''Statistics'' \<mapsto> Subnet 1,
                 V ''SensorSink'' \<mapsto> Subnet 1,
                 V ''PresenceSensor'' \<mapsto> Subnet 1,
                 V ''Webcam'' \<mapsto> Subnet 1,
                 V ''TempSensor'' \<mapsto> Subnet 1,
                 V ''FireSensor'' \<mapsto> Subnet 1,
                 V ''AdminPc'' \<mapsto> Subnet 4
                 ]"
  private lemma "dom Subnets_host_attributes \<subseteq> set (nodesL policy)"
    by(simp add: Subnets_host_attributes_def policy_def)
  definition "Subnets_m \<equiv> new_configured_list_SecurityInvariant
                                  SINVAR_LIB_Subnets
                                    \<lparr> node_properties = Subnets_host_attributes \<rparr>"
end


text{* Access Gateway for the Statistics server:
  The statistics server is further protected from external accesses. 
	Another, smaller subnet is defined with the only member being the statistics server. 
	The only way it may be accessed is via that sensor sink. *}
context begin
  private definition "SubnetsInGW_host_attributes \<equiv>
                [V ''Statistics'' \<mapsto> Member,
                 V ''SensorSink'' \<mapsto> InboundGateway
                 ]"
  private lemma "dom SubnetsInGW_host_attributes \<subseteq> set (nodesL policy)"
    by(simp add: SubnetsInGW_host_attributes_def policy_def)
  definition "SubnetsInGW_m \<equiv> new_configured_list_SecurityInvariant
                                  SINVAR_LIB_SubnetsInGW
                                    \<lparr> node_properties = SubnetsInGW_host_attributes \<rparr>"
end


text{*NonInterference (for the sake of example):
	The fire sensor is managed by an external company and has a built-in GSM module to call the fire fighters in case of an emergency. 
	This additional, out-of-band connectivity is not modeled. 
	However, the contract defines that the company's administrator must not interfere in any way with the fire sensor. *}
context begin
  private definition "NonInterference_host_attributes \<equiv>
                [V ''Statistics'' \<mapsto> Unrelated,
                 V ''SensorSink'' \<mapsto> Unrelated,
                 V ''PresenceSensor'' \<mapsto> Unrelated,
                 V ''Webcam'' \<mapsto> Unrelated,
                 V ''TempSensor'' \<mapsto> Unrelated,
                 V ''FireSensor'' \<mapsto> Interfering, (*!*)
                 V ''MissionControl1'' \<mapsto> Unrelated,
                 V ''MissionControl2'' \<mapsto> Unrelated,
                 V ''Watchdog'' \<mapsto> Unrelated,
                 V ''Bot1'' \<mapsto> Unrelated,
                 V ''Bot2'' \<mapsto> Unrelated,
                 V ''AdminPc'' \<mapsto> Interfering, (*!*)
                 V ''INET'' \<mapsto> Unrelated
                 ]"
  private lemma "dom NonInterference_host_attributes \<subseteq> set (nodesL policy)"
    by(simp add: NonInterference_host_attributes_def policy_def)
  definition "NonInterference_m \<equiv> new_configured_list_SecurityInvariant SINVAR_LIB_NonInterference
                                    \<lparr> node_properties = NonInterference_host_attributes \<rparr>"
end



definition "invariants \<equiv> [BLP_privacy_m, BLP_tradesecrets_m, BLP_employee_export_m,
                          ACL_bot2_m, Control_hierarchy_m,
                          SecurityGateway_m, SinkRobots_m, Subnets_m, SubnetsInGW_m]"
text{*We have excluded @{const NonInterference_m} because of its infeasible runtime.*}


lemma "length invariants = 9" by eval


text{*All security requirements (including @{const NonInterference_m}) are fulfilled.*}
lemma "all_security_requirements_fulfilled (NonInterference_m#invariants) policy" by eval
ML{*
visualize_graph @{context} @{term "invariants"} @{term "policy"};
*}


definition make_policy :: "('a SecurityInvariant) list \<Rightarrow> 'a list \<Rightarrow> 'a list_graph" where
  "make_policy sinvars Vs \<equiv> generate_valid_topology sinvars \<lparr>nodesL = Vs, edgesL = List.product Vs Vs \<rparr>"


definition make_policy_efficient :: "('a SecurityInvariant) list \<Rightarrow> 'a list \<Rightarrow> 'a list_graph" where
  "make_policy_efficient sinvars Vs \<equiv> generate_valid_topology_some sinvars \<lparr>nodesL = Vs, edgesL = List.product Vs Vs \<rparr>"



text{*
The diff to the maximum policy.
Since we excluded @{const NonInterference_m}, it should be the maximum.
*}
value[code] "make_policy invariants (nodesL policy)" (*15s without NonInterference*)
lemma "make_policy invariants (nodesL policy) = 
   \<lparr>nodesL =
    [V ''Statistics'', V ''SensorSink'', V ''PresenceSensor'', V ''Webcam'', V ''TempSensor'',
     V ''FireSensor'', V ''MissionControl1'', V ''MissionControl2'', V ''Watchdog'', V ''Bot1'',
     V ''Bot2'', V ''AdminPc'', V ''INET''],
    edgesL =
      [(V ''Statistics'', V ''Statistics''), (V ''SensorSink'', V ''Statistics''),
       (V ''SensorSink'', V ''SensorSink''), (V ''SensorSink'', V ''Webcam''),
       (V ''PresenceSensor'', V ''SensorSink''), (V ''PresenceSensor'', V ''PresenceSensor''),
       (V ''Webcam'', V ''SensorSink''), (V ''Webcam'', V ''Webcam''),
       (V ''TempSensor'', V ''SensorSink''), (V ''TempSensor'', V ''TempSensor''),
       (V ''TempSensor'', V ''INET''), (V ''FireSensor'', V ''SensorSink''),
       (V ''FireSensor'', V ''FireSensor''), (V ''FireSensor'', V ''INET''),
       (V ''MissionControl1'', V ''MissionControl1''),
       (V ''MissionControl1'', V ''MissionControl2''), (V ''MissionControl1'', V ''Bot1''),
       (V ''MissionControl1'', V ''Bot2''), (V ''MissionControl2'', V ''MissionControl2''),
       (V ''MissionControl2'', V ''Bot2''), (V ''Watchdog'', V ''MissionControl1''),
       (V ''Watchdog'', V ''MissionControl2''), (V ''Watchdog'', V ''Watchdog''),
       (V ''Watchdog'', V ''Bot1''), (V ''Watchdog'', V ''Bot2''), (V ''Watchdog'', V ''INET''),
       (V ''Bot1'', V ''Bot1''), (V ''Bot2'', V ''Bot2''), (V ''AdminPc'', V ''MissionControl1''),
       (V ''AdminPc'', V ''MissionControl2''), (V ''AdminPc'', V ''Watchdog''),
       (V ''AdminPc'', V ''Bot1''), (V ''AdminPc'', V ''AdminPc''), (V ''AdminPc'', V ''INET''),
       (V ''INET'', V ''INET'')]\<rparr>" by eval

text{*Additional flows which would be allowed but which are not in the policy*}
lemma  "set [e \<leftarrow> edgesL (make_policy invariants (nodesL policy)). e \<notin> set (edgesL policy)] = 
        set [(v,v). v \<leftarrow> (nodesL policy)] \<union>
        set [(V ''SensorSink'', V ''Webcam''),
             (V ''TempSensor'', V ''INET''),
             (V ''FireSensor'', V ''INET''),
             (V ''MissionControl1'', V ''MissionControl2''),
             (V ''Watchdog'', V ''MissionControl1''),
             (V ''Watchdog'', V ''MissionControl2''),
             (V ''Watchdog'', V ''INET''),
             (V ''AdminPc'', V ''Watchdog''),
             (V ''AdminPc'', V ''Bot1''),
             (V ''AdminPc'', V ''INET'')]" by eval
ML_val{*
visualize_edges @{context} @{term "edgesL policy"} 
    [("edge [dir=\"arrow\", style=dashed, color=\"#FF8822\", constraint=false]",
     @{term "[e \<leftarrow> edgesL (make_policy invariants (nodesL policy)).
                e \<notin> set (edgesL policy)]"})] ""; 
*}

text{* without @{const NonInterference_m} *}
lemma "all_security_requirements_fulfilled invariants (make_policy invariants (nodesL policy))" by eval




text{*Side note: what if we exclude subnets?*}
ML_val{*
visualize_edges @{context} @{term "edgesL (make_policy invariants (nodesL policy))"} 
    [("edge [dir=\"arrow\", style=dashed, color=\"#FF8822\", constraint=false]",
     @{term "[e \<leftarrow> edgesL (make_policy [BLP_privacy_m, BLP_tradesecrets_m, BLP_employee_export_m,
                           ACL_bot2_m, Control_hierarchy_m,
                           SecurityGateway_m, SinkRobots_m, (*Subnets_m, *)SubnetsInGW_m]  (nodesL policy)).
                e \<notin> set (edgesL (make_policy invariants (nodesL policy)))]"})] ""; 
*}


text{*The more efficient algorithm does not need to construct the complete set of offending flows*}
value[code] "make_policy_efficient (invariants@[NonInterference_m]) (nodesL policy)"
value[code] "make_policy_efficient (NonInterference_m#invariants) (nodesL policy)"


lemma "make_policy_efficient (invariants@[NonInterference_m]) (nodesL policy) = 
       make_policy_efficient (NonInterference_m#invariants) (nodesL policy)" by eval

text{*But @{const NonInterference_m} insists on removing something, which would not be necessary.*}
lemma "make_policy invariants (nodesL policy) \<noteq> make_policy_efficient (NonInterference_m#invariants) (nodesL policy)" by eval

lemma "set (edgesL (make_policy_efficient (NonInterference_m#invariants) (nodesL policy)))
       \<subseteq>
       set (edgesL (make_policy invariants (nodesL policy)))" by eval

text{*This is what it wants to be gone.*} (*may take some minutes*)
lemma "[e \<leftarrow> edgesL (make_policy invariants (nodesL policy)).
                e \<notin> set (edgesL (make_policy_efficient (NonInterference_m#invariants) (nodesL policy)))] =
       [(V ''AdminPc'', V ''MissionControl1''), (V ''AdminPc'', V ''MissionControl2''),
        (V ''AdminPc'', V ''Watchdog''), (V ''AdminPc'', V ''Bot1''), (V ''AdminPc'', V ''INET'')]"
  by eval

lemma "[e \<leftarrow> edgesL (make_policy invariants (nodesL policy)).
               e \<notin> set (edgesL (make_policy_efficient (NonInterference_m#invariants) (nodesL policy)))] =
       [e \<leftarrow> edgesL (make_policy invariants (nodesL policy)). fst e = V ''AdminPc'' \<and> snd e \<noteq> V ''AdminPc'']"
  by eval
ML_val{*
visualize_edges @{context} @{term "edgesL policy"} 
    [("edge [dir=\"arrow\", style=dashed, color=\"#FF8822\", constraint=false]",
     @{term "[e \<leftarrow> edgesL (make_policy invariants (nodesL policy)).
                e \<notin> set (edgesL (make_policy_efficient (NonInterference_m#invariants) (nodesL policy)))]"})] ""; 
*}





subsection{*stateful implementation*}
definition "stateful_policy = generate_valid_stateful_policy_IFSACS policy invariants"
lemma "stateful_policy =
 \<lparr>hostsL = nodesL policy,
    flows_fixL = edgesL policy,
    flows_stateL =
      [(V ''Webcam'', V ''SensorSink''),
       (V ''SensorSink'', V ''Statistics'')]\<rparr>" by eval

ML_val{*
visualize_edges @{context} @{term "flows_fixL stateful_policy"} 
    [("edge [dir=\"arrow\", style=dashed, color=\"#FF8822\", constraint=false]", @{term "flows_stateL stateful_policy"})] ""; 
*}


text{*Because @{const BLP_tradesecrets_m} and @{const SinkRobots_m} restrict information leakage,
     @{term "''Watchdog''"} cannot establish a stateful connection to the bots.
     The invariants clearly state that the bots must not leak information, and Watchdog
     was never given permission to get any information back.*}


text{*Without those two invariants, also AdminPc can set up stateful connections to the machines
      it is intended to administer.*}

lemma "generate_valid_stateful_policy_IFSACS policy
      [BLP_privacy_m, BLP_employee_export_m,
       ACL_bot2_m, Control_hierarchy_m, 
       SecurityGateway_m,  Subnets_m, SubnetsInGW_m] =
 \<lparr>hostsL = nodesL policy,
    flows_fixL = edgesL policy,
    flows_stateL =
      [(V ''Webcam'', V ''SensorSink''),
       (V ''SensorSink'', V ''Statistics''),
       (V ''MissionControl1'', V ''Bot1''),
       (V ''MissionControl1'', V ''Bot2''),
       (V ''MissionControl2'', V ''Bot2''),
       (V ''AdminPc'', V ''MissionControl2''),
       (V ''AdminPc'', V ''MissionControl1''),
       (V ''Watchdog'', V ''Bot1''),
       (V ''Watchdog'', V ''Bot2'')]\<rparr>" by eval


ML_val{*
visualize_edges @{context} @{term "flows_fixL (generate_valid_stateful_policy_IFSACS policy [BLP_privacy_m,  BLP_employee_export_m,
                          ACL_bot2_m, Control_hierarchy_m, 
                          SecurityGateway_m,  Subnets_m, SubnetsInGW_m])"} 
    [("edge [dir=\"arrow\", style=dashed, color=\"#FF8822\", constraint=false]",
      @{term "flows_stateL (generate_valid_stateful_policy_IFSACS policy [BLP_privacy_m,  BLP_employee_export_m,
                          ACL_bot2_m, Control_hierarchy_m, 
                          SecurityGateway_m,  Subnets_m, SubnetsInGW_m])"})] ""; 
*}


text{*Bot1 and Bot2 have different security clearances.
      If Watchdog wants to get information from both, it needs to be trusted.
      Also, Watchdog needs to be included into the SinkPool to set up a stateful connection to the Bots. 
      The bots must be lifted from Sinks to the SinkPool, otherwise, it would be impossible 
      to get any information flow back from them.

      Same for AdminPC.*}

lemma "all_security_requirements_fulfilled [BLP_privacy_m, BLP_employee_export_m,
               ACL_bot2_m, Control_hierarchy_m, 
               SecurityGateway_m, Subnets_m, SubnetsInGW_m,
               new_configured_list_SecurityInvariant SINVAR_LIB_Sink
                 \<lparr> node_properties = [V ''MissionControl1'' \<mapsto> SinkPool,
                                      V ''MissionControl2'' \<mapsto> SinkPool,
                                      V ''Bot1'' \<mapsto> SinkPool,
                                      V ''Bot2'' \<mapsto> SinkPool,
                                      V ''Watchdog'' \<mapsto> SinkPool,
                                      V ''AdminPc'' \<mapsto> SinkPool
                                      ] \<rparr>,
               new_configured_list_SecurityInvariant SINVAR_LIB_BLPtrusted
                 \<lparr> node_properties = [V ''MissionControl1'' \<mapsto> \<lparr> privacy_level = 1, trusted = False \<rparr>,
                                      V ''MissionControl2'' \<mapsto> \<lparr> privacy_level = 2, trusted = False \<rparr>,
                                      V ''Bot1'' \<mapsto> \<lparr> privacy_level = 1, trusted = False \<rparr>,
                                      V ''Bot2'' \<mapsto> \<lparr> privacy_level = 2, trusted = False \<rparr>,
                                      V ''Watchdog'' \<mapsto> \<lparr> privacy_level = 1, trusted = True \<rparr>,
                                        (*trust because bot2 must send to it. privacy_level 1 to interact with bot 1*)
                                      V ''AdminPc'' \<mapsto> \<lparr> privacy_level = 1, trusted = True \<rparr>
                                      ] \<rparr>
              ]
       policy" by eval

lemma "generate_valid_stateful_policy_IFSACS policy
              [BLP_privacy_m, BLP_employee_export_m,
               ACL_bot2_m, Control_hierarchy_m, 
               SecurityGateway_m, Subnets_m, SubnetsInGW_m,
               new_configured_list_SecurityInvariant SINVAR_LIB_Sink
                 \<lparr> node_properties = [V ''MissionControl1'' \<mapsto> SinkPool,
                                      V ''MissionControl2'' \<mapsto> SinkPool,
                                      V ''Bot1'' \<mapsto> SinkPool,
                                      V ''Bot2'' \<mapsto> SinkPool,
                                      V ''Watchdog'' \<mapsto> SinkPool,
                                      V ''AdminPc'' \<mapsto> SinkPool
                                      ] \<rparr>,
               new_configured_list_SecurityInvariant SINVAR_LIB_BLPtrusted
                 \<lparr> node_properties = [V ''MissionControl1'' \<mapsto> \<lparr> privacy_level = 1, trusted = False \<rparr>,
                                      V ''MissionControl2'' \<mapsto> \<lparr> privacy_level = 2, trusted = False \<rparr>,
                                      V ''Bot1'' \<mapsto> \<lparr> privacy_level = 1, trusted = False \<rparr>,
                                      V ''Bot2'' \<mapsto> \<lparr> privacy_level = 2, trusted = False \<rparr>,
                                      V ''Watchdog'' \<mapsto> \<lparr> privacy_level = 1, trusted = True \<rparr>,
                                        (*trust because bot2 must send to it. privacy_level 1 to interact with bot 1*)
                                      V ''AdminPc'' \<mapsto> \<lparr> privacy_level = 1, trusted = True \<rparr>
                                      ] \<rparr>
              ]
 =
 \<lparr>hostsL = nodesL policy,
    flows_fixL = edgesL policy,
    flows_stateL =
      [(V ''Webcam'', V ''SensorSink''),
       (V ''SensorSink'', V ''Statistics''),
       (V ''MissionControl1'', V ''Bot1''),
       (V ''MissionControl2'', V ''Bot2''),
       (V ''AdminPc'', V ''MissionControl2''),
       (V ''AdminPc'', V ''MissionControl1''),
       (V ''Watchdog'', V ''Bot1''),
       (V ''Watchdog'', V ''Bot2'')]\<rparr>" by eval



text{*firewall -- classical use case*}
ML_val{*

(*header*)
writeln ("echo 1 > /proc/sys/net/ipv4/ip_forward"^"\n"^
         "# flush all rules"^"\n"^
         "iptables -F"^"\n"^
         "#default policy for FORWARD chain:"^"\n"^
         "iptables -P FORWARD DROP");

iterate_edges_ML @{context}  @{term "flows_fixL stateful_policy"}
  (fn (v1,v2) => writeln ("iptables -A FORWARD -i $"^v1^"_iface -s $"^v1^"_ipv4 -o $"^v2^"_iface -d $"^v2^"_ipv4 -j ACCEPT"^" # "^v1^" -> "^v2) )
  (fn _ => () )
  (fn _ => () );

iterate_edges_ML @{context} @{term "flows_stateL stateful_policy"}
  (fn (v1,v2) => writeln ("iptables -I FORWARD -m state --state ESTABLISHED -i $"^v2^"_iface -s $"^v2^"_ipv4 -o $"^v1^"_iface -d $"^v1^"_ipv4 # "^v2^" -> "^v1^" (answer)") )
  (fn _ => () )
  (fn _ => () )
*}

end


