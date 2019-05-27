
use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(1);

plan tests => repeat_each() * (3 * blocks() + 3);

$ENV{TEST_NGINX_CWD} = cwd();

no_long_string();

our $HttpConfig = <<'_EOC_';
    lua_need_request_body on;
    lua_package_path "$TEST_NGINX_CWD/lib/?.lua;$TEST_NGINX_CWD/t/lualib/?.lua;";
    lua_shared_dict counter    1m;

    init_by_lua_block {
        require "resty.core"
        local yaml = require "resty.yaml"
        local taurus = require "resty.taurus"
        local text = io.open("$TEST_NGINX_CWD/t/rule/011-count-rule.yaml"):read("*a")
        local r = yaml.parse(text) or {}
        _G.rule_engine = taurus.compile(r)
    }
_EOC_

run_tests();

__DATA__

=== TEST 1: count rule match
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
            ngx.log(ngx.ERR, decide.rulename)
            ngx.say(decide.rulename or "")
            ngx.say(decide.upstream or "")
        }
    }
--- pipelined_requests eval
["GET /t?param=demo", "GET /t?param=demo"]
--- response_body eval
["rulename2\nproxy2\n",
"rulename\nproxy\n"]
--- error_code eval
[200,200]
--- no_error_log
[warn]
