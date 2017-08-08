## Effective Ruby: 48 Specific Ways to Write Better Ruby

1. In ruby every value is true except nil & false.
Unlike in a lot of languages, the number zero is true in Ruby.
If you want to differentiate between nil and false, either use the nil? method or use the "==" operator with false as the left operand

2. Treat all objects as if it could be nil (nil error sneaks into production)
problem: undefined method fubar for nil:NilClass (NoMethodError)
solution: use to_s, to_a, to_f
example: nil.to_s = ""

In case of array, name = [first, middle, last].compact.join(" ")
Array#compact “method returns a copy of the receiver with all nil elements removed.

Always assume that every variable could be nil.

3. 
