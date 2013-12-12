-module(blinkyblink).
-export([start/0, stop/0, on_click/2, controller/1]).

init() ->
  application:start(gproc),
  gpio:start_link({17, input}),
  gpio:start_link({22, input}).

teardown() ->
  gpio:release(17),
  gpio:release(22).


on_click(Pin, Fn) ->
  gpio:set_int(Pin, rising),
  clicky(Pin, Fn).



clicky(Pin, Fn) ->
  receive
    stop -> exit(instructed);
    {gpio_interrupt, Pin, rising} -> 
      receive
        {gpio_interrupt, Pin, rising} -> Fn(), clicky(Pin, Fn)
      after 1000 -> clicky(Pin, Fn)
      end
  end.

controller(running) ->
  io:format("Blinking"),
  receive
    stop -> blinkers:stop(), exit(instructed);
    off -> blinkers:stop(), controller(notrunning)
  end;

controller(notrunning) ->
  io:format("Now not blinking"),
  receive
    stop -> exit(instructed);
    on -> blinkers:start(), controller(running)
  end.

stop() ->
  clicky17 ! stop,
  clicky22 ! stop,
  controller_pid ! stop,
  teardown().

start() ->
	init(),
  register(controller_pid, spawn(blinkyblink, controller, [notrunning])),
  register(clicky17, spawn(blinkyblink, on_click, 
                           [17, fun() -> controller_pid ! on end])),
  register(clicky22, spawn(blinkyblink, on_click,
                           [22, fun() -> controller_pid ! off end])).



