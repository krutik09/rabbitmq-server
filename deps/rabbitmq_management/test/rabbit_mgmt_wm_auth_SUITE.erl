%% This Source Code Form is subject to the terms of the Mozilla Public
%% License, v. 2.0. If a copy of the MPL was not distributed with this
%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%
%% Copyright (c) 2007-2023 Broadcom. All Rights Reserved. The term “Broadcom” refers to Broadcom Inc. and/or its subsidiaries.  All rights reserved.
%%

-module(rabbit_mgmt_wm_auth_SUITE).

-include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").

-compile(export_all).

all() ->
    [
     {group, without_any_settings},
     {group, with_oauth_disabled},
     {group, with_oauth_enabled}
    ].

groups() ->
    [
      {without_any_settings, [], [
        should_return_disabled_auth_settings
      ]},
      {with_oauth_disabled, [], [
        should_return_disabled_auth_settings
      ]},
      {with_oauth_enabled, [], [
        should_return_disabled_auth_settings,
        {with_oauth_providers_idp1_idp2, [], [
          {with_mgt_resource_server_a_with_client_id_x, [], [
            should_return_disabled_auth_settings
          ]},
          {with_resource_server_a_with_oauth_provider_idp1, [], [
            {with_mgt_oauth_client_id_z, [], [
              should_return_oauth_resource_server_a_with_oauth_provider_url_idp1_url,
              should_return_oauth_client_id_z
            ]},
            {with_mgt_resource_server_A_with_client_id_x, [], [
              should_return_oauth_resource_server_a_with_client_id_x
            ]}
          ]},
          {with_root_issuer_url1, [], [
            should_return_disabled_auth_settings,
            {with_resource_server_a, [], [
              should_return_disabled_auth_settings,
              {with_mgt_oauth_client_id_z, [], [
                should_return_oauth_resource_server_a_oauth_provider_url_url0,
                should_return_oauth_client_id_z
              ]},
              {with_mgt_resource_server_A_with_client_id_x, [], [
                should_return_oauth_resource_server_a_oauth_provider_url_url0,
                should_return_oauth_resource_server_A_with_client_id_x
              ]}
            ]}
          ]}
        ]},
        {with_resource_server_id_rabbit, [], [
          should_return_disabled_auth_settings,
          {with_mgt_oauth_client_id_z, [], [
            should_return_disabled_auth_settings,
            {with_mgt_aouth_provider_url_url0, [], [
              should_return_oauth_enabled,
              should_return_oauth_client_id_z,
              should_return_oauth_resource_id_rabbit,
              should_return_sp_initiated_logon,
              oauth_provider_url_should_be_url0,
              should_return_oauth_disable_basic_auth,
              should_not_return_scopes,
              {with_idp_initiated_logon, [], [
                should_return_enabled_auth_settings_idp_initiated_logon
              ]}
            ]},
            {with_root_issuer_Url1, [], [
              should_return_oauth_enabled,
              should_return_oauth_client_id_z,
              should_return_oauth_resource_id_rabbit,
              should_return_sp_initiated_logon,
              should_return_oauth_provider_url_url1
            ]},
            {with_oauth_providers_idp1_idp2, [], [
              should_return_disabled_auth_settings,
              {with_default_oauth_provider_idp3, [], [
                should_return_disabled_auth_settings
              ]},
              {with_default_oauth_provider_idp1, [], [
                should_return_oauth_provider_url_idp1_url
              ]}
            ]}
          ]}
        ]}
      ]}
    ].

%% -------------------------------------------------------------------
%% Setup/teardown.
%% -------------------------------------------------------------------
init_per_suite(Config) ->
  [ {resource_server_id, <<"rabbitmq">>},
    {oauth_client_id, <<"rabbitmq_client">>},
    {oauth_scopes, <<>>},
    {oauth_provider_idp1, <<"idp1">>},
    {resource_A, <<"resource-a">>},
    {rabbit, <<"rabbit">>},
    {idp1, <<"idp1">>},
    {idp2, <<"idp2">>},
    {idp3, <<"idp3">>},
    {idp1_url, <<"idp1_url">>},
    {idp2_url, <<"idp2_url">>},
    {idp3_url, <<"idp3_url">>},
    {url0, <<"https://url0">>},
    {url1, <<"https://url1">>},
    {a, <<"a">>},
    {b, <<"b">>},
    {z, <<"z">>},
    {x, <<"x">>} | Config].

end_per_suite(_Config) ->
    ok.

init_per_group(with_oauth_disabled, Config) ->
  application:set_env(rabbitmq_management, oauth_enabled, false),
  Config;
init_per_group(with_oauth_enabled, Config) ->
  application:set_env(rabbitmq_management, oauth_enabled, true),
  Config;

init_per_group(with_resource_server_id_rabbit, Config) ->
  application:set_env(rabbitmq_auth_backend_oauth2, resource_server_id, ?config(rabbit, Config)),
  Config;
init_per_group(with_mgt_oauth_client_id_z, Config) ->
  ClientId = ?config(z, Config),
  application:set_env(rabbitmq_management, oauth_client_id, ClientId),
  logEnvVars(),
  Config;
init_per_group(with_mgt_aouth_provider_url_url0, Config) ->
  Url = ?config(url90, Config),
  application:set_env(rabbitmq_management, oauth_provider_url, Url),
  Config;
init_per_group(with_root_issuer_url1, Config) ->
  Url = ?config(url1, Config),
  application:set_env(rabbitmq_auth_backend_oauth2, issuer, Url),
  logEnvVars(),
  Config;
init_per_group(with_idp_initiated_logon, Config) ->
  application:set_env(rabbitmq_management, oauth_initiated_logon_type, idp_initiated),
  [ {oauth_initiated_logon_type, idp_initiated} | Config];

init_per_group(with_oauth_providers_idp1_idp2, Config) ->
  Idp1 = ?config(idp1, Config),
  Idp2 = ?config(idp2, Config),
  Idp1Url = ?config(idp1_url, Config),
  Idp2Url = ?config(idp2_url, Config),
  application:set_env(rabbitmq_auth_backend_oauth2, oauth_providers, #{
    Idp1 => [ { issuer, Idp1Url} ],
    Idp2 => [ { issuer, Idp2Url} ]
  }),
  Config;
init_per_group(with_resource_server_a, Config) ->
  ResourceA = ?config(a, Config),
  ResourceServers = application:get_env(rabbitmq_auth_backend_oauth2, resource_servers, #{}),
  ResourceServers1 = maps:put(ResourceA, [ { id, ResourceA} | maps:get(ResourceA, ResourceServers, []) ], ResourceServers),
  application:set_env(rabbitmq_auth_backend_oauth2, resource_servers, ResourceServers1),
  logEnvVars(),
  Config;

init_per_group(with_resource_server_a_with_oauth_provider_idp1, Config) ->
  ResourceA = ?config(a, Config),
  Idp1 = ?config(idp1, Config),
  ResourceServers = application:get_env(rabbitmq_auth_backend_oauth2, resource_servers, #{}),
  ResourceServers1 = maps:put(ResourceA, [ { oauth_provider_id, Idp1} | maps:get(ResourceA, ResourceServers, []) ], ResourceServers),
  application:set_env(rabbitmq_auth_backend_oauth2, resource_servers, ResourceServers1),
  logEnvVars(),
  Config;

init_per_group(with_mgt_resource_server_a_with_client_id_x, Config) ->
  ResourceA = ?config(a, Config),
  ClientId = ?config(x, Config),
  ResourceServers = application:get_env(rabbitmq_management, resource_servers, #{}),
  OAuthResourceA = [ { oauth_client_id, ClientId} | maps:get(ResourceA, ResourceServers, []) ],
  application:set_env(rabbitmq_management, resource_servers,
    maps:put(ResourceA, OAuthResourceA, ResourceServers)),
  logEnvVars(),
  Config;

init_per_group(with_default_oauth_provider_idp1, Config) ->
  Idp = ?config(idp1, Config),
  application:set_env(rabbitmq_auth_backend_oauth2, default_oauth_provider, Idp),
  Config;
init_per_group(with_default_oauth_provider_idp3, Config) ->
  Idp = ?config(idp3, Config),
  application:set_env(rabbitmq_auth_backend_oauth2, default_oauth_provider, Idp),
  Config;
init_per_group(with_unknown_default_oauth_provider, Config) ->
  application:set_env(rabbitmq_auth_backend_oauth2, default_oauth_provider, <<"unknown">>),
  Config;

init_per_group(_, Config) ->
  Config.

end_per_group(with_oauth_disabled, Config) ->
  application:unset_env(rabbitmq_management, oauth_enabled),
  Config;
end_per_group(with_oauth_enabled, Config) ->
  application:unset_env(rabbitmq_management, oauth_enabled),
  Config;
end_per_group(with_resource_server_id_rabbit, Config) ->
  application:unset_env(rabbitmq_auth_backend_oauth2, resource_server_id),
  Config;
end_per_group(with_mgt_aouth_provider_url_url0, Config) ->
  application:unset_env(rabbitmq_management, oauth_provider_url),
  Config;
end_per_group(with_root_issuer_url1, Config) ->
  application:unset_env(rabbitmq_auth_backend_oauth2, issuer),
  Config;
end_per_group(with_mgt_oauth_client_id_z, Config) ->
  application:unset_env(rabbitmq_management, oauth_client_id),
  Config;
end_per_group(with_idp_initiated_logon, Config) ->
  application:unset_env(rabbitmq_management, oauth_initiated_logon_type),
  Config;
end_per_group(with_two_oauth_providers, Config) ->
  application:unset_env(rabbitmq_auth_backend_oauth2, oauth_providers),
  Config;
end_per_group(with_many_resource_servers, Config) ->
  application:unset_env(rabbitmq_auth_backend_oauth2, resource_servers),
  Config;
end_per_group(with_resource_server_a, Config) ->
  ResourceA = ?config(a, Config),
  ResourceServers = application:get_env(rabbitmq_auth_backend_oauth2, resource_servers, #{}),
  NewMap = maps:remove(ResourceA, ResourceServers),
  case maps:size(NewMap) of
    0 -> application:unset_env(rabbitmq_auth_backend_oauth2, resource_servers);
    _ -> application:set_env(rabbitmq_auth_backend_oauth2, resource_servers, NewMap)
  end,
  Config;
end_per_group(with_resource_server_a_with_oauth_provider_idp1, Config) ->
  ResourceA = ?config(a, Config),
  ResourceServers = application:get_env(rabbitmq_auth_backend_oauth2, resource_servers, #{}),
  OAuthResourceA = proplists:delete(oauth_provider_id, maps:get(ResourceA, ResourceServers, [])),
  NewMap = delete_key_with_empty_proplist(ResourceA, maps:put(ResourceA, OAuthResourceA, ResourceServers)),
  case maps:size(NewMap) of
    0 -> application:unset_env(rabbitmq_auth_backend_oauth2, resource_servers);
    _ -> application:set_env(rabbitmq_auth_backend_oauth2, resource_servers, NewMap)
  end,
  Config;

end_per_group(with_mgt_resource_server_a_with_client_id_x, Config) ->
  ResourceA = ?config(a, Config),
  ResourceServers = application:get_env(rabbitmq_management, resource_servers, #{}),
  OAuthResourceA = proplists:delete(oauth_client_id, maps:get(ResourceA, ResourceServers, [])),
  NewMap = delete_key_with_empty_proplist(ResourceA, maps:put(ResourceA, OAuthResourceA, ResourceServers)),
  case maps:size(NewMap) of
    0 -> application:unset_env(rabbitmq_management, resource_servers);
    _ -> application:set_env(rabbitmq_management, resource_servers, NewMap)
  end,
  Config;
end_per_group(with_default_oauth_provider_idp1, Config) ->
  application:unset_env(rabbitmq_auth_backend_oauth2, default_oauth_provider),
  Config;
end_per_group(with_default_oauth_provider_idp3, Config) ->
  application:unset_env(rabbitmq_auth_backend_oauth2, default_oauth_provider),
  Config;

end_per_group(_, Config) ->
  Config.


delete_key_with_empty_proplist(Key, Map) ->
  case maps:get(Key, Map) of
    [] -> maps:remove(Key, Map)
  end.

%% -------------------------------------------------------------------
%% Test cases.
%% -------------------------------------------------------------------

should_return_oauth_provider_url_idp1_url(Config) ->
  Actual = rabbit_mgmt_wm_auth:authSettings(),
  ?assertEqual(?config(idp1_url, Config), proplists:get_value(oauth_provider_url, Actual)).

should_return_disabled_auth_settings(_Config) ->
  [{oauth_enabled, false}] = rabbit_mgmt_wm_auth:authSettings().

should_return_oauth_resource_server_A_with_client_id(Config) ->
  ResourceA = ?config(resource_A, Config),
  Actual = rabbit_mgmt_wm_auth:authSettings(),
  ResourceServers = proplists:get_value(oauth_resource_servers, Actual),
  ResourceServerA = maps:get(ResourceA, ResourceServers),

  {ok, ConfiguredResourceServers} = application:get_env(rabbitmq_management, resource_servers),
  Expected = proplists:get_value(oauth_client_id, maps:get(ResourceA, ConfiguredResourceServers)),
  ?assertEqual(Expected, proplists:get_value(oauth_client_id, ResourceServerA)).

should_return_mgt_resource_server_a_oauth_provider_url_url0(Config) ->
  Actual = rabbit_mgmt_wm_auth:authSettings(),
  ResourceServers = proplists:get_value(oauth_resource_servers, Actual),
  ResourceServer = maps:get(?config(a, Config), ResourceServers),
  ?assertEqual(?config(url0), proplists:get_value(oauth_provider_url, ResourceServer)).

should_return_oauth_resource_server_a_with_client_id_x(Config) ->
  Actual = rabbit_mgmt_wm_auth:authSettings(),
  OAuthResourceServers =  proplists:get_value(oauth_resource_servers, Actual),
  OauthResource = maps:get(?config(a, Config), OAuthResourceServers),
  ?assertEqual(?config(x, Config), proplists:get_value(oauth_client_id, OauthResource)).

should_return_oauth_resource_server_a_with_oauth_provider_url_idp1_url(Config) ->
  Actual = rabbit_mgmt_wm_auth:authSettings(),
  OAuthResourceServers =  proplists:get_value(oauth_resource_servers, Actual),
  OauthResource = maps:get(?config(a, Config), OAuthResourceServers),
  ?assertEqual(?config(idp1_url, Config), proplists:get_value(oauth_provider_url, OauthResource)).

should_return_empty_scopes(_Config) ->
  Actual = rabbit_mgmt_wm_auth:authSettings(),
  ?assertEqual(false, proplists:is_defined(scopes, Actual)).

should_return_oauth_enabled(_Config) ->
  Actual = rabbit_mgmt_wm_auth:authSettings(),
  ?assertEqual(true, proplists:get_value(oauth_enabled, Actual)).

should_return_enabled_auth_settings_sp_initiated_logon(_Config) ->
  Actual = rabbit_mgmt_wm_auth:authSettings(),
  ?assertEqual(false, proplists:is_defined(oauth_initiated_logon_type, Actual)).

should_return_enabled_auth_settings_idp_initiated_logon(Config) ->
  ResourceId = ?config(resource_server_id, Config),
  Actual = rabbit_mgmt_wm_auth:authSettings(),
  ?assertNot(proplists:is_defined(oauth_client_id, Actual)),
  ?assertNot(proplists:is_defined(scopes, Actual)),
  ?assertNot(proplists:is_defined(oauth_metadata_url, Actual)),
  ?assertEqual(ResourceId, proplists:get_value(oauth_resource_id, Actual)),
  ?assertEqual( <<"idp_initiated">>, proplists:get_value(oauth_initiated_logon_type, Actual)).

should_return_root_issuer_as_oauth_provider_url(_Config) ->
  Actual = rabbit_mgmt_wm_auth:authSettings(),
  log(Actual),
  Issuer = application:get_env(rabbitmq_auth_backend_oauth2, issuer, ""),
  ?assertEqual(Issuer, proplists:get_value(oauth_provider_url, Actual)).

should_return_oauth_disable_basic_auth(_Config) ->
  Actual = rabbit_mgmt_wm_auth:authSettings(),
  ?assertEqual(true, proplists:get_value(oauth_disable_basic_auth, Actual)).

should_return_oauth_enabled_basic_auth(_Config) ->
  Actual = rabbit_mgmt_wm_auth:authSettings(),
  ?assertEqual(false, proplists:get_value(oauth_disable_basic_auth, Actual)).

should_return_oauth_client_id_z(Config) ->
  Actual = rabbit_mgmt_wm_auth:authSettings(),
  ?assertEqual(?config(z, Config), proplists:get_value(oauth_client_id, Actual)).

should_return_mgt_oauth_client_id(_Config) ->
  Actual = rabbit_mgmt_wm_auth:authSettings(),
  {ok, Expected} = application:get_env(rabbitmq_management, oauth_client_id),
  ?assertEqual(Expected, proplists:get_value(oauth_client_id, Actual)).

should_return_configured_oauth_provider_url(_Config) ->
  Actual = rabbit_mgmt_wm_auth:authSettings(),
  Issuer = application:get_env(rabbitmq_management, oauth_provider_url, ""),
  ?assertEqual(Issuer, proplists:get_value(oauth_provider_url, Actual)).

should_return_oauth_provider_issuer_as_oauth_provider_url(_Config) ->
  Actual = rabbit_mgmt_wm_auth:authSettings(),
  {ok, DefaultOAuthProvider} = application:get_env(rabbitmq_auth_backend_oauth2, default_oauth_provider),
  OauthProvider = maps:get(DefaultOAuthProvider,
    application:get_env(rabbitmq_auth_backend_oauth2, oauth_providers, #{})),
  ?assertEqual(proplists:get_value(issuer, OauthProvider), proplists:get_value(oauth_provider_url, Actual)).

log(AuthSettings) ->
  logEnvVars(),
  ct:log("authSettings: ~p ", [AuthSettings]).
logEnvVars() ->
  ct:log("rabbitmq_management: ~p ", [application:get_all_env(rabbitmq_management)]),
  ct:log("rabbitmq_auth_backend_oauth2: ~p ", [application:get_all_env(rabbitmq_auth_backend_oauth2)]).


should_return_oauth_resource_server_A(Config) ->
  ClientId = ?config(oauth_client_id, Config),
  ResourceA = ?config(resource_A, Config),
  Actual = rabbit_mgmt_wm_auth:authSettings(),
  log(Actual),

  OAuthResourceServers = proplists:get_value(oauth_resource_servers, Actual),
  OAuthResourceA = maps:get(ResourceA, OAuthResourceServers),

  ?assertEqual(true, proplists:get_value(oauth_enabled, Actual)),
  ?assertEqual(ClientId, proplists:get_value(oauth_client_id, OAuthResourceA)).
