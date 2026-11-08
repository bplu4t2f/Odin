package test_issue_8061

import "core:testing"
import "core:encoding/json"
import "core:log"
import "core:fmt"
import "core:strconv"

@(test)
test_json_edge_cases :: proc(t: ^testing.T) {
	cases := []string {
		"[\"a\x01b\"]",
		`["\q"]`,
		`[1e]`,
		"[\"\xff\"]",
		`["\ud800"]`,
		`[1,]`,
		`{"a":1,}`,
		`[01]`,
		`[1.]`,
		"\v[1]",
		"[1]\x00garbage",
	}
	for c in cases {
		v, err := json.parse(c, .JSON, false)
		defer json.destroy_value(v)
		fmt.printf("%q err=%v value=%v\n", c, err, v)
	}

	expect(t, "[\"a\x01b\"]", .Invalid_String)
	expect(t, `["\q"]`, .Invalid_String)
	expect(t, `[1e]`, .Illegal_Character)
	expect(t, "[\"\xff\"]", .Invalid_String)
	expect(t, `["\ud800"]`, .Invalid_String)
	expect(t, `[1,]`, .Illegal_Character)
	expect(t, `{"a":1,}`, .Illegal_Character)
	expect(t, `[01]`, .Invalid_Number)
	expect(t, `[1.]`, .Invalid_Number)
	expect(t, "\v[1]", .Illegal_Character)
	expect(t, "[1]\x00garbage", .Invalid_String)
}

expect :: proc(t: ^testing.T, input: string, expected_error: json.Error, loc := #caller_location) {
	v, err := json.parse(input, .JSON, parse_integers = false)
	defer json.destroy_value(v)

	// https://github.com/bplu4t2f/Odin/issues/20 :(
	buf := make([dynamic]byte, context.temp_allocator)
	input_for_logging := strconv.quote_string(&buf, input)
	testing.expectf(t, err == expected_error, "Expected error: {1}, got: {2}. Test case:\n\t{0}", input_for_logging, expected_error, err, loc = loc)
	if err == expected_error {
		log.infof("Test case successful: Expected {1}, got {1}\n\t{0}", input_for_logging, expected_error, err)
	}
}
