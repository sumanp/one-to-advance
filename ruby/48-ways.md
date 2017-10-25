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


### Classes Objects and Modules
### 6. Know how ruby build's inheritance hierarchies
* An object is a container of variables. These variables are referred to as instance variables and represent the state of an object. Each object has a special, internal variable that connects it to one and only one class. Because of this connection the object is said to be an instance of this class.

* A class is a container of methods and constants. The methods are referred to as instance methods and represent the behavior for all objects which are instances of the class.

* A superclass is a fancy name for the parent class in a class hierarchy. If class B inherits from class A, then A is the superclass of B. Classes have a special, internal variable to keep track of their superclass.

* A module is identical to a class in all respects but one. Like classes, modules are objects and therefore have a connection to a class which they are an instance of. While classes are connected to the Class class, modules are connected to the Module class. Internally, Ruby implements modules and classes using the same data structure but limits what you can do with them through their class methods (there’s no new method) and a more restrictive syntax.

* Modules have many uses in Ruby but for now we’re only concerned with how they contribute to the inheritance hierarchy. Although Ruby doesn’t directly support multiple inheritance, modules can be mixed into a class with the include method which has a similar effect.

* Singleton classes play an important role in Ruby, such as providing a place to store class methods and methods included from modules. Unlike other classes, they’re created dynamically on an as needed basis by Ruby itself. They also come with restrictions. For example, you can’t create an instance of a singleton class. The only thing you really need to take away from this is that singleton classes are just regular classes which don’t have names and are subjected to a couple of limitations.

* A receiver is the object on which a method is invoked. For example, in “customer.name” the method invoked is name and the receiver is customer. While the name method is executing the self variable will be set to customer and any instance variables accessed will come from the customer object. Sometimes the receiver is omitted from method calls, in which case it’s implicitly set to whatever self is in the current context.

```
class Person
  def name
    ...
  end
end

class Customer < Person
  ...
end
irb> customer = Customer.new
---> #<Customer>

irb> customer.class
---> Customer

irb> Customer.superclass
---> Person

irb> customer.respond_to?(:name)
---> true
```

* Modules can never override methods from the class which includes them. Since modules are inserted above the including class Ruby always checks the class before moving upward. (Okay, this isn’t entirely true. Be sure to read Item 35 to see how the prepend method in Ruby 2.0 complicates this.)

```
customer = Customer.new

def customer.name
  "Leonard"
end
```

The code above defines a method which exists only for this one object, customer. This specific method cannot be called on any other object. How do you suppose Ruby implements that? If you’re pointing a finger at singleton classes you’d be correct. In fact, this method is called a singleton method. When Ruby executes this code it will create a singleton class, install the name method as an instance method, and then insert this anonymous class as the class of the customer object. Even though the class of the customer object is now a singleton class, the introspective class method in Ruby will skip over it and still return Customer. This obscures things for us but makes life easier for Ruby. When it searches for the name method it only needs to traverse the class hierarchy. No special logic is needed.

Things to remember:
• To find a method Ruby only has to search up the class hierarchy. If it doesn’t find the method it’s looking for it starts the search again, trying to find the method_missing method.

• Including modules silently creates singleton classes which are inserted into the hierarchy above the including class.

• Singleton methods (class methods and per-object methods) are stored in singleton classes which are also inserted into the hierarchy.


### 7. Be aware of different behaviors of super
