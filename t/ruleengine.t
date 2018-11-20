
use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(2);

plan tests => repeat_each() * (3 * blocks());

$ENV{TEST_NGINX_CWD} = cwd();

no_long_string();

run_tests();

__DATA__

=== TEST 1: simple unit test one
--- http_config
    lua_need_request_body on;
    lua_package_path "$TEST_NGINX_CWD/lib/?.lua;$TEST_NGINX_CWD/t/lualib/?.lua;";
--- config
    location = /t {
        content_by_lua_block {
            local yaml = require "resty.yaml"
            local taurus = require "resty.taurus"
            local fact = require "resty.taurus.context.fact"
            local decision = require "resty.taurus.context.decision"
            local text = io.open("$TEST_NGINX_CWD/t/rule/000-engine-rule.yaml"):read("*a")
            local r = yaml.parse(text) or {}
            local rule_engine = taurus.compile(r)

            local decide = decision.new()
            rule_engine:match(fact.new(
                ngx.req.get_headers(),
                ngx.req.get_uri_args(),
                ngx.req.get_post_args(),
                {}
            ), decide)
            ngx.say(decide.rulename)
            ngx.say(decide.upstream)
        }
    }
--- request
POST /t?param=demo
partner1=demo2
--- response_body
rulename
proxy
--- error_code: 200
--- no_error_log
[warn]
