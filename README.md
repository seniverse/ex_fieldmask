# FieldMask

[![Build Status](https://travis-ci.org/seniverse/ex_fieldmask.svg?branch=master)](https://travis-ci.org/seniverse/ex_fieldmask)
[![Coverage Status](https://coveralls.io/repos/github/seniverse/ex_fieldmask/badge.svg?branch=master)](https://coveralls.io/github/seniverse/ex_fieldmask?branch=master)
[![hex.pm version](https://img.shields.io/hexpm/v/ex_fieldmask.svg)](https://hex.pm/packages/ex_fieldmask)
[![hex.pm downloads](https://img.shields.io/hexpm/dt/ex_fieldmask.svg)](https://hex.pm/packages/ex_fieldmask)

FieldMask implements [Partial Responses protocol of Google+ API](https://developers.google.com/+/web/api/rest/#partial-responses) purely in Elixir via algorithmic method rather than grammar way which is adopted by [fieldmask](https://github.com/seniverse/fieldmask).

It's the counterpart of [JSON Mask](https://github.com/nemtsov/json-mask) in JavaScript and [jsonmask](https://github.com/zapier/jsonmask) in Python.

## Installation

The package can be installed by adding `ex_fieldmask` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_fieldmask, "~> 0.1.0"} # replace version with newest one
  ]
end
```

## Examples

```shell
iex> FieldMask.mask("a,b", %{"a" => 1, "b" => 2, "c" => 3})
{:ok, %{"a" => 1, "b" => 2}}

iex> FieldMask.mask("a/b", %{"a" => %{"b" => 2, "c" => 3}})
{:ok, %{"a" => %{"b" => 2}}}

iex> FieldMask.mask("a(b,c)", %{"a" => %{"b" => 1, "c" => 2, "d" => 3}, "e" => 4})
{:ok, %{"a" => %{"b" => 1, "c" => 2}}}

iex> FieldMask.mask("a/*/c", %{"a" => %{"b" => %{"c" => 2, "e" => 1}, "d" => %{ "c" => 4, "f" => 3}}})
{:ok, %{"a" => %{"b" => %{"c" => 2}, "d" => %{"c" => 4}}}}

iex> FieldMask.mask("a/b)", %{"a" => 1, "b" => 2, "c" => 3})
{:error, "Invalid text with mismatched brackets: a/b)"}
```

Check test folder to see more examples.

It returns `{:ok, masked_json}` or `{:error, error_message}`. `masked_json` is either a Map or a List in Elixir and `error_message` is a String. Besides, if `text` in invalid or data isn't a decoded JSON, exception would be raised. You are expected to `rescue` the exception or just let it crash catering to the actual condition.

Use [`Poison`](https://github.com/devinus/poison) or other JSON related packages to encode/decode a JSON to/from inner data structure of Elixir.

## One more thing

Take a look at [json-mask#syntax](https://github.com/nemtsov/json-mask#syntax) for the syntax and grammar of Partial Responses protocol of Google+ API.

Unlike package [fieldmask](https://github.com/seniverse/fieldmask) also in the [Seniverse](https://github.com/seniverse) orgnization, this one adopt algorithmic way to parse descriptive `text` and mask your data object. By this way, it's not that strict while parsing text. For example, `"a(b)c"` is equivalent to `"a(b),c"` although you miss the comma `,`. They can both pass the validation and compiled as `%{"a" => %{"b" => %{}}, "c" => %{}}` to do the masking job. This is intentional but you should always use the strict valid syntax.

## Benchmark

See [fieldmask_benchmark](https://github.com/seniverse/fieldmask_benchmark).

## ChangeLog

[CHANGELOG](https://github.com/seniverse/ex_fieldmask/blob/master/CHANGELOG.md)

## License

[Apache 2.0](https://github.com/seniverse/ex_fieldmask/blob/master/LICENSE)
