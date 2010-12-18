-module(beamjs_mod_messaging).
-export([exports/1,init/1]).
-behaviour(erlv8_module).
-include_lib("erlv8/include/erlv8.hrl").
%-behaviour(gen_server2).
%% gen_server2 callbacks
-export([handle_call/3, handle_cast/2, handle_info/2,
		 terminate/2, code_change/3]).


init({gen_server2,This, Emitter}) ->
	{ok, {This, Emitter}};
init(_VM) ->
	ok.

exports(_VM) ->
 	?V8Obj([{"Mailbox", fun new_mailbox/2}]).

prototype() ->
	?V8Obj([{"send", fun send/2}]).


new_mailbox1(#erlv8_fun_invocation{ this = This }=I) ->
	Global = I:global(),
	Require = Global:get_value("require"),
	EventsMod = Require:call(["events"]),
	EventEmitterCtor = EventsMod:get_value("EventEmitter"),

	EventEmitterCtor:call(This,[]),

	This:set_prototype(prototype()),
	Prototype = This:get_prototype(),
	Prototype:set_prototype(beamjs_mod_events:prototype_EventEmitter()), %% FIXME?

	undefined.
	
new_mailbox(#erlv8_fun_invocation{ this = This }=I,[Name]) ->
	new_mailbox1(I),
	Emitter = This:get_value("emit"),
	{ok, Pid} = gen_server2:start({local,list_to_atom(Name)}, ?MODULE, {gen_server2, This, Emitter}, []), %% not sure if we want start or start_link here
	This:set_hidden_value("mailboxServer", Pid),
	undefined;
	
new_mailbox(#erlv8_fun_invocation{ this = This }=I,[]) ->
	new_mailbox1(I),
	Emitter = This:get_value("emit"),
	{ok, Pid} = gen_server2:start(?MODULE, {gen_server2, This, Emitter}, []), %% not sure if we want start or start_link here
	This:set_hidden_value("mailboxServer", Pid),
	undefined.

send(#erlv8_fun_invocation{},[Name, Data]) when is_list(Name) ->
	list_to_existing_atom(Name) ! Data;

send(#erlv8_fun_invocation{},[{erlv8_object, _}=O,Data])  ->
	Pid = O:get_hidden_value("mailboxServer"),
	Pid ! Data.


% gen_server2 

handle_call(_Request, _From, State) ->
	{noreply, State}.

handle_cast(_Msg, State) ->
	{noreply, State}.

handle_info(Info, {This,Emitter}=State) ->
	Emitter:call(This,["info",Info]),
	{noreply, State}.

terminate(_Reason, _State) ->
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.
