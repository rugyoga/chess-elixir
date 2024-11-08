defmodule Mix.Tasks.CountGames do
  use Mix.Task

  @shortdoc "Downloads the latest SFPA season"

  @moduledoc """
  This is where we would put any long form documentation and doctests.
  """

  @impl Mix.Task
  def run(_args) do
    filename = "/Users/guy/Downloads/lichess_db_standard_rated_2024-09.pgn"
    Application.ensure_all_started(:chess)
    filename
    |> Chess.pgns()
    |> Enum.count()
    |> IO.puts
  end

  # We can define other functions as needed here.
end
