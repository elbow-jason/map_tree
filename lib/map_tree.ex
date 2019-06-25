defmodule MapTree do
  @moduledoc """
  MapTree is a for building trees of nested maps.

  Given a `tree` of nested maps a list of `keys` MapTree changes or fetches the "leaves" of the tree of maps.
  """

  @type tree :: map()
  @type leaf :: any()
  @type keys :: list(any)

  @doc """
  Puts a `leaf` into a `tree` nested in the location of the `keys`.

      iex> MapTree.put(%{}, [1, 2, 3], :yes)
      {:ok, %{1 => %{2 => %{3 => :yes}}}}

      iex> {:ok, tree} = MapTree.put(%{}, [1, 2], :yes)
      iex> MapTree.put(tree, [1, 2, 3], :no)
      {:error, {:not_a_map, 2}}
  """
  @spec put(tree, keys, leaf) :: {:error, {:not_a_map, any}} | {:ok, tree}
  def put(tree, keys, leaf) do
    change(tree, keys, fn submap, key -> Map.put(submap, key, leaf) end)
  end

  @doc """
  Fetches a sub-`tree` or leaf` of the `tree` from the location of the `keys`.

  Returns an error tuple when a subtree in the `tree` is not a map or is not found.

      iex> {:ok, tree} = MapTree.put(%{}, [1, 2, 3], :yes)
      iex> MapTree.fetch(tree, [1, 2, 3])
      {:ok, :yes}

      iex> {:ok, tree} = MapTree.put(%{}, [1, 2, 3], :yes)
      iex> MapTree.fetch(tree, [1, 2])
      {:ok, %{3 => :yes}}

      iex> {:ok, tree} = MapTree.put(%{}, [1, 2, 3], :yes)
      iex> MapTree.fetch(tree, [1, 2, 4])
      {:error, :not_found}

      iex> {:ok, tree} = MapTree.put(%{}, [1, 2, 3], :yes)
      iex> MapTree.fetch(tree, [1, 2, 3, 4])
      {:error, {:not_a_map, 3}}
  """
  @spec fetch(tree, keys) :: {:error, :not_found | {:not_a_map, any}} | {:ok, any}
  def fetch(map, [key]) do
    case Map.fetch(map, key) do
      {:ok, _} = ok -> ok
      :error -> {:error, :not_found}
    end
  end

  def fetch(map, [key | rest]) do
    case Map.fetch(map, key) do
      {:ok, next} when is_map(next) ->
        fetch(next, rest)

      {:ok, _} ->
        {:error, {:not_a_map, key}}

      _ ->
        {:error, :not_found}
    end
  end

  @doc """
  Puts or updates a sub-`tree` or leaf` of the `tree` at the location of the `keys`.

  Returns an error tuple when a subtree in the `tree` is not a map.


      iex> MapTree.update(%{}, [1, 2], 1, fn n -> n + 1 end)
      {:ok, %{1 => %{2 => 1}}}

      iex> {:ok, tree} = MapTree.put(%{}, [1, 2], 10)
      iex> MapTree.update(tree, [1, 2], 1, fn n -> n + 1 end)
      {:ok, %{1 => %{2 => 11}}}


      iex> {:ok, tree} = MapTree.put(%{}, [1, 2], 10)
      iex> MapTree.update(tree, [1, 2, 3], 1, fn n -> n + 1 end)
      {:error, {:not_a_map, 2}}
  """
  @spec update(tree, keys, any, (any -> any)) :: {:error, {:not_a_map, any}} | {:ok, any}
  def update(map, keys, initial, mapper) when is_map(map) do
    change(map, keys, fn submap, key -> Map.update(submap, key, initial, mapper) end)
  end

  @doc """
  Deletes the last `key` of `keys` from the `tree`. If the keypath leads through
  a non-map and error tuple is returned.

      iex> {:ok, tree} = MapTree.put(%{}, [1, 2], 10)
      iex> MapTree.delete(tree, [1, 2])
      {:ok, %{1 => %{}}}

      iex> {:ok, tree} = MapTree.put(%{}, [1, 2, 3], 10)
      iex> MapTree.delete(tree, [1, 2, 3, 4])
      {:error, {:not_a_map, 3}}
  """
  @spec delete(tree, keys) :: {:error, {:not_a_map, any}} | {:ok, tree}
  def delete(map, keys) do
    change(map, keys, fn submap, key -> Map.delete(submap, key) end)
  end

  defp change(map, [key], mapper) when is_map(map) do
    {:ok, mapper.(map, key)}
  end

  defp change(map, [key | rest], mapper) when is_map(map) do
    with(
      {:ok, submap} when is_map(submap) <- Map.fetch(map, key),
      {:ok, changed} <- change(submap, rest, mapper)
    ) do
      {:ok, Map.put(map, key, changed)}
    else
      :error ->
        case change(%{}, rest, mapper) do
          {:ok, submap} ->
            {:ok, Map.put(map, key, submap)}

          err ->
            err
        end

      {:error, _} = err ->
        err

      {:ok, _} ->
        {:error, {:not_a_map, key}}
    end
  end
end
