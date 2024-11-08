defmodule Chess do

  @spec pgns(binary) :: Enumerable.t()
  def pgns(filename) do
    finalise = fn acc -> acc |> Enum.reverse() |> Enum.join() end
    #{:ok, file} = File.open(filename, [:read, :utf])
    filename
    |> File.stream!()
    |> Stream.chunk_while(
      [],
      fn elem, acc ->
        if String.starts_with?(elem, "[Event") do
          {:cont, finalise.(acc), [elem]}
        else
          {:cont, [elem | acc]}
        end
      end,
      fn
        [] -> {:cont, []}
        acc -> {:cont, finalise.(acc), []}
      end)
    |> Stream.drop(1)
  end

  def split_native(filename) do
    ChessLogic.from_pgn_file(filename)
  end

  def metadata(pgn) do
    pgn
    |> String.split("\n", trim: true)
    |> Enum.filter(&String.starts_with?(&1, "["))
    |> Enum.flat_map(fn line ->
      matches = Regex.named_captures(~r/\[(?<name>\S*)\s+\"(?<value>.*)\"\]/, line)
      if is_nil(matches) do
        []
      else
        [{matches["name"], matches["value"]}]
      end
    end)
    |> Map.new()
  end

  def to_fen(move_num, f \\ fn x -> x end) do
    fn pgn ->
      [g] = ChessLogic.from_pgn(pgn)
      p = g.history |> Enum.at(-(1 + 2*move_num))
      if(is_nil(p), do: [], else: [f.(p.fen)])
    end
  end

  def enum_version(pgns, predicate, to_fen) do
    pgns
    |> Stream.filter(predicate)
    |> Stream.flat_map(to_fen)
    |> Enum.frequencies()
    |> Enum.sort_by(fn {_k, v} -> v end, :desc)
    |> Enum.take(10)
  end

  def flow_naive(pgns, predicate, to_fen) do
    pgns
    |> Flow.from_enumerable()
    |> Flow.filter(predicate)
    |> Flow.flat_map(to_fen)
    |> Flow.partition()
    |> Chess.top_n_flow()
    |> Enum.to_list()
    |> hd()
  end

  def flow_better(pgns, predicate, to_fen) do
    pgns
    |> Flow.from_enumerable()
    |> Flow.partition()
    |> Flow.filter(predicate)
    |> Flow.flat_map(to_fen)
    |> Flow.partition()
    |> Chess.top_n_flow()
    |> Enum.to_list()
    |> hd()
  end

  def top_n_flow(stream, n \\ 10) do
    stream
    |> Flow.reduce(
      fn -> %{} end,
      fn fen, map -> Map.update(map, fen, 1, & &1 + 1) end
    )
    |> Flow.take_sort(n, fn {_pos_a, count_a}, {_pos_b, count_b} -> count_b <= count_a end)
  end


  # pawns("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1") => "8/pppppppp/8/8/8/8/PPPPPPPP/8 w KQkq - 0 1"
  def pawns_only(fen) do
    [board | rest] = String.split(fen, " ")
    board
    |> String.split("/")
    |> Enum.map(
      fn rank ->
        rank
        |> String.split("", trim: true)
        |> Enum.map(fn ch -> if(ch in ["r", "n", "b", "q", "k", "R", "N", "B", "Q", "K"], do: "1", else: ch) end)
        |> Enum.map(fn ch -> if(ch in ["p", "P"], do: ch, else: String.to_integer(ch)) end)
        |> Enum.chunk_by(&is_integer/1)
        |> Enum.map(fn chunks -> if is_integer(hd(chunks)), do: ["#{Enum.sum(chunks)}"], else: chunks end)
        |> Enum.join()
      end
    )
    |> Enum.join("/")
    |> then(&[&1 | rest])
    |> Enum.join(" ")
  end

end
