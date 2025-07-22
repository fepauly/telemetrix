defmodule Telemetrix.Influx.SensorDataPoint do
  use Instream.Series

  series do
    measurement "sensor_data"

    tag :device_id
    tag :type

    field :value
  end
end
