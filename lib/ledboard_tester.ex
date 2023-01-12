defmodule LedboardTester do
  def main(args) do
    opts = [switches: [ip: :string, port: :integer]]
    {[ip: ip, port: port], [], []} = OptionParser.parse(args, opts)
    IO.inspect([ip: ip, port: port])
    call(ip, port)
  end

  def call(ip, port) do
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
