using FactCheck
# (defn contextual-eval [ctx expr]
#   (eval
#    `(let [~@(mapcat (fn [[k v]] [k `'~v]) ctx)]
#       ~expr)))
#
# (contextual-eval '{a 1, b 2} '(+ a b))

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

