theory NetworkModel_Vertices
imports Main FiniteGraph
"~~/src/HOL/Library/Char_ord" (*order on char*)
"~~/src/HOL/Library/List_lexord" (*order on strings*)
begin


text {*We need at least some vertices available for a graph ...*}
class vertex =
  fixes vertex_1 :: "'a"
  fixes vertex_2 :: "'a"
  fixes vertex_3 :: "'a"
  assumes distince_vertices: "distinct [vertex_1, vertex_2, vertex_3]"
begin
  lemma distince_vertices12[simp]: "vertex_1 \<noteq> vertex_2" apply(insert distince_vertices) by(simp)
  lemma distince_vertices13[simp]: "vertex_1 \<noteq> vertex_3" apply(insert distince_vertices) by(simp)
  lemma distince_vertices23[simp]: "vertex_2 \<noteq> vertex_3" apply(insert distince_vertices) by(simp)
  
  lemmas distince_vertices_sym = distince_vertices12[symmetric] distince_vertices13[symmetric]
          distince_vertices23[symmetric]
  declare distince_vertices_sym[simp]
end


text {* Numbers, chars and strings are good candidates for vertices. *}

instantiation nat::vertex
begin
  definition "vertex_1_nat" ::nat where "vertex_1 \<equiv> (1::nat)"
  definition "vertex_2_nat" ::nat where "vertex_2 \<equiv> (2::nat)"
  definition "vertex_3_nat" ::nat where "vertex_3 \<equiv> (3::nat)"
instance apply(intro_classes) by(simp add: vertex_1_nat_def vertex_2_nat_def vertex_3_nat_def)
end
value "vertex_1::nat"

instantiation char::vertex
begin
  definition "vertex_1_char" ::char where "vertex_1 \<equiv> CHR ''A''"
  definition "vertex_2_char" ::char where "vertex_2 \<equiv> CHR ''B''"
  definition "vertex_3_char" ::char where "vertex_3 \<equiv> CHR ''C''"
instance apply(intro_classes) by(simp add: vertex_1_char_def  vertex_2_char_def vertex_3_char_def)
end
value "vertex_1::char"

datatype vString = V string
value "V ''AA''"
instantiation vString::vertex
begin
  definition "vertex_1_vString" ::vString where "vertex_1 \<equiv> V ''A''"
  definition "vertex_2_vString" ::vString where "vertex_2 \<equiv> V ''B''"
  definition "vertex_3_vString" ::vString where "vertex_3 \<equiv> V ''C''"
instance apply(intro_classes) by(simp add: vertex_1_vString_def vertex_2_vString_def vertex_3_vString_def)
end

definition string_of_vString :: "vString \<Rightarrow> string" where
  "string_of_vString v = (case v of V s \<Rightarrow> s)"


instantiation vString::linorder
begin
  definition "less_eq_vString" where "less_eq a b \<equiv> ((string_of_vString a) \<le> (string_of_vString b))"
  definition "less_vString" where "less a b \<equiv> (string_of_vString a) < (string_of_vString b)"
instance
 apply(intro_classes)
 apply(simp_all add: less_eq_vString_def less_vString_def string_of_vString_def)
 apply(case_tac x, simp_all, case_tac y, simp_all)
 apply force
 apply(case_tac x, simp_all, case_tac y, simp_all)
 apply(case_tac x, simp_all, case_tac y, simp_all)
 apply(force)
done
end



(*for the ML graphviz vizualizer*)
ML {*
fun tune_Vstring_format (t: term) (s: string) : string = 
    (*TODO fails for different pretty printer settings
     Syntax.string_of_typ @{context} @{typ vString}  *)
    if fastype_of t = @{typ vString} then String.substring (s, (size "NetworkModel_Vertices.vString.V.  "), (size s - (size "NetworkModel_Vertices.vString.V.    "))) else s
*}


hide_const(open) V

  
end
