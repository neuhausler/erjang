%%
%% This file is part of Erjang
%%
%% Copyright (c) 2010 by Trifork
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%  
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%

-module(test_server).

-export([timetrap/1, timetrap_cancel/1, 
	 minutes/1, seconds/1,
	 timecall/3,
	 do_times/4, 
	 lookup_config/2,
	 format/2, format/1,
	 fail/0, fail/1, fail/2
	]).

minutes(Minutes) ->
    seconds (Minutes * 60).

seconds(Seconds) ->
    Seconds * 1000.

timetrap(Millis) ->
    Self = self(),
    spawn(fun() -> timetrapper(Millis, Self) end).

timetrap_cancel(Ref) ->
    Ref ! {cancel, self()}.

% private
timetrapper(Millis,Owner) ->
    receive 
	{cancel, Owner} ->
	    done
    after Millis ->
	    erlang:exit(Owner, kill),
	    io:format("Killed ~p~n", [Owner])
    end.


%% Like timer:tc/3, but reports seconds
timecall(Mod,Fun,Args) ->
    {Micros,Result} = timer:tc(Mod,Fun,Args),
    {Micros / 1000000.0, Result }.

do_times_N(0,_Mod,_Fun,_Args) -> ok;
do_times_N(Count,Mod,Fun,Args) when Count > 0 ->
    apply(Mod,Fun,Args),
    do_times_N(Count-1,Mod,Fun,Args).

do_times_0(0,_Fun) -> ok;
do_times_0(Count,Fun) ->
    Fun(),
    do_times_0(Count-1,Fun).

do_times_1(0,_Fun,_A1) -> ok;
do_times_1(Count,Fun,A1) ->
    Fun(A1),
    do_times_1(Count-1,Fun,A1).

do_times_2(0,_Fun,_,_) -> ok;
do_times_2(Count,Fun,A1,A2) ->
    Fun(A1,A2),
    do_times_2(Count-1,Fun,A1,A2).

do_times_3(0,_Fun,_,_,_) -> ok;
do_times_3(Count,Fun,A1,A2,A3) ->
    Fun(A1,A2,A3),
    do_times_3(Count-1,Fun,A1,A2,A3).


do_times(N,M,F,A) ->
    Fun = erlang:make_fun(M,F,length(A)),
    case A of
	[] -> do_times_0(N, Fun);
	[A1] -> do_times_1(N, Fun, A1);
	[A1,A2] -> do_times_2(N, Fun, A1, A2);
	[A1,A2,A3] -> do_times_3(N, Fun, A1, A2, A3);
	_ -> do_times_N(N,M,F,A)
    end.



lookup_config(Key,Config) when is_atom(Key) ->
    {Key,Value} = lists:keyfind(Key,1,Config),
    Value.

format(Template, Args) when is_list(Args) ->
    io:format(Template, Args).

format(Template) ->
    io:format(Template).

fail() ->
    erlang:error(fail).

fail(Msg) ->
    erlang:error({fail,Msg}).

fail(Msg,More) ->
    erlang:error({fail,Msg,More}).
