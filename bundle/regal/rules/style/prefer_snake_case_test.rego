package regal.rules.style["prefer-snake-case_test"]

import future.keywords.if

import data.regal.ast
import data.regal.config
import data.regal.rules.style["prefer-snake-case"] as rule

snake_case_violation := {
	"category": "style",
	"description": "Prefer snake_case for names",
	"related_resources": [{
		"description": "documentation",
		"ref": config.docs.resolve_url("$baseUrl/$category/prefer-snake-case", "style"),
	}],
	"title": "prefer-snake-case",
	"level": "error",
}

test_fail_camel_cased_rule_name if {
	r := rule.report with input as ast.policy(`camelCase := 5`)
	r == {object.union(
		snake_case_violation,
		{"location": {"col": 1, "file": "policy.rego", "row": 3, "text": `camelCase := 5`}},
	)}
}

test_success_snake_cased_rule_name if {
	r := rule.report with input as ast.policy(`snake_case := 5`)
	r == set()
}

test_fail_camel_cased_some_declaration if {
	r := rule.report with input as ast.policy(`p {some fooBar; input[fooBar]}`)
	r == {object.union(
		snake_case_violation,
		{"location": {"col": 9, "file": "policy.rego", "row": 3, "text": `p {some fooBar; input[fooBar]}`}},
	)}
}

test_success_snake_cased_some_declaration if {
	r := rule.report with input as ast.policy(`p {some foo_bar; input[foo_bar]}`)
	r == set()
}

test_fail_camel_cased_multiple_some_declaration if {
	r := rule.report with input as ast.with_future_keywords(`p {
		some x, foo_bar, fooBar; x = 1; foo_bar = 2; input[fooBar]
	}`)
	r == {object.union(
		snake_case_violation,
		{"location": {
			"col": 20, "file": "policy.rego", "row": 9,
			"text": "\t\tsome x, foo_bar, fooBar; x = 1; foo_bar = 2; input[fooBar]",
		}},
	)}
}

test_success_snake_cased_multiple_some_declaration if {
	r := rule.report with input as ast.policy(`p {some x, foo_bar; x = 5; input[foo_bar]}`)
	r == set()
}

test_fail_camel_cased_var_assignment if {
	r := rule.report with input as ast.policy(`allow { camelCase := 5 }`)
	r == {object.union(
		snake_case_violation,
		{"location": {"col": 9, "file": "policy.rego", "row": 3, "text": `allow { camelCase := 5 }`}},
	)}
}

test_fail_camel_cased_multiple_var_assignment if {
	r := rule.report with input as ast.policy(`allow { snake_case := "foo"; camelCase := 5 }`)
	r == {object.union(
		snake_case_violation,
		{"location": {
			"col": 30, "file": "policy.rego", "row": 3,
			"text": `allow { snake_case := "foo"; camelCase := 5 }`,
		}},
	)}
}

test_success_snake_cased_var_assignment if {
	r := rule.report with input as ast.policy(`allow { snake_case := 5 }`)
	r == set()
}

test_fail_camel_cased_some_in_value if {
	r := rule.report with input as ast.with_future_keywords(`allow { some cC in input }`)
	r == {object.union(
		snake_case_violation,
		{"location": {"col": 14, "file": "policy.rego", "row": 8, "text": `allow { some cC in input }`}},
	)}
}

test_fail_camel_cased_some_in_key_value if {
	r := rule.report with input as ast.with_future_keywords(`allow { some cC, sc in input }`)
	r == {object.union(
		snake_case_violation,
		{"location": {"col": 14, "file": "policy.rego", "row": 8, "text": `allow { some cC, sc in input }`}},
	)}
}

test_fail_camel_cased_some_in_key_value_2 if {
	r := rule.report with input as ast.with_future_keywords(`allow { some sc, cC in input }`)
	r == {object.union(
		snake_case_violation,
		{"location": {"col": 18, "file": "policy.rego", "row": 8, "text": `allow { some sc, cC in input }`}},
	)}
}

test_success_snake_cased_some_in if {
	r := rule.report with input as ast.with_future_keywords(`allow { some sc in input }`)
	r == set()
}

test_fail_camel_cased_every_value if {
	r := rule.report with input as ast.with_future_keywords(`allow { every cC in input { cC == 1 } }`)
	r == {object.union(
		snake_case_violation,
		{"location": {"col": 15, "file": "policy.rego", "row": 8, "text": `allow { every cC in input { cC == 1 } }`}},
	)}
}

test_fail_camel_cased_every_key if {
	r := rule.report with input as ast.with_future_keywords(`allow { every cC, sc in input { cC == 1; sc == 2 } }`)
	r == {object.union(
		snake_case_violation,
		{"location": {
			"col": 15, "file": "policy.rego", "row": 8,
			"text": `allow { every cC, sc in input { cC == 1; sc == 2 } }`,
		}},
	)}
}

test_success_snake_cased_every if {
	r := rule.report with input as ast.with_future_keywords(`allow { every sc in input { sc == 1 } }`)
	r == set()
}
