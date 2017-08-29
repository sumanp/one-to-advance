## Ways to Write Better Ruby

### 1. In ruby every value is true except nil & false.
Unlike in a lot of languages, the number zero is true in Ruby.
If you want to differentiate between nil and false, either use the nil? method or use the "==" operator with false as the left operand

### 2. Treat all objects as if it could be nil (nil error sneaks into production)
problem: undefined method fubar for nil:NilClass (NoMethodError)
solution: use to_s, to_a, to_f
example: nil.to_s = ""

In case of array, name = [first, middle, last].compact.join(" ")
Array#compact “method returns a copy of the receiver with all nil elements removed.

Always assume that every variable could be nil.

### 3. Avoid ruby's cryptic perlism.
a] example: The variables created by the “=~” operator are called special global variables.

  Cryptic code:
  ```def extract_error (message)
    if message =~ /^ERROR:\s+(.+)$/
      $1
    else
      "no error"
    end
  end
  ```

  Alternative:
  ```def extract_error (message)
    if m = message.match(/^ERROR:\s+(.+)$/)
      m[1]
    else
      "no error"
    end
  end
  ```

b] $_

  Cryptic code:
  ```“while readline
    print if ~ /^ERROR:/
  end
  ```
  “The only legitimate use for these methods (and the $_ variable) is for writing short, simple scripts on the command line, so-called “one liners”.”

  “This version of readline is subtlety different from its counterpart in the IO class. You can probably gather that it reads a line from standard input and returns it. The subtle part is that it also stores that line of input in the $_ variable. (Kernel#gets does the same thing but doesn’t raise an exception when the end-of-file marker is reached.) In a similar fashion, if Kernel#print is called without any arguments, ”

  “When you’re writing real code you should avoid methods which implicitly read from, or write to, the $_ global variable.”

  “These include other similar Kernel methods which I haven’t listed here such as chomp, sub, and gsub.”

  “Things to Remember

    • Prefer String#match to String#=~. The former returns all the match information in a MatchData object instead of several special global variables.

    • Use the longer, more descriptive global variable aliases as opposed to their short cryptic names (e.g. $LOAD_PATH instead of $:). Most of the longer names are only available after loading the English library.

    • Avoid methods which implicitly read from, or write to, the $_ global variable (e.g. Kernel#print, Regexp#~, etc.)”

### 4. Be aware that constants are mutable.
In reality, a constant is any identifier which begins with an uppercase letter. This means that identifiers like String and Array are also constants. That’s right, the names of classes and modules are actually constants in Ruby.

Things to Remember

• Always freeze constants to prevent them from being mutated.

• If a constant references a collection object such as an array or hash, freeze the collection and its elements.

• To prevent assigning new values to existing constants, freeze the module they’re defined in.

### 5. Pay Attention to Runtime Warnings
When you give your Ruby code to the interpreter, it has to perform some compiler-like tasks before it starts to execute the code. It’s useful to think about Ruby working with our code in two phases, compile time and run time.

The majority of them are generated when Ruby encounters ambiguous syntax and proceeds by picking one of many possible interpretations. You obviously don’t want Ruby guessing what you really meant. Imagine what would happen if a future version of Ruby changed its interpretation of ambiguous code and your program started behaving differently! By paying attention to these types of warnings you can make the necessary changes to your code and completely avoid the ambiguity in the first place. Here’s an example where the code isn’t completely clear and Ruby produces a warning:

Example:

```irb> dirs = ['usr', 'bin', 'local']
irb> File.join *dirs
warning: `*' interpreted as argument prefix

irb> File.join(*dirs)
---> "usr/local/bin"

irb> dirs.map &:length
warning: `&' interpreted as argument prefix

irb> dirs.map(&:length)
---> [3, 5, 3]
```

Things to Remember

• Use the “-w” command line option to the Ruby interpreter to enable compile time and run time warnings. You can also set the RUBYOPT environment variable to “-w”.

• If you must disable run time warnings, do so by temporarily setting the $VERBOSE global variable to nil.
