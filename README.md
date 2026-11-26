# lua-resty-taurus

A simple rule engine for OpenResty / LuaJIT.

[![Travis](https://travis-ci.org/toruneko/lua-resty-taurus.svg?branch=master)](https://travis-ci.org/toruneko/lua-resty-taurus)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**Status:** production ready.

## Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Synopsis](#synopsis)
- [API](#api)
- [Fact](#fact)
- [Decision](#decision)
- [Rule definition](#rule-definition)
- [Conditions](#conditions)
- [Actions](#actions)
- [Evaluation order](#evaluation-order)
- [Testing](#testing)
- [License](#license)

## Features

- Declarative JSON/YAML rules, no Lua code required to describe logic.
- Ordered first-match evaluation with logical `and` / `or` / `not` expressions.
- Request-aware fact lookup for headers, query string, body and custom context.
- Built-in actions for upstream selection (`proxy`, `crc32`) and request rejection (`refuse`).

## Requirements

- An nginx build with [ngx_lua](https://github.com/openresty/lua-nginx-module), i.e. OpenResty.
- [LuaJIT 2.0](http://luajit.org/luajit.html) or newer.
- [lua-resty-core](https://github.com/openresty/lua-resty-core).
- [lua-resty-limit-traffic](https://github.com/openresty/lua-resty-limit-traffic) — only required when using the `count` condition.

## Installation

Place the `lib/resty/taurus` directory inside your `lua_package_path`:

```nginx
lua_package_path "/path/to/lua-resty-taurus/lib/?.lua;;";
```

Then load the library:

```lua
local taurus = require "resty.taurus"
```

When using the `count` condition, declare the shared dictionary referenced by the rule (e.g. `dict_name: counter`):

```nginx
http {
    lua_shared_dict counter 10m;
}
```

## Synopsis

```nginx
# nginx.conf
lua_package_path "/path/to/lua-resty-taurus/lib/?.lua;;";

server {
    location = /t {
        content_by_lua_block {
            local r = {
                rules = {
                    {
                        name = "rulename",
                        when = {
                            equals = {
                                ["request.query.param"] = "demo"
                            }
                        },
                        ["do"] = {
                            proxy = "backend_a"
                        }
                    }
                }
            }

            local taurus = require "resty.taurus"
            local rule_engine = taurus.compile(r)

            local fact = require "resty.taurus.context.fact"
            local decision = require "resty.taurus.context.decision"

            local decide = decision.new()
            local matched = rule_engine:match(fact.new(
                ngx.req.get_headers(),
                ngx.req.get_uri_args(),
                ngx.req.get_post_args(),
                {}
            ), decide)

            ngx.say(matched)
            ngx.say(decide.rulename or "")
            ngx.say(decide.upstream or "")
        }
    }
}
```

## API

### compile

`syntax: rule_engine = taurus.compile(r)`

Compiles a rule description table `r` (with a mandatory `rules` array) into a reusable rule engine object. Configuration is validated at compile time; invalid or unknown conditions raise a Lua error.

```lua
local taurus = require "resty.taurus"
local rule_engine = taurus.compile(r)
```

The engine is immutable after compilation, so it can safely be built once (e.g. in `init_by_lua_block`) and shared by all workers.

### match

`syntax: matched = rule_engine:match(fact, decide)`

Evaluates the rules in order against `fact` and writes the outcome of the first matching rule into `decide`. Returns `true` when a rule matched, `false` otherwise.

```lua
local fact = require "resty.taurus.context.fact"
local decision = require "resty.taurus.context.decision"

local decide = decision.new()
local matched = rule_engine:match(fact.new(
    ngx.req.get_headers(),
    ngx.req.get_uri_args(),
    ngx.req.get_post_args(),
    {}
), decide)

ngx.say(decide.rulename or "")
ngx.say(decide.upstream or "")
```

## Fact

`fact.new(header, query, body, ctx)` wraps the request data that conditions read from. Conditions address a value with a dotted key:

| Key pattern | Source |
| --- | --- |
| `request.header.<name>` | request header |
| `request.query.<name>` | URI query argument |
| `request.body.<name>` | POST body argument |
| `context.<name>` | custom scalar value from `ctx` |
| `context.<group>.<name>` | custom value from `ctx[group][name]` |

Missing values resolve to `nil`, and every condition treats a missing value as "not matched".

## Decision

`decision.new()` creates a result object populated by the matched rule's action:

| Field | Description |
| --- | --- |
| `rulename` | Name of the matched rule. |
| `upstream` | Upstream selected by `proxy` or `crc32`. |
| `ctx` | Scratch table available to actions. |

## Rule definition

```yaml
rules:
  - name: [rulename]
    when:
      [condition or logical expression]
    do:
      [action]
```

- `name` — identifier copied to `decision.rulename`.
- `when` — a single condition or a logical expression; leaving it empty makes the rule match every request (catch-all).
- `do` — exactly one action.

### Logical expressions

`and` / `or` accept a list of conditions (or nested expressions). `not` negates a single condition.

```yaml
# and: all conditions must match
when:
  and:
    - range:
        request.query.param:
          gt: 100
          lte: 200
    - has_fields: ["request.query.param2"]

# or: at least one condition must match
when:
  or:
    - contains:
        request.query.param: demo
    - has_fields: ["request.query.param2"]

# not: the condition must not match
when:
  not:
    in_array:
      request.query.param: ["demo1", "demo2"]
```

Expressions can be nested arbitrarily:

```yaml
when:
  and:
    - range:
        request.query.param:
          gt: 100
          lte: 200
    - or:
        - contains:
            request.query.param2: demo
        - not:
            in_array:
              request.query.param2: ["demo1", "demo2"]
```

## Conditions

| Condition | Matches when the fact value... |
| --- | --- |
| [`equals`](#equals) | equals the expected value |
| [`contains`](#contains) | contains the expected regex pattern |
| [`startwith`](#startwith) | starts with the expected regex pattern |
| [`endwith`](#endwith) | ends with the expected regex pattern |
| [`in_array`](#in_array) | is a member of the expected set |
| [`has_fields`](#has_fields) | — all listed keys exist in the fact |
| [`range`](#range) | falls within the numeric bounds |
| [`count`](#count) | exceeds the allowed rate within a time window |

### equals

Compares the fact value with the expected value. Numeric expectations compare numerically; otherwise both sides are compared as strings.

```yaml
equals:
  request.query.param: demo
```

### contains

Checks whether the fact value contains a match for the expected [Lua regex](https://github.com/openresty/lua-nginx-module#ngxrematch) pattern.

```yaml
contains:
  request.query.param: demo
```

### startwith

Checks whether the fact value begins with the expected regex pattern.

```yaml
startwith:
  request.query.param: demo
```

### endwith

Checks whether the fact value ends with the expected regex pattern.

```yaml
endwith:
  request.query.param: demo
```

### in_array

Checks whether the fact value is one of the expected values. If the expectation is not a list, it is treated as a fact key pointing to a list.

```yaml
in_array:
  request.query.param:
    - demo1
    - demo2
```

```yaml
# read the candidate list from another fact key
in_array:
  request.query.param: context.allowed_methods
```

### has_fields

Checks that every listed fact key exists.

```yaml
has_fields:
  - request.query.param
  - request.query.param2
```

### range

Checks numeric bounds. All supplied bounds must hold; each of `gt`, `gte`, `lt`, `lte` is optional.

```yaml
range:
  request.query.param:
    gt: 100
    lte: 200
```

### count

Rate-limits the fact value with [lua-resty-limit-traffic](https://github.com/openresty/lua-resty-limit-traffic): the condition matches once the value has been seen more than `total` times within `window` second(s).

```yaml
count:
  request.query.param:
    dict_name: counter
    total: 1
    window: 1
```

> Requires a `lua_shared_dict` named `dict_name` in `nginx.conf`.

## Actions

### proxy

Sets `decision.upstream` to a fixed upstream name:

```yaml
do:
  proxy: backend_a
```

Or to the value of a fact key:

```yaml
do:
  proxy:
    key: request.query.host
```

### crc32

Consistently maps a fact value onto one of the `selector` entries via CRC32, which is useful for sticky load balancing:

```yaml
do:
  crc32:
    hash: request.query.user_id
    selector:
      - backend_a
      - backend_b
      - backend_c
```

### refuse

Immediately rejects the request with the given status code through `ngx.exit`:

```yaml
do:
  refuse: 403
```

## Evaluation order

Rules are evaluated top to bottom and the first match wins; remaining rules are skipped. Put specific rules before broad or catch-all rules:

```yaml
rules:
  - name: block
    when:
      equals:
        request.query.param: bad
    do:
      refuse: 403
  - name: default
    when:
    do:
      proxy: backend_a
```

## Testing

The test suite uses [Test::Nginx](https://github.com/openresty/test-nginx):

```bash
make test
```

`make test` expects OpenResty at `/usr/local/openresty-debug`. Override it with `OPENRESTY_PREFIX`:

```bash
make test OPENRESTY_PREFIX=/usr/local/openresty
```

## See Also

- [lua-nginx-module](https://github.com/openresty/lua-nginx-module)
- [lua-resty-limit-traffic](https://github.com/openresty/lua-resty-limit-traffic)
- [Filebeat processors](https://www.elastic.co/guide/en/beats/filebeat/current/defining-processors.html) — inspiration for the condition syntax.

## Author

Jianhao Dai (toruneko) <toruneko@outlook.com>

## License

This module is licensed under the MIT license.

Copyright (C) 2018, by Jianhao Dai (toruneko) <toruneko@outlook.com>

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
