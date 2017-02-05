defmodule LogicAlarmReducers do
  def reduce state = %{alarm: :boot}, :clock_tick do
    %{state | alarm: :idle}
  end

  def reduce state = %{alarm: :idle}, :alarm_check do
    alarm_time = state.time
      |> Timex.set(hour: state.alarm_hour, minute: state.alarm_minute, second: 0)
      |> Timex.shift(minutes: -1 * state.sunrise_duration)
    alarm_time_later = alarm_time |> Timex.shift(minutes: 2)
    if state.alarm_active && Timex.between? state.time, alarm_time, alarm_time_later do
      %{state | alarm: :sunrise, brightness: 0, brightness_delta: get_brightness_delta(state)}
    else
      state
    end
  end

  def reduce state = %{alarm: :sunrise}, :clock_tick do
    new_brightness = min(state.brightness + state.brightness_delta, 255)
    if new_brightness >= 255 do
      %{state | brightness: new_brightness, alarm: :alarm}
    else
      %{state | brightness: new_brightness}
    end
  end

  def reduce state = %{alarm: :sunrise}, :touch do
    %{state | alarm: :idle}
  end

  def reduce state = %{alarm: :alarm}, :touch do
    %{state | alarm: :idle}
  end

  def reduce(state, _) do
    state
  end

  defp get_brightness_delta state do
    max_brightness = 16 * state.max_brightness + 15
    max_brightness / max(state.sunrise_duration * 60, 1)
  end
end
