local reader = require("reader")
local function getenv(k, p)
  if string63(k) then
    local b = find(function (e)
      return(e[k])
    end, reverse(environment))
    if is63(b) then
      if p then
        return(b[p])
      else
        return(b)
      end
    end
  end
end
local function macro_function(k)
  return(getenv(k, "macro"))
end
local function macro63(k)
  return(is63(macro_function(k)))
end
local function special63(k)
  return(is63(getenv(k, "special")))
end
local function special_form63(form)
  return(obj63(form) and special63(hd(form)))
end
local function statement63(k)
  return(special63(k) and getenv(k, "stmt"))
end
local function symbol_expansion(k)
  return(getenv(k, "symbol"))
end
local function symbol63(k)
  return(is63(symbol_expansion(k)))
end
local function variable63(k)
  local b = first(function (frame)
    return(frame[k] or frame._scope)
  end, reverse(environment))
  return(obj63(b) and is63(b.variable))
end
function bound63(x)
  return(macro63(x) or special63(x) or symbol63(x) or variable63(x))
end
function quoted(form)
  if string63(form) then
    return(escape(form))
  else
    if atom63(form) then
      return(form)
    else
      return(join({"list"}, map(quoted, form)))
    end
  end
end
local function literal(s)
  if string_literal63(s) then
    return(s)
  else
    return(quoted(s))
  end
end
local function stash42(args)
  if keys63(args) then
    local l = {"%object", "\"_stash\"", true}
    local _u21 = args
    local k = nil
    for k in next, _u21 do
      local v = _u21[k]
      if not number63(k) then
        add(l, literal(k))
        add(l, v)
      end
    end
    return(join(args, {l}))
  else
    return(args)
  end
end
local function bias(k)
  if number63(k) and not (target == "lua") then
    if target == "js" then
      k = k - 1
    else
      k = k + 1
    end
  end
  return(k)
end
function bind(lh, rh)
  if obj63(lh) and obj63(rh) then
    local id = unique()
    return(join({{id, rh}}, bind(lh, id)))
  else
    if atom63(lh) then
      return({{lh, rh}})
    else
      local bs = {}
      local _u30 = lh
      local k = nil
      for k in next, _u30 do
        local v = _u30[k]
        local _u327
        if k == "rest" then
          _u327 = {"cut", rh, _35(lh)}
        else
          _u327 = {"get", rh, {"quote", bias(k)}}
        end
        local x = _u327
        if is63(k) then
          local _u328
          if v == true then
            _u328 = k
          else
            _u328 = v
          end
          local _u35 = _u328
          bs = join(bs, bind(_u35, x))
        end
      end
      return(bs)
    end
  end
end
function bind42(args, body)
  local args1 = {}
  local function rest()
    if target == "js" then
      return({"unstash", {{"get", {"get", {"get", "Array", {"quote", "prototype"}}, {"quote", "slice"}}, {"quote", "call"}}, "arguments", _35(args1)}})
    else
      add(args1, "|...|")
      return({"unstash", {"list", "|...|"}})
    end
  end
  if atom63(args) then
    return({args1, join({"let", {args, rest()}}, body)})
  else
    local bs = {}
    local r = unique()
    local _u51 = args
    local k = nil
    for k in next, _u51 do
      local v = _u51[k]
      if number63(k) then
        if atom63(v) then
          add(args1, v)
        else
          local x = unique()
          add(args1, x)
          bs = join(bs, {v, x})
        end
      end
    end
    if keys63(args) then
      bs = join(bs, {r, rest()})
      bs = join(bs, {keys(args), r})
    end
    return({args1, join({"let", bs}, body)})
  end
end
local function quoting63(depth)
  return(number63(depth))
end
local function quasiquoting63(depth)
  return(quoting63(depth) and depth > 0)
end
local function can_unquote63(depth)
  return(quoting63(depth) and depth == 1)
end
local function quasisplice63(x, depth)
  return(can_unquote63(depth) and obj63(x) and hd(x) == "unquote-splicing")
end
function macroexpand(form)
  if symbol63(form) then
    return(macroexpand(symbol_expansion(form)))
  else
    if atom63(form) then
      return(form)
    else
      local x = hd(form)
      if x == "%local" then
        local _u1 = form[1]
        local name = form[2]
        local value = form[3]
        return({"%local", name, macroexpand(value)})
      else
        if x == "%function" then
          local _u2 = form[1]
          local args = form[2]
          local body = cut(form, 2)
          add(environment, {_scope = true})
          local _u66 = args
          local _u1 = nil
          for _u1 in next, _u66 do
            local _u64 = _u66[_u1]
            setenv(_u64, {_stash = true, variable = true})
          end
          local _u65 = join({"%function", args}, macroexpand(body))
          drop(environment)
          return(_u65)
        else
          if x == "%local-function" or x == "%global-function" then
            local _u3 = form[1]
            local _u69 = form[2]
            local _u70 = form[3]
            local _u71 = cut(form, 3)
            add(environment, {_scope = true})
            local _u74 = _u70
            local _u1 = nil
            for _u1 in next, _u74 do
              local _u72 = _u74[_u1]
              setenv(_u72, {_stash = true, variable = true})
            end
            local _u73 = join({x, _u69, _u70}, macroexpand(_u71))
            drop(environment)
            return(_u73)
          else
            if macro63(x) then
              return(macroexpand(apply(macro_function(x), tl(form))))
            else
              return(map(macroexpand, form))
            end
          end
        end
      end
    end
  end
end
local function quasiquote_list(form, depth)
  local xs = {{"list"}}
  local _u80 = form
  local k = nil
  for k in next, _u80 do
    local v = _u80[k]
    if not number63(k) then
      local _u329
      if quasisplice63(v, depth) then
        _u329 = quasiexpand(v[2])
      else
        _u329 = quasiexpand(v, depth)
      end
      local _u82 = _u329
      last(xs)[k] = _u82
    end
  end
  local _u83 = form
  local _u84 = _35(_u83)
  local _u85 = 0
  while _u85 < _u84 do
    local x = _u83[_u85 + 1]
    if quasisplice63(x, depth) then
      local _u86 = quasiexpand(x[2])
      add(xs, _u86)
      add(xs, {"list"})
    else
      add(last(xs), quasiexpand(x, depth))
    end
    _u85 = _u85 + 1
  end
  local pruned = keep(function (x)
    return(_35(x) > 1 or not (hd(x) == "list") or keys63(x))
  end, xs)
  return(join({"join*"}, pruned))
end
function quasiexpand(form, depth)
  if quasiquoting63(depth) then
    if atom63(form) then
      return({"quote", form})
    else
      if can_unquote63(depth) and hd(form) == "unquote" then
        return(quasiexpand(form[2]))
      else
        if hd(form) == "unquote" or hd(form) == "unquote-splicing" then
          return(quasiquote_list(form, depth - 1))
        else
          if hd(form) == "quasiquote" then
            return(quasiquote_list(form, depth + 1))
          else
            return(quasiquote_list(form, depth))
          end
        end
      end
    end
  else
    if atom63(form) then
      return(form)
    else
      if hd(form) == "quote" then
        return(form)
      else
        if hd(form) == "quasiquote" then
          return(quasiexpand(form[2], 1))
        else
          return(map(function (x)
            return(quasiexpand(x, depth))
          end, form))
        end
      end
    end
  end
end
function expand_if(_u94)
  local a = _u94[1]
  local b = _u94[2]
  local c = cut(_u94, 2)
  if is63(b) then
    return({join({"%if", a, b}, expand_if(c))})
  else
    if is63(a) then
      return({a})
    end
  end
end
indent_level = 0
function indentation()
  return(apply(cat, replicate(indent_level, "  ")))
end
local reserved = {["="] = true, ["=="] = true, ["+"] = true, ["-"] = true, ["%"] = true, ["*"] = true, ["/"] = true, ["<"] = true, [">"] = true, ["<="] = true, [">="] = true, ["break"] = true, ["case"] = true, ["catch"] = true, ["continue"] = true, ["debugger"] = true, ["default"] = true, ["delete"] = true, ["do"] = true, ["else"] = true, ["finally"] = true, ["for"] = true, ["function"] = true, ["if"] = true, ["in"] = true, ["instanceof"] = true, ["new"] = true, ["return"] = true, ["switch"] = true, ["this"] = true, ["throw"] = true, ["try"] = true, ["typeof"] = true, ["var"] = true, ["void"] = true, ["with"] = true, ["and"] = true, ["end"] = true, ["repeat"] = true, ["while"] = true, ["false"] = true, ["local"] = true, ["nil"] = true, ["then"] = true, ["not"] = true, ["true"] = true, ["elseif"] = true, ["or"] = true, ["until"] = true}
function reserved63(x)
  return(reserved[x])
end
local function valid_code63(n)
  return(number_code63(n) or n > 64 and n < 91 or n > 96 and n < 123 or n == 95)
end
function valid_id63(id)
  if none63(id) or reserved63(id) then
    return(false)
  else
    local i = 0
    while i < _35(id) do
      if not valid_code63(code(id, i)) then
        return(false)
      end
      i = i + 1
    end
    return(true)
  end
end
function key(k)
  local i = inner(k)
  if valid_id63(i) then
    return(i)
  else
    if target == "js" then
      return(k)
    else
      return("[" .. k .. "]")
    end
  end
end
function mapo(f, t)
  local o = {}
  local _u104 = t
  local k = nil
  for k in next, _u104 do
    local v = _u104[k]
    local x = f(v)
    if is63(x) then
      add(o, literal(k))
      add(o, x)
    end
  end
  return(o)
end
local _u107 = {}
local _u108 = {}
_u108.js = "!"
_u108.lua = "not "
_u107["not"] = _u108
local _u109 = {}
_u109["*"] = true
_u109["/"] = true
_u109["%"] = true
local _u110 = {}
_u110["+"] = true
_u110["-"] = true
local _u111 = {}
local _u112 = {}
_u112.js = "+"
_u112.lua = ".."
_u111.cat = _u112
local _u113 = {}
_u113["<"] = true
_u113[">"] = true
_u113["<="] = true
_u113[">="] = true
local _u114 = {}
local _u115 = {}
_u115.js = "==="
_u115.lua = "=="
_u114["="] = _u115
local _u116 = {}
local _u117 = {}
_u117.js = "&&"
_u117.lua = "and"
_u116["and"] = _u117
local _u118 = {}
local _u119 = {}
_u119.js = "||"
_u119.lua = "or"
_u118["or"] = _u119
local infix = {_u107, _u109, _u110, _u111, _u113, _u114, _u116, _u118}
local function unary63(form)
  return(_35(form) == 2 and in63(hd(form), {"not", "-"}))
end
local function index(k)
  if number63(k) then
    return(k - 1)
  end
end
local function precedence(form)
  if not (atom63(form) or unary63(form)) then
    local _u124 = infix
    local k = nil
    for k in next, _u124 do
      local v = _u124[k]
      if v[hd(form)] then
        return(index(k))
      end
    end
  end
  return(0)
end
local function getop(op)
  return(find(function (level)
    local x = level[op]
    if x == true then
      return(op)
    else
      if is63(x) then
        return(x[target])
      end
    end
  end, infix))
end
local function infix63(x)
  return(is63(getop(x)))
end
local function compile_args(args)
  local s = "("
  local c = ""
  local _u130 = args
  local _u131 = _35(_u130)
  local _u132 = 0
  while _u132 < _u131 do
    local x = _u130[_u132 + 1]
    s = s .. c .. compile(x)
    c = ", "
    _u132 = _u132 + 1
  end
  return(s .. ")")
end
local function escape_newlines(s)
  local s1 = ""
  local i = 0
  while i < _35(s) do
    local c = char(s, i)
    local _u330
    if c == "\n" then
      _u330 = "\\n"
    else
      _u330 = c
    end
    s1 = s1 .. _u330
    i = i + 1
  end
  return(s1 .. "")
end
local function id(id)
  local id1 = ""
  local i = 0
  while i < _35(id) do
    local c = char(id, i)
    local n = code(c)
    local _u331
    if c == "-" then
      _u331 = "_"
    else
      local _u332
      if valid_code63(n) then
        _u332 = c
      else
        local _u333
        if i == 0 then
          _u333 = "_" .. n
        else
          _u333 = n
        end
        _u332 = _u333
      end
      _u331 = _u332
    end
    local c1 = _u331
    id1 = id1 .. c1
    i = i + 1
  end
  return(id1)
end
local function compile_atom(x)
  if x == "nil" and target == "lua" then
    return(x)
  else
    if x == "nil" then
      return("undefined")
    else
      if id_literal63(x) then
        return(inner(x))
      else
        if string_literal63(x) then
          return(escape_newlines(x))
        else
          if string63(x) then
            return(id(x))
          else
            if boolean63(x) then
              if x then
                return("true")
              else
                return("false")
              end
            else
              if number63(x) then
                return(x .. "")
              else
                error("Cannot compile atom: " .. string(x))
              end
            end
          end
        end
      end
    end
  end
end
local function terminator(stmt63)
  if not stmt63 then
    return("")
  else
    if target == "js" then
      return(";\n")
    else
      return("\n")
    end
  end
end
local function compile_special(form, stmt63)
  local x = form[1]
  local args = cut(form, 1)
  local _u138 = getenv(x)
  local special = _u138.special
  local stmt = _u138.stmt
  local self_tr63 = _u138.tr
  local tr = terminator(stmt63 and not self_tr63)
  return(apply(special, args) .. tr)
end
local function parenthesize_call63(x)
  return(obj63(x) and hd(x) == "%function" or precedence(x) > 0)
end
local function compile_call(form)
  local f = hd(form)
  local f1 = compile(f)
  local args = compile_args(stash42(tl(form)))
  if parenthesize_call63(f) then
    return("(" .. f1 .. ")" .. args)
  else
    return(f1 .. args)
  end
end
local function op_delims(parent, child, ...)
  local _u141 = unstash({...})
  local right = _u141.right
  local _u334
  if right then
    _u334 = _6261
  else
    _u334 = _62
  end
  if _u334(precedence(child), precedence(parent)) then
    return({"(", ")"})
  else
    return({"", ""})
  end
end
local function compile_infix(form)
  local op = form[1]
  local _u146 = cut(form, 1)
  local a = _u146[1]
  local b = _u146[2]
  local _u147 = op_delims(form, a)
  local ao = _u147[1]
  local ac = _u147[2]
  local _u148 = op_delims(form, b, {_stash = true, right = true})
  local bo = _u148[1]
  local bc = _u148[2]
  local _u149 = compile(a)
  local _u150 = compile(b)
  local _u151 = getop(op)
  if unary63(form) then
    return(_u151 .. ao .. _u149 .. ac)
  else
    return(ao .. _u149 .. ac .. " " .. _u151 .. " " .. bo .. _u150 .. bc)
  end
end
function compile_function(args, body, ...)
  local _u152 = unstash({...})
  local name = _u152.name
  local prefix = _u152.prefix
  local _u335
  if name then
    _u335 = compile(name)
  else
    _u335 = ""
  end
  local id = _u335
  local _u154 = compile_args(args)
  indent_level = indent_level + 1
  local _u156 = compile(body, {_stash = true, stmt = true})
  indent_level = indent_level - 1
  local _u155 = _u156
  local ind = indentation()
  local _u336
  if prefix then
    _u336 = prefix .. " "
  else
    _u336 = ""
  end
  local p = _u336
  local _u337
  if target == "js" then
    _u337 = ""
  else
    _u337 = "end"
  end
  local tr = _u337
  if name then
    tr = tr .. "\n"
  end
  if target == "js" then
    return("function " .. id .. _u154 .. " {\n" .. _u155 .. ind .. "}" .. tr)
  else
    return(p .. "function " .. id .. _u154 .. "\n" .. _u155 .. ind .. tr)
  end
end
local function can_return63(form)
  return(is63(form) and (atom63(form) or not (hd(form) == "return") and not statement63(hd(form))))
end
function compile(form, ...)
  local _u158 = unstash({...})
  local stmt = _u158.stmt
  if nil63(form) then
    return("")
  else
    if special_form63(form) then
      return(compile_special(form, stmt))
    else
      local tr = terminator(stmt)
      local _u338
      if stmt then
        _u338 = indentation()
      else
        _u338 = ""
      end
      local ind = _u338
      local _u339
      if atom63(form) then
        _u339 = compile_atom(form)
      else
        local _u340
        if infix63(hd(form)) then
          _u340 = compile_infix(form)
        else
          _u340 = compile_call(form)
        end
        _u339 = _u340
      end
      local _u160 = _u339
      return(ind .. _u160 .. tr)
    end
  end
end
local function lower_statement(form, tail63)
  local hoist = {}
  local e = lower(form, hoist, true, tail63)
  if some63(hoist) and is63(e) then
    return(join({"do"}, join(hoist, {e})))
  else
    if is63(e) then
      return(e)
    else
      if _35(hoist) > 1 then
        return(join({"do"}, hoist))
      else
        return(hd(hoist))
      end
    end
  end
end
local function lower_body(body, tail63)
  return(lower_statement(join({"do"}, body), tail63))
end
local function lower_do(args, hoist, stmt63, tail63)
  local _u168 = butlast(args)
  local _u169 = _35(_u168)
  local _u170 = 0
  while _u170 < _u169 do
    local x = _u168[_u170 + 1]
    add(hoist, lower(x, hoist, stmt63))
    _u170 = _u170 + 1
  end
  local e = lower(last(args), hoist, stmt63, tail63)
  if tail63 and can_return63(e) then
    return({"return", e})
  else
    return(e)
  end
end
local function lower_if(args, hoist, stmt63, tail63)
  local cond = args[1]
  local _u173 = args[2]
  local _u174 = args[3]
  if stmt63 or tail63 then
    local _u342
    if _u174 then
      _u342 = {lower_body({_u174}, tail63)}
    end
    return(add(hoist, join({"%if", lower(cond, hoist), lower_body({_u173}, tail63)}, _u342)))
  else
    local e = unique()
    add(hoist, {"%local", e})
    local _u341
    if _u174 then
      _u341 = {lower({"set", e, _u174})}
    end
    add(hoist, join({"%if", lower(cond, hoist), lower({"set", e, _u173})}, _u341))
    return(e)
  end
end
local function lower_short(x, args, hoist)
  local a = args[1]
  local b = args[2]
  local hoist1 = {}
  local b1 = lower(b, hoist1)
  if some63(hoist1) then
    local id = unique()
    local _u343
    if x == "and" then
      _u343 = {"%if", id, b, id}
    else
      _u343 = {"%if", id, id, b}
    end
    return(lower({"do", {"%local", id, a}, _u343}, hoist))
  else
    return({x, lower(a, hoist), b1})
  end
end
local function lower_try(args, hoist, tail63)
  return(add(hoist, {"%try", lower_body(args, tail63)}))
end
local function lower_while(args, hoist)
  local c = args[1]
  local body = cut(args, 1)
  return(add(hoist, {"while", lower(c, hoist), lower_body(body)}))
end
local function lower_for(args, hoist)
  local t = args[1]
  local k = args[2]
  local body = cut(args, 2)
  return(add(hoist, {"%for", lower(t, hoist), k, lower_body(body)}))
end
local function lower_function(args)
  local a = args[1]
  local body = cut(args, 1)
  return({"%function", a, lower_body(body, true)})
end
local function lower_definition(kind, args, hoist)
  local name = args[1]
  local _u199 = args[2]
  local body = cut(args, 2)
  return(add(hoist, {kind, name, _u199, lower_body(body, true)}))
end
local function lower_call(form, hoist)
  local _u202 = map(function (x)
    return(lower(x, hoist))
  end, form)
  if some63(_u202) then
    return(_u202)
  end
end
local function lower_infix63(form)
  return(infix63(hd(form)) and _35(form) > 3)
end
local function lower_infix(form, hoist)
  local x = form[1]
  local args = cut(form, 1)
  return(lower(reduce(function (a, b)
    return({x, b, a})
  end, reverse(args)), hoist))
end
local function lower_special(form, hoist)
  local e = lower_call(form, hoist)
  if e then
    return(add(hoist, e))
  end
end
function lower(form, hoist, stmt63, tail63)
  if atom63(form) then
    return(form)
  else
    if empty63(form) then
      return({"%array"})
    else
      if nil63(hoist) then
        return(lower_statement(form))
      else
        if lower_infix63(form) then
          return(lower_infix(form, hoist))
        else
          local x = form[1]
          local args = cut(form, 1)
          if x == "do" then
            return(lower_do(args, hoist, stmt63, tail63))
          else
            if x == "%if" then
              return(lower_if(args, hoist, stmt63, tail63))
            else
              if x == "%try" then
                return(lower_try(args, hoist, tail63))
              else
                if x == "while" then
                  return(lower_while(args, hoist))
                else
                  if x == "%for" then
                    return(lower_for(args, hoist))
                  else
                    if x == "%function" then
                      return(lower_function(args))
                    else
                      if x == "%local-function" or x == "%global-function" then
                        return(lower_definition(x, args, hoist))
                      else
                        if in63(x, {"and", "or"}) then
                          return(lower_short(x, args, hoist))
                        else
                          if statement63(x) then
                            return(lower_special(form, hoist))
                          else
                            return(lower_call(form, hoist))
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
local function expand(form)
  return(lower(macroexpand(form)))
end
local load1 = load
local function run(code)
  local f,e = load1(code)
  if f then
    return(f())
  else
    error(e .. " in " .. code)
  end
end
_37result = nil
function eval(form)
  local previous = target
  target = "lua"
  local code = compile(expand({"set", "%result", form}))
  target = previous
  run(code)
  return(_37result)
end
local function run_file(path)
  return(run(read_file(path)))
end
local function compile_file(path)
  local s = reader.stream(read_file(path))
  local body = reader["read-all"](s)
  local form = expand(join({"do"}, body))
  return(compile(form, {_stash = true, stmt = true}))
end
setenv("do", {_stash = true, special = function (...)
  local forms = unstash({...})
  local s = ""
  local _u223 = forms
  local _u224 = _35(_u223)
  local _u225 = 0
  while _u225 < _u224 do
    local x = _u223[_u225 + 1]
    s = s .. compile(x, {_stash = true, stmt = true})
    _u225 = _u225 + 1
  end
  return(s)
end, stmt = true, tr = true})
setenv("%if", {_stash = true, special = function (cond, cons, alt)
  local _u234 = compile(cond)
  indent_level = indent_level + 1
  local _u236 = compile(cons, {_stash = true, stmt = true})
  indent_level = indent_level - 1
  local _u235 = _u236
  local _u344
  if alt then
    indent_level = indent_level + 1
    local _u238 = compile(alt, {_stash = true, stmt = true})
    indent_level = indent_level - 1
    _u344 = _u238
  end
  local _u237 = _u344
  local ind = indentation()
  local s = ""
  if target == "js" then
    s = s .. ind .. "if (" .. _u234 .. ") {\n" .. _u235 .. ind .. "}"
  else
    s = s .. ind .. "if " .. _u234 .. " then\n" .. _u235
  end
  if _u237 and target == "js" then
    s = s .. " else {\n" .. _u237 .. ind .. "}"
  else
    if _u237 then
      s = s .. ind .. "else\n" .. _u237
    end
  end
  if target == "lua" then
    return(s .. ind .. "end\n")
  else
    return(s .. "\n")
  end
end, stmt = true, tr = true})
setenv("while", {_stash = true, special = function (cond, form)
  local _u243 = compile(cond)
  indent_level = indent_level + 1
  local _u244 = compile(form, {_stash = true, stmt = true})
  indent_level = indent_level - 1
  local body = _u244
  local ind = indentation()
  if target == "js" then
    return(ind .. "while (" .. _u243 .. ") {\n" .. body .. ind .. "}\n")
  else
    return(ind .. "while " .. _u243 .. " do\n" .. body .. ind .. "end\n")
  end
end, stmt = true, tr = true})
setenv("%for", {_stash = true, special = function (t, k, form)
  local _u249 = compile(t)
  local ind = indentation()
  indent_level = indent_level + 1
  local _u250 = compile(form, {_stash = true, stmt = true})
  indent_level = indent_level - 1
  local body = _u250
  if target == "lua" then
    return(ind .. "for " .. k .. " in next, " .. _u249 .. " do\n" .. body .. ind .. "end\n")
  else
    return(ind .. "for (" .. k .. " in " .. _u249 .. ") {\n" .. body .. ind .. "}\n")
  end
end, stmt = true, tr = true})
setenv("%try", {_stash = true, special = function (form)
  local ind = indentation()
  indent_level = indent_level + 1
  local _u258 = compile(form, {_stash = true, stmt = true})
  indent_level = indent_level - 1
  local body = _u258
  local e = unique()
  local hf = {"return", {"%array", false, {"get", e, "\"message\""}}}
  indent_level = indent_level + 1
  local _u262 = compile(hf, {_stash = true, stmt = true})
  indent_level = indent_level - 1
  local h = _u262
  return(ind .. "try {\n" .. body .. ind .. "}\n" .. ind .. "catch (" .. e .. ") {\n" .. h .. ind .. "}\n")
end, stmt = true, tr = true})
setenv("%delete", {_stash = true, special = function (place)
  return(indentation() .. "delete " .. compile(place))
end, stmt = true})
setenv("break", {_stash = true, special = function ()
  return(indentation() .. "break")
end, stmt = true})
setenv("%function", {_stash = true, special = function (args, body)
  return(compile_function(args, body))
end})
setenv("%global-function", {_stash = true, special = function (name, args, body)
  if target == "lua" then
    local x = compile_function(args, body, {_stash = true, name = name})
    return(indentation() .. x)
  else
    return(compile({"set", name, {"%function", args, body}}, {_stash = true, stmt = true}))
  end
end, stmt = true, tr = true})
setenv("%local-function", {_stash = true, special = function (name, args, body)
  if target == "lua" then
    local x = compile_function(args, body, {_stash = true, name = name, prefix = "local"})
    return(indentation() .. x)
  else
    return(compile({"%local", name, {"%function", args, body}}, {_stash = true, stmt = true}))
  end
end, stmt = true, tr = true})
setenv("return", {_stash = true, special = function (x)
  local _u345
  if nil63(x) then
    _u345 = "return"
  else
    _u345 = "return(" .. compile(x) .. ")"
  end
  local _u285 = _u345
  return(indentation() .. _u285)
end, stmt = true})
setenv("error", {_stash = true, special = function (x)
  local _u346
  if target == "js" then
    _u346 = "throw new " .. compile({"Error", x})
  else
    _u346 = "error(" .. compile(x) .. ")"
  end
  local e = _u346
  return(indentation() .. e)
end, stmt = true})
setenv("%local", {_stash = true, special = function (name, value)
  local id = compile(name)
  local value1 = compile(value)
  local _u347
  if is63(value) then
    _u347 = " = " .. value1
  else
    _u347 = ""
  end
  local rh = _u347
  local _u348
  if target == "js" then
    _u348 = "var "
  else
    _u348 = "local "
  end
  local keyword = _u348
  local ind = indentation()
  return(ind .. keyword .. id .. rh)
end, stmt = true})
setenv("set", {_stash = true, special = function (lh, rh)
  local _u300 = compile(lh)
  local _u349
  if nil63(rh) then
    _u349 = "nil"
  else
    _u349 = rh
  end
  local _u301 = compile(_u349)
  return(indentation() .. _u300 .. " = " .. _u301)
end, stmt = true})
setenv("get", {_stash = true, special = function (t, k)
  local _u305 = compile(t)
  local k1 = compile(k)
  if target == "lua" and char(_u305, 0) == "{" then
    _u305 = "(" .. _u305 .. ")"
  end
  if string_literal63(k) and valid_id63(inner(k)) then
    return(_u305 .. "." .. inner(k))
  else
    return(_u305 .. "[" .. k1 .. "]")
  end
end})
setenv("%array", {_stash = true, special = function (...)
  local forms = unstash({...})
  local _u350
  if target == "lua" then
    _u350 = "{"
  else
    _u350 = "["
  end
  local open = _u350
  local _u351
  if target == "lua" then
    _u351 = "}"
  else
    _u351 = "]"
  end
  local close = _u351
  local s = ""
  local c = ""
  local _u313 = forms
  local k = nil
  for k in next, _u313 do
    local v = _u313[k]
    if number63(k) then
      s = s .. c .. compile(v)
      c = ", "
    end
  end
  return(open .. s .. close)
end})
setenv("%object", {_stash = true, special = function (...)
  local forms = unstash({...})
  local s = "{"
  local c = ""
  local _u352
  if target == "lua" then
    _u352 = " = "
  else
    _u352 = ": "
  end
  local sep = _u352
  local _u323 = pair(forms)
  local k = nil
  for k in next, _u323 do
    local v = _u323[k]
    if number63(k) then
      local _u325 = v[1]
      local _u326 = v[2]
      if not string63(_u325) then
        error("Illegal key: " .. string(_u325))
      end
      s = s .. c .. key(_u325) .. sep .. compile(_u326)
      c = ", "
    end
  end
  return(s .. "}")
end})
return({eval = eval, ["run-file"] = run_file, ["compile-file"] = compile_file, expand = expand, compile = compile})
