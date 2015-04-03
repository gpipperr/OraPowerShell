--==============================================================================
--
--
--==============================================================================

SELECT root_cs_name "Compliance Standard",
  parent_cs_name "Parent Compliance Standard",
  rule_name "Rule Name",
  root_target_name "Target Name",
  root_target_type "Target Type",
  compliance_score "Compliance Score",
  last_evaluation_date "Last Evaluation Date"
FROM mgmt$cs_rule_eval_summary
WHERE root_target_name    = '&TARGET.'
ORDER BY last_evaluation_date DESC
/