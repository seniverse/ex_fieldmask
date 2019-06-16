defmodule FieldMaskTest do
  @moduledoc false
  use ExUnit.Case
  doctest FieldMask

  test "official example of Google+" do
    text = "url,object(content,attachments/url)"

    object = %{
      "id" => "z12gtjhq3qn2xxl2o224exwiqruvtda0i",
      "url" => "https://plus.google.com/102817283354809142195/posts/F97fqZwJESL",
      "object" => %{
        "objectType" => "note",
        "content" => "A picture... of a space ship... launched from earth 40 years ago.",
        "attachments" => [
          %{
            "objectType" => "image",
            "url" => "http://apod.nasa.gov/apod/ap110908.html",
            "image" => %{"height" => 284, "width" => 506}
          }
        ]
      },
      "provider" => %{"title" => "Google+"}
    }

    assert FieldMask.mask(text, object) ===
             {:ok,
              %{
                "url" => "https://plus.google.com/102817283354809142195/posts/F97fqZwJESL",
                "object" => %{
                  "content" =>
                    "A picture... of a space ship... launched from earth 40 years ago.",
                  "attachments" => [%{"url" => "http://apod.nasa.gov/apod/ap110908.html"}]
                }
              }}
  end

  test "array at the beginning" do
    text = "a,b"
    array = [%{"a" => 1, "b" => 2, "c" => 3}, %{"a" => 4, "b" => 5, "c" => []}]

    assert FieldMask.mask(text, array) === {:ok, [%{"a" => 1, "b" => 2}, %{"a" => 4, "b" => 5}]}
  end

  test "a/*/b with a is an array" do
    text = "a/*/c"
    data = %{"a" => [%{"c" => 2, "e" => 1}, %{"c" => 4, "f" => 3}]}

    assert_raise BadMapError, fn -> FieldMask.mask(text, data) end
  end

  test "a/*/b with a is an tuple" do
    text = "a/*/c"
    data = %{"a" => {%{"c" => 2, "e" => 1}, %{"c" => 4, "f" => 3}}}

    assert_raise BadMapError, fn -> FieldMask.mask(text, data) end
  end

  test "data is uncompitable with text" do
    text = "a/b"
    data = %{"a" => 1, "b" => 2, "c" => 3}

    assert_raise CaseClauseError, fn -> FieldMask.mask(text, data) end
  end

  test "invalid test except for mismatched brackets" do
    text = "a(b//c"

    assert_raise ArgumentError, fn -> FieldMask.compile(text) end
  end
end
