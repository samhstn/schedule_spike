defmodule ScheduleSpike do
  use GenServer

  require Logger

  @short 5 * 1000
  @medium 15 * 1000
  @long 30 * 1000

  def start_link(_) do
    GenServer.start_link(__MODULE__, :never, name: __MODULE__)
  end

  def init(frequency) do
    schedule_work(frequency)

    {:ok, {frequency, []}}
  end

  defp frequency_to_ms(:short), do: @short
  defp frequency_to_ms(:medium), do: @medium
  defp frequency_to_ms(:long), do: @long

  def never(), do: GenServer.call(__MODULE__, {:work, :never})
  def short(), do: GenServer.call(__MODULE__, {:work, :short})
  def medium(), do: GenServer.call(__MODULE__, {:work, :medium})
  def long(), do: GenServer.call(__MODULE__, {:work, :long})

  defp update_timers(frequency, timers) do
    Enum.each(timers, &Process.cancel_timer/1)

    case frequency do
      :never -> timers
      _ -> [schedule_work(frequency) | Enum.filter(timers, &Process.read_timer/1)]
    end
  end

  def handle_call({:work, frequency}, _from, {old_frequency, timers}) do
    new_timers = update_timers(frequency, timers)

    {:reply,
     "Updating schedule from #{old_frequency} to #{frequency}, with timers: #{inspect(new_timers)}",
     {frequency, new_timers}}
  end

  def handle_info({:work, frequency}, {_old_frequency, timers}) do
    new_timers = update_timers(frequency, timers)

    Logger.info("Work after #{frequency_to_ms(frequency)}ms, with timers #{inspect(new_timers)}")

    {:noreply, {frequency, new_timers}}
  end

  defp schedule_work(:never), do: nil

  defp schedule_work(frequency) do
    Process.send_after(self(), {:work, frequency}, frequency_to_ms(frequency))
  end
end
