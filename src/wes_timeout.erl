-module(wes_timeout).

%% Make this into some kind of heap if this implementation has
%% performance impact.

-export([next/1,
         reset/3,
         new/0,
         add/4,
         to_list/1,
         now_milli/0,
         time_diff/2]).

next(Timeouts) ->
    dict:fold(fun(Name, {NextTimeout, _}, {NameAcc, TimeoutAcc}) ->
                      if TimeoutAcc == infinity -> {Name, NextTimeout};
                         TimeoutAcc =< NextTimeout -> {NameAcc, TimeoutAcc};
                         true -> {Name, NextTimeout}
                      end
              end,
              {bogus, infinity},
              Timeouts).

to_list(Timeouts) ->
    dict:to_list(Timeouts).

reset(Name, Now, Timeouts) ->
    dict:update(Name, fun({_OldTimeout, Timeout}) ->
                              {Now+Timeout, Timeout}
                      end,
                Timeouts).

add(Name, infinite, _Now, Timeouts) ->
    dict:erase(Name, Timeouts);
add(Name, Timeout, Now, Timeouts) ->
    dict:store(Name, {Timeout+Now, Timeout}, Timeouts).

new() ->
    dict:new().

now_milli() -> erlang:system_time(milli_seconds).

time_diff(infinity, _) -> infinity;
time_diff(A, B) -> max(0, A - B).
