defmodule FieldMaskTest do
  @moduledoc false
  use ExUnit.Case
  doctest FieldMask

  test "offcial example of Google+" do
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
end
