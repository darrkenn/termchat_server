defmodule Utils.Json do
  def read_decode(path) do
    case File.read(path) do
      {:ok, contents} ->
        case Jason.decode(contents) do
          {:ok, data} -> {:ok, data}
          {:error, error} -> {:error, {:decode_error, error}}
        end

      {:error, error} ->
        {:error, {:read_error, error}}
    end
  end
end
