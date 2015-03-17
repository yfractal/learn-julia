using FactCheck

function _let_block(dic_expr)
    function get_assignments(dic_content)
        exp = Expr(:(=))
        exp.args = dic_content.args

        exp
    end

    dic_contents = dic_expr.args[2:end]
    assignments = map(get_assignments, dic_contents)

    let_expr = Expr(:let)
    let_expr.args = unshift!(assignments, (quote end))

    let_expr
end

function contextual_eval(ctx, expr)
    let_expr = _let_block(ctx)
    let_expr.args[1] = expr

    eval(let_expr)
end

facts("contextual-eval") do
    context("let_block") do
        ctx = :({a=>1, b=>1})
        expected = :( let a = 1, b = 1 end )

        @fact _let_block(ctx) => expected
    end

    context("eval expr in the let block") do
        ctx = :({a=>1, b=>1})
        expr = :(a + b)

        @fact contextual_eval(ctx, expr) => 2
    end
end


# Defining control structures do_until
macro do_until(expr::Expr)
    function get_ifexpr(lines)
        line, ifexp = lines[1], Expr(:if)
        ifexp.args = line.args

        length(lines) >= 2 && push!(ifexp.args, get_ifexpr(lines[2:end]))

        push!(ifexp.args, nothing)

        ifexp
    end

    lines = []

    i = 1
    for line in expr.args
        (i % 2) == 0 && push!(lines, line)
        i += 1
    end

    esc(get_ifexpr(lines))
end

facts("do_until") do
    result_array = []

    @do_until begin
        iseven(2), push!(result_array, "Enven")
        (0 == 1), push!(result_array, "Zero")
    end

    @fact result_array => ["Enven"]
end

# Anaphora
# awhen
# (defmacro awhen [expr & body]
#   `(let [~'it ~expr]
#      (if ~'it
#        (do ~@body))))

# (awhen [1 2 3] (it 2))

macro awhen(expr, body...)
    esc(quote
        let it = $(expr)
          if it != nothing
            $(body...)
          end
        end
   end)
end

facts("awhen") do
    context("awhen") do
        @fact @awhen([1, 2, 3], it[2]) => 2
        @fact @awhen(nothing, it[2]) => nothing
        # do not use @awhen([1, 2, 3], x = 2, it[x])
        # see more https://groups.google.com/d/msg/julia-users/9KANwP6ZO2M/WWP8_k6gygQJ
        @fact (@awhen [1, 2, 3] x = 2 it[x]) => 2
    end
end

# resolulation
# http://www.jianshu.com/p/9f09ed930015
module Foo
x = "I am in Foo"
macro foo(exp)
    :($(exp))
end
end
@expand Foo.@foo( x )


module Foo
x = 100
macro foo(exp)
    :($(esc(exp)))
end
end
@expand Foo.@foo( x )

module Foo
x = 100
macro foo(exp)
    esc(:($(exp)))
end
end

@expand Foo.@foo( x )

# resolulation end
