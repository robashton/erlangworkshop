-module(blinkyblink).
-export([start/0, stop/0, blink/1, clicky/1]).

init() ->
  application:start(gproc),
  gpio:start_link({18, output}),
  gpio:start_link({23, output}),
  gpio:start_link({24, output}),
  gpio:start_link({17, input}),
  gpio:start_link({22, input}).

teardown() ->
  gpio:release(18),
  gpio:release(23),
  gpio:release(17),
  gpio:release(22),
  gpio:release(24).

blink(Pin) ->
	gpio:write(Pin, 1),
	timer:sleep(500),

	gpio:write(Pin, 0),

  receive
    stop ->
      exit(instructed)
  after
    500 ->
      blink(Pin)
  end.

check_for_rising(Pin) ->
  timer:sleep(100),
  case gpio:read(Pin) of
    1 -> stop();
    0 -> clicky(Pin)
  end.

clicky(Pin) ->
	gpio:set_int(Pin, rising),
  receive
    stop -> exit(instructed);
    {gpio_interrupt, Pin, _} -> check_for_rising(Pin)
  end.



stop() ->
  clicky17 ! stop,
  clicky22 ! stop,
  blink18 ! stop,
  blink23 ! stop,
  blink24 ! stop,
  teardown().

start() ->
	init(),
  register(blink18, spawn(blinkyblink, blink, [18])),
  timer:sleep(800),
  register(blink23, spawn(blinkyblink, blink, [23])),
  timer:sleep(900),
  register(blink24, spawn(blinkyblink, blink, [24])),
  register(clicky17, spawn(blinkyblink, clicky, [17])),
  register(clicky22, spawn(blinkyblink, clicky, [22])).
