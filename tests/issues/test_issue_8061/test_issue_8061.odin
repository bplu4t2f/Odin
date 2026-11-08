package test_issue_8061

import "core:testing"
import "core:encoding/json"
import "core:log"
import "core:fmt"
import "core:strconv"

@(test)
test_json_edge_cases :: proc(t: ^testing.T) {
	// RFC 8259 does not specify parser error codes, and Section 9 permits
	// parsers to accept non-JSON extensions; rejection behavior is implementation-specific.
	// RFC 8259 Section 7 requires U+0000 through U+001F to be escaped in strings.
	expect(t, "[\"a\x01b\"]",    .Invalid_String)
	// RFC 8259 Section 7 allows only its listed escape characters and \uXXXX after a backslash.
	expect(t, `["\q"]`,          .Invalid_String)
	// RFC 8259 Section 6 requires one or more digits after an exponent marker.
	expect(t, `[1e]`,            .Illegal_Character)
	// RFC 8259 Section 8.1 requires JSON text exchanged between systems to use UTF-8; 0xFF is not valid UTF-8.
	expect(t, "[\"\xff\"]",      .Invalid_String)
	// RFC 8259's array grammar does not permit a trailing comma without another value.
	expect(t, `[1,]`,            .Illegal_Character)
	// RFC 8259's object grammar does not permit a trailing comma without another member.
	expect(t, `{"a":1,}`,        .Illegal_Character)
	// RFC 8259 Section 6 prohibits leading zeros in the integer part of a number.
	expect(t, `[01]`,            .Invalid_Number)
	// RFC 8259 Section 6 requires one or more digits after a decimal point.
	expect(t, `[1.]`,            .Invalid_Number)
	// RFC 8259 Section 2 permits only space, tab, line feed, and carriage return as whitespace.
	expect(t, "\v[1]",           .Illegal_Character)
	// RFC 8259 defines a JSON text as one value surrounded only by permitted whitespace; NUL and trailing text are not allowed.
	expect(t, "[1]\x00garbage",  .Invalid_String)
}

@(test)
test_json_edge_case_lone_surrogate :: proc(t: ^testing.T) {
	// !! TO BE DETERMINED !!
	// RFC 8259 Section 8.2 says lone surrogates have unpredictable behavior; its grammar permits this escape.
	// In other words, this is not strictly an error.
	//expect(t, `["\ud800"]`,      .Invalid_String)
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
