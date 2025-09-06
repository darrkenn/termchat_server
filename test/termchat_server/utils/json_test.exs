defmodule Utils.JsonTest do
  use ExUnit.Case, async: true
  alias Utils.Json

  describe "read_decode/1" do
    test "successfully read and decode json" do
      json_path = "test/tmp_successful.json"
      File.write!(json_path, ~s({"type":"test","successful":"true"}))

      assert Json.read_decode(json_path) == {:ok, %{"type" => "test", "successful" => "true"}}

      File.rm(json_path)
    end

    test "return read_error if file doesnt exist" do
      json_path = "test/tmp_nonexistant.json"

      assert {:error, {:read_error, _}} = Json.read_decode(json_path)
    end

    test "return decode error for bad json" do
      json_path = "test/tmp_bad.json"
      File.write!(json_path, "uh oh")

      assert {:error, {:decode_error, _}} = Json.read_decode(json_path)
      File.rm(json_path)
    end
  end
end
