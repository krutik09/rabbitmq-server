-module(rabbit_custom_interceptor).
-export([intercept/1]).
-export([read_schema_file/1]).
read_schema_file(Msg) ->
    case file:read_file("/tmp/schema.json") of                 
        {ok, Content} ->
            case decode_schema(Content) of
                true ->
                    case validate_message("validation_key", Msg) of
                        true ->
                            true;
                        false ->
                            rabbit_log:error("Message validation failed"),
                            false
                    end;
                false ->
                    rabbit_log:error("Failed to decode schema"),
                    false
            end;
        {error, Reason} ->
            case filelib:is_file("/tmp/schema.json") of
                true ->
                    rabbit_log:error("Error reading file: ~p", [Reason]),
                    false;
                false ->
                    rabbit_log:info("Schema file does not exist. All the messages will be forwarded without data validation"),
                    true
            end
    end.

% Decodes schema content and adds it using Jesse, returns true if successful, false otherwise.
decode_schema(Content) ->
    try
        Schema = jsx:decode(Content),
        jesse:add_schema("validation_key", Schema),
        true
    catch
        ErrorType:ErrorReason ->
            rabbit_log:error("Failed to decode schema. Error: ~p:~p", [ErrorType, ErrorReason]),
            false
    end.

% Validates a message against a schema, returns true if valid, false otherwise.
validate_message(SchemaKey, Msg) ->
    try
        DecodedMsg = jsx:decode(Msg),
        case jesse:validate(SchemaKey, DecodedMsg) of
            {ok,_Result} ->
                true;
            {error, ValidationErrors} ->
                rabbit_log:error("Message validation failed: ~p", [ValidationErrors]),
                false
        end
    catch
        ErrorType:ErrorReason ->
            rabbit_log:error("Failed to validate message. Error: ~p:~p", [ErrorType, ErrorReason]),
            false
    end.

intercept(Msg) ->
    case read_schema_file(Msg) of
            true -> true;
            false -> false
    end.