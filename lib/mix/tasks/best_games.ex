defmodule Mix.Tasks.BestGames do
  use Mix.Task

  @shortdoc "Downloads the latest SFPA season"

  @moduledoc """
  This is where we would put any long form documentation and doctests.
  """

  @impl Mix.Task
  def run(args) do
    Application.ensure_all_started(:chess)
    to_fen = Chess.to_fen(10, &Chess.pawns_only/1)
    predicate = everything() # acceptable?()

    [filename | rest] = args
    pgns = filename |> Path.expand() |> Chess.pgns()
    case rest do
      ["flow_naive" | _] ->
        pgns |> Chess.flow_naive(predicate, to_fen) |> Enum.each(&process/1)
      ["flow_better" | _] ->
        pgns |> Chess.flow_better(predicate, to_fen) |> Enum.each(&process/1)
      _ ->
        pgns |> Chess.enum_version(predicate, to_fen) |> Enum.each(&process/1)
    end
  end

  defp get_numeric(meta, key) do
    meta |> Map.get(key, "0") |> String.to_integer()
  end

  defp get_min_time(meta) do
    [base, _inc] = meta |> Map.get("TimeControl", "1+0") |> String.split("+") |> Enum.map(&String.to_integer/1)
    2 * base
    rescue _ -> [1, 0]
  end

  def everything(), do: fn _pgn -> true end

  def acceptable?(min_elo \\ 2400, min_time \\ 600) do
    fn pgn ->
      metadata = Chess.metadata(pgn)
      white_elo = get_numeric(metadata, "WhiteElo")
      black_elo = get_numeric(metadata, "BlackElo")
      time = get_min_time(metadata)
      white_elo >= min_elo and black_elo >= min_elo and time >= min_time
    end
  end

  def process({fen, count}) do
    fen |> ChessLogic.Position.from_fen() |> ChessLogic.Position.print()
    IO.puts "occurred #{count} times"
  end

  # We can define other functions as needed here.
end

# flow
# Executed in  185.26 secs    fish           external
#    usr time  171.74 secs  140.00 micros  171.74 secs
#    sys time    4.42 secs  817.00 micros    4.42 secs

# enum
# Executed in  197.90 secs    fish           external
#    usr time  172.27 secs  156.00 micros  172.27 secs
#    sys time    5.20 secs  803.00 micros    5.20 secs
