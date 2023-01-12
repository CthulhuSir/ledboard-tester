defmodule LedboardTester do
  def main() do
    call(System.get_env("HOST"), System.get_env("PORT") |> String.to_integer())
  end

  def call(ip, port) do

    IO.inspect([ip: ip, port: port])
    data = [
      %{number: 0, time: 0},
      %{number: 0, time: 0},
      %{number: 0, time: 0},
      %{number: 0, time: 0},
      %{number: 0, time: 0},
      %{number: 0, time: 0},
      %{number: 0, time: 0},
      %{number: 0, time: 0},
      %{number: 0, time: 0},
      %{number: 0, time: 0}
    ]

    LedboardTester.Client.update(ip, port, data)
  end
end
