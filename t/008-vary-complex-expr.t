
use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(2);

plan tests => repeat_each() * (3 * blocks());

$ENV{TEST_NGINX_CWD} = cwd();

no_long_string();

our $HttpConfig = <<'_EOC_';
    lua_need_request_body on;
    lua_load_resty_core off;
    lua_package_path "$TEST_NGINX_CWD/lib/?.lua;$TEST_NGINX_CWD/t/lualib/?.lua;";

    init_by_lua_block {
        local yaml = require "resty.yaml"
        local taurus = require "resty.taurus"
        local text = io.open("$TEST_NGINX_CWD/t/rule/008-vary-complex-expr.yaml"):read("*a")
        local r = yaml.parse(text) or {}
        _G.rule_engine = taurus.compile(r)
    }
_EOC_

run_tests();

__DATA__

=== TEST 1: expr match param=150 && param2=demo
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
            local fact = require "resty.taurus.context.fact"
            local decision = require "resty.taurus.context.decision"
            local decide = decision.new()
            _G.rule_engine:match(fact.new(
                ngx.req.get_headers(),
                ngx.req.get_uri_args(),
                ngx.req.get_post_args(),
                {}
            ), decide)
            ngx.say(decide.rulename or "")
            ngx.say(decide.upstream or "")
        }
    }
--- request
GET /t?param=150&param2=demo
--- response_body
rulename
proxy
--- error_code: 200
--- no_error_log
[warn]



=== TEST 2: expr match param=150 && param2=demo2222
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
            local fact = require "resty.taurus.context.fact"
            local decision = require "resty.taurus.context.decision"
            local decide = decision.new()
            _G.rule_engine:match(fact.new(
                ngx.req.get_headers(),
                ngx.req.get_uri_args(),
                ngx.req.get_post_args(),
                {}
            ), decide)
            ngx.say(decide.rulename or "")
            ngx.say(decide.upstream or "")
        }
    }
--- request
GET /t?param=150&param2=demo2222
--- response_body
rulename
proxy
--- error_code: 200
--- no_error_log
[warn]



=== TEST 3: expr match param=150 && param2=dem3o
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
            local fact = require "resty.taurus.context.fact"
            local decision = require "resty.taurus.context.decision"
            local decide = decision.new()
            _G.rule_engine:match(fact.new(
                ngx.req.get_headers(),
                ngx.req.get_uri_args(),
                ngx.req.get_post_args(),
                {}
            ), decide)
            ngx.say(decide.rulename or "")
            ngx.say(decide.upstream or "")
        }
    }
--- request
GET /t?param=150&param2=dem3o
--- response_body
rulename
proxy
--- error_code: 200
--- no_error_log
[warn]



=== TEST 4: expr not match param=150 && param2=dem1o
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
            local fact = require "resty.taurus.context.fact"
            local decision = require "resty.taurus.context.decision"
            local decide = decision.new()
            _G.rule_engine:match(fact.new(
                ngx.req.get_headers(),
                ngx.req.get_uri_args(),
                ngx.req.get_post_args(),
                {}
            ), decide)
            ngx.say(decide.rulename or "")
            ngx.say(decide.upstream or "")
        }
    }
--- request
GET /t?param=150&param2=dem1o
--- response_body
rulename2
proxy2
--- error_code: 200
--- no_error_log
[warn]



=== TEST 5: expr not match param=150
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua_block {
            local fact = require "resty.taurus.context.fact"
            local decision = require "resty.taurus.context.decision"
            local decide = decision.new()
            _G.rule_engine:match(fact.new(
                ngx.req.get_headers(),
                ngx.req.get_uri_args(),
                ngx.req.get_post_args(),
                {}
            ), decide)
            ngx.say(decide.rulename or "")
            ngx.say(decide.upstream or "")
        }
    }
--- request
GET /t?param=150
--- response_body
rulename2
proxy2
--- error_code: 200
--- no_error_log
[warn]