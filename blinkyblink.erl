-module(blinkyblink).
-export([start/0, stop/0, blink/1]).

init() ->
  application:start(gproc),
  gpio:start_link({18, output}),
  gpio:start_link({23, output}),
  gpio:start_link({24, output}).

teardown() ->
  gpio:release(18),
  gpio:release(23),
  gpio:release(24).

blink(Pin) ->
	gpio:write(Pin, 1),
	io:format("LED on~n"),
	timer:sleep(500),

	gpio:write(Pin, 0),
	io:format("LED off~n"),

  receive
    stop ->
      exit(instructed)
  after
    500 ->
      blink(Pin)
  end.

stop() ->
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
  register(blink24, spawn(blinkyblink, blink, [24])).
