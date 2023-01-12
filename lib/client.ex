defmodule LedboardTester.Client do
  # FPanel.LedBoard.Client.update("10.91.9.90", 10001, [%{number: "22A", time: "3"}])
  def update(address, port, forecast) do
    IO.inspect("ESTABLISHING TCP CONNECTION...")

    {:ok, socket} =
      :gen_tcp.connect(String.to_charlist(address), port, [{:active, false}, :binary])

    IO.inspect("SUCCESS")
    IO.inspect("BUILDING TRANSPORT REQ...")
    tv_pkt = build_transport_req(k_SDK_Service_Ask(), <<tcp_version()::little-32>>)
    IO.inspect("SUCCESS")
    IO.inspect("SENDING TRANSPORT REQ...")
    :ok = :gen_tcp.send(socket, tv_pkt)
    IO.inspect("SUCCESS")
    IO.inspect("RECIEVING RESPONSE...")
    {:ok, data} = :gen_tcp.recv(socket, 0, 10_000)
    IO.inspect("SUCCESS")
    IO.inspect("PARSING RESPONSE...")
    {:ok, cmd, data} = parse_transport_resp(data)
    IO.inspect("SUCCESS")
    # IO.inspect({cmd, parse_data(cmd, data)})

    xml_data = ~s{<?xml version="1.0" encoding="utf-8"?>
      <sdk guid="##GUID">
        <in method="GetIFVersion">
          <version value="1000000"/>
        </in>
      </sdk>
    }

    IO.inspect("BUILDING SDK REQ...")
    sdk_pkt = build_transport_req(k_SDK_Cmd_Ask(), build_sdk_req(xml_data))
    IO.inspect("SUCCESS")
    IO.inspect("SENDING SDK REQ...")
    :ok = :gen_tcp.send(socket, sdk_pkt)
    IO.inspect("SUCCESS")
    IO.inspect("RECIEVING RESPONSE...")
    {:ok, data} = :gen_tcp.recv(socket, 0, 10_000)
    IO.inspect("SUCCESS")
    IO.inspect("PARSING RESPONSE...")
    {:ok, cmd, data} = parse_transport_resp(data)
    IO.inspect("SUCCESS")
    # IO.inspect({cmd, parse_data(cmd, data)})

    sdk_data = parse_data(cmd, data)

    %{"guid" => guid} = Regex.named_captures(~r/sdk guid\="(?<guid>.+)"/iu, sdk_data)

    timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    xml_data = ~s{<?xml version="1.0" encoding="utf-8"?>
        <sdk guid="#{guid}">
          <in method="AddProgram">
            <screen timeStamps="#{timestamp}">
              <program type="normal" id="0" guid="e1d934c6-df81-465c-8093-1fa7c7692507" name="">
                <playControl count="1" disabled="false" />
                #{format_forecast(forecast)}
                <area guid="#{UUID.uuid4()}" name="" alpha="255">
                  <rectangle x="#{95}" y="4" width="4" height="60" />
                  <resources>
                    <text guid="#{UUID.uuid4()}" name="" singleLine="false">
                      <style align="center" valign="top" />
                      <string>|\n|\n|\n|\n</string>
                      <font name="Arial" size="12" color="#804000" bold="false" italic="false" underline="false" />
                    </text>
                  </resources>
                </area>
              </program>
            </screen>
          </in>
        </sdk>
    }

    IO.inspect("BUILDING SDK PKT...")
    sdk_pkt = build_transport_req(k_SDK_Cmd_Ask(), build_sdk_req(xml_data))
    IO.inspect("SUCCESS")
    IO.inspect("SENDING SDK PKT...")
    :ok = :gen_tcp.send(socket, sdk_pkt)
    IO.inspect("SUCCESS")
    IO.inspect("RECIEVING RESPONSE...")
    {:ok, data} = :gen_tcp.recv(socket, 0, 10_000)
    IO.inspect("SUCCESS")
    IO.inspect("PARSING RESPONSE...")
    {:ok, cmd, data} = parse_transport_resp(data)
    IO.inspect("SUCCESS")
    # IO.inspect({cmd, parse_data(cmd, data)})

    IO.inspect("CLOSING TCP CONNECTION...")
    :ok = :gen_tcp.close(socket)
    IO.inspect("SUCCESS")
  end

  def build_sdk_req(data) do
    data = String.replace(data, "\n", "\r\n")
    <<byte_size(data)::little-32, 0x00::little-32, data::binary>>
  end

  def build_transport_req(cmd, data) do
    <<byte_size(data) + 4::little-16, cmd::little-16, data::binary>>
  end

  def parse_data(:kErrorAnswer, <<error::little-16>>), do: error_code(error)

  def parse_data(:kSDKServiceAnswer, <<version::little-32>>), do: version

  def parse_data(:kSDKCmdAnswer, <<_length::little-32, _index::little-32, data::bytes>>),
    do: data

  def parse_data(_, <<version::little-32>>), do: version

  def parse_transport_resp(<<_length::little-16, cmd_code::little-16, data::bytes>>) do
    {:ok, parse_cmd_code(cmd_code), data}
  end

  def tcp_version(), do: 0x1000005

  def k_SDK_Service_Ask(), do: 0x2001

  def k_SDK_Cmd_Ask(), do: 0x2003

  def parse_cmd_code(code) do
    %{
      -1 => :kUnknown,
      # TCP heartbeat packet request.
      0x005F => :kTcpHeartbeatAsk,
      # TCP heartbeat packet response.
      0x0060 => :kTcpHeartbeatAnswer,
      # Search for device request.
      0x1001 => :kSearchDeviceAsk,
      # Search for device response.
      0x1002 => :kSearchDeviceAnswer,
      # Error response.
      0x2000 => :kErrorAnswer,
      # SDK version request.
      0x2001 => :kSDKServiceAsk,
      # SDK version response.
      0x2002 => :kSDKServiceAnswer,
      # SDK command request.
      0x2003 => :kSDKCmdAsk,
      # SDK command response.
      0x2004 => :kSDKCmdAnswer,
      # Start to transfer file request.
      0x8001 => :kFileStartAsk,
      # Start to transfer file response.
      0x8002 => :kFileStartAnswer,
      # Transfer file content request.
      0x8003 => :kFileContentAsk,
      # Transfer file content response. This instruction is ignored.
      0x8004 => :kFileContentAnswer,
      # End the file transfer request.
      0x8005 => :kFileEndAsk,
      # End the file transfer response.
      0x8006 => :kFileEndAnswer,
      # Read file request.
      0x8007 => :kReadFileAsk,
      # Read file response.
      0x8008 => :kReadFileAnswer
    }[code]
  end

  def error_code(code) do
    [
      :kUnknown,
      :kSuccess,
      # Finish writing to the file.
      :kWriteFinish,
      # Process Error
      :kProcessError,
      # The version is too low.
      :kVersionTooLow,
      # The device is occupied.
      :kDeviceOccupa,
      # The file is occupied.
      :kFileOccupa,
      # Too many users reading back the file.
      :kReadFileExcessive,
      # Invalid packet length.
      :kInvalidPacketLen,
      # Invalid parameter.
      :kInvalidParam,
      # Storage capacity is not enough.
      :kNotSpaceToSave,
      # Failed to create file.
      :kCreateFileFailed,
      # Failed to write file.
      :kWriteFileFailed,
      # Failed to read file.
      :kReadFileFailed,
      # Invalid file data.
      :kInvalidFileData,
      # The file content is incorrect.
      :kFileContentError,
      # Failed to open file.
      :kOpenFileFailed,
      # Failed to seek file.
      :kSeekFileFailed,
      # Failed to rename file.
      :kRenameFailed,
      # Failed to find file.
      :kFileNotFound,
      # The file did not complete the transfer.
      :kFileNotFinish,
      # The xml command is too long.
      :kXmlCmdTooLong,
      # Invalid Xml index
      :kInvalidXmlIndex,
      # Error parsing xml.
      :kParseXmlFailed,
      # Invalid method
      :kInvalidMethod,
      # Memory error.
      :kMemoryFailed,
      # System error
      :kSystemError,
      # Unsupported video.
      :kUnsupportVideo,
      # Not a multimedia file.
      :kNotMediaFile,
      # Failed to parse the video file.
      :kParseVideoFailed,
      # Unsupported frame rate.
      :kUnsupportFrameRate,
      # Unsupported resolution (video).
      :kUnsupportResolution,
      # Unsupported format (video).
      :kUnsupportFormat,
      # Unsupported length of time (video).
      :kUnsupportDuration,
      # Download file failed.
      :kDownloadFileFailed,
      :kScreenNodeIsNull,
      :kNodeExist,
      :kNodeNotExist,
      :kPluginNotExist,
      :kCheckLicenseFailed,
      :kNotFoundWifiModule,
      :kTestWifiUnsuccessful,
      :kRunningError,
      :kUnsupportMethod,
      :kInvalidGUID,
      :kDelayRespond,
      :kShortlyReturn,
      :KConnectionFailed,
      :kCount
    ]
    |> Enum.at(code + 1)
  end

  def format_forecast(data) do
    width = 192
    height = 64
    padding_top = 4
    divider_width = 12
    effective_height = height - padding_top
    numbers_width_ratio = 0.45
    numbers_width = trunc((width - divider_width) / 2 * numbers_width_ratio)
    times_width = trunc((width - divider_width) / 2 - numbers_width)

    offsets = [
      {1, numbers_width + 1},
      {divider_width + numbers_width + times_width - 1,
       divider_width + numbers_width * 2 + times_width}
    ]

    data
    |> Enum.slice(0..7)
    |> Enum.chunk_every(4)
    |> Enum.with_index()
    |> Enum.map(fn {forecasts, index} ->
      {offset_left, offset_right} = Enum.at(offsets, index)

      numbers =
        forecasts
        |> Enum.map(fn %{number: n} -> n end)
        |> Enum.join("\n")

      times =
        forecasts
        |> Enum.map(fn %{time: t} -> "#{t}" <> " мин" end)
        |> Enum.join("\n")

      ~s{<area guid="#{UUID.uuid4()}" name="" alpha="255">
        <rectangle x="#{offset_left}" y="#{padding_top}" width="#{numbers_width}" height="#{effective_height}" />
        <resources>
          <text guid="#{UUID.uuid4()}" name="" singleLine="false">
            <style align="left" valign="top" />
            <string>#{numbers}</string>
            <font name="Arial" size="12" color="#804000" bold="false" italic="false" underline="false" />
          </text>
        </resources>
      </area>
      <area guid="#{UUID.uuid4()}" name="" alpha="255">
        <rectangle x="#{offset_right}" y="#{padding_top}" width="#{times_width}" height="#{effective_height}" />
        <resources>
          <text guid="#{UUID.uuid4()}" name="" singleLine="false">
            <style align="right" valign="top" />
            <string>#{times}</string>
            <font name="Arial" size="12" color="#804000" bold="false" italic="false" underline="false" />
          </text>
        </resources>
      </area>}
    end)
    |> Enum.join()
  end
end
