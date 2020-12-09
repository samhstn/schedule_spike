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

    {:ok, {frequency, nil}}
  end

  defp frequency_to_ms(:short), do: @short
  defp frequency_to_ms(:medium), do: @medium
  defp frequency_to_ms(:long), do: @long

  def never(), do: GenServer.call(__MODULE__, {:update_frequency, :never})
  def short(), do: GenServer.call(__MODULE__, {:update_frequency, :short})
  def medium(), do: GenServer.call(__MODULE__, {:update_frequency, :medium})
  def long(), do: GenServer.call(__MODULE__, {:update_frequency, :long})

  defp update_timer(frequency, timer) do
    if timer do
      Process.cancel_timer(timer)
    end

    schedule_work(frequency)
  end

  def handle_call({:update_frequency, frequency}, _from, {old_frequency, timer}) do
    new_timer = update_timer(frequency, timer)

    {:reply,
     "Updating schedule from #{old_frequency} to #{frequency}, with timer: #{inspect(new_timer)}",
     {frequency, new_timer}}
  end

  def handle_info({:work, frequency}, {_old_frequency, timer}) do
    new_timer = update_timer(frequency, timer)

    Logger.info("Work after #{frequency_to_ms(frequency)}ms, with timer #{inspect(new_timer)}")

    {:noreply, {frequency, new_timer}}
  end

  defp schedule_work(:never), do: nil

  defp schedule_work(frequency) do
    Process.send_after(self(), {:work, frequency}, frequency_to_ms(frequency))
  end
end
