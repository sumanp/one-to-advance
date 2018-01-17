You can tell that you need to stop caching when your cache key gets more and more granular.

High memory consumption is intrinsic to Ruby. It’s a side effect of the language design. “Everything is an object” means that programs need extra memory to represent data as Ruby objects. Also, slow garbage collection is a well-known historical problem with Ruby. Its mark-and-sweep, stop-the-world GC is not only the slowest known garbage collection algorithm. It also has to stop the application for the time GC is running

Let’s see how much by printing memory size before and after our benchmark. The way to do this is to print the process’s RSS, or Resident Set Size, which is the portion of a process’s memory that’s held in RAM.

puts "%dM" % `ps -o rss= -p #{Process.pid}`.to_i

Takeaways
• Memory consumption and garbage collection are among the major reasons why Ruby is slow.
• Ruby has a significant memory overhead.
• GC in Ruby 2.1 and later is up to five times faster than in earlier versions.
• The raw performance of all modern Ruby interpreters is about the same.




Optimise Memory:
High memory consumption is what makes Ruby slow. Therefore, to optimise we need to reduce the memory footprint. This will, in turn, reduce the time for garbage collection.

It turns out that to get significant speedup you might not need code profiling. Memory optimization is easier: just review, think, and rewrite. Only when you are sure that the code spends a reasonable time in GC should you look further and try to locate algorithmic complexity or other sources of poor performance.

Takeaways
• The 80-20 rule of Ruby performance optimization: 80% of performance improvements come from memory optimization, so optimize memory first.
• A memory-optimized program has the same performance in any modern Ruby versions.
• Ruby 2.1 is not a silver performance bullet; it just minimizes losses.



Get Into the Performance Mind-set:
When you write code, remember that memory consumption and garbage collection are, most likely, why Ruby is slow, and constantly ask yourself these three questions:

1. Is Ruby the right tool to solve my problem?
Ruby is a general-purpose programming language, but that doesn’t mean you should use it to solve all your problems. There are things that Ruby is not so good at. The prime example is large dataset processing. That needs memory: exactly the sort of thing that you want to avoid.
This task is better done in a database or in background processes written in other programming languages. Twitter, for example, once had a Ruby on Rails front end backed by Scala workers. Another example is statistical computations, which are better done with, say, the R language.

2. How much memory will my code use?
The less memory your code uses, the less work Ruby GC has to do. You already know some tricks to reduce memory consumption

3. What is the raw performance of this code?
Once you’re sure the memory is used optimally, take a look at the algo- rithmic complexity of the code itself.

**************************************************************************************************************************************************

Save Memory:
The first step to make your application faster is to save memory. Every time you create or copy something in memory, you add work for GC. Let’s look at the best practices to write code that doesn’t use too much memory.

1. Modify Strings in place:
You can do most string manipulations in place, meaning that instead of making a changed copy, you change the original.
Ruby has a bunch of “bang!” functions for in-place modification. Those are gsub!, capitalize!, downcase!, upcase!, delete!, reverse!, slice!, and others. It’s always a good idea to use them as much as you can when you no longer need the original string.

Example:
```
require '../wrapper'

str="X"*1024*1024*10 #10MBstring

measure do
  str = str.downcase # requires extra memory of 10mb
end

measure do
  str.downcase!
end
```

1b. Inplace modification using String::<<
```
#bad
x = "foo"
x += "bar"

#good
x = "foo"
x << " bar"
```
Another thing worth pointing out is that “bang!” functions are not guaranteed to do an in-place modification. Most of them do, but that’s implementation dependent. So don’t be surprised when one of them doesn’t optimize anything.



2. Modifying Arrays and Hashes
do not create a modified copy of the same array unless really necessary. Use in place modification using '!'

```
# don't
require 'wrapper'
data = Array.new(100) { "x" * 1024 * 1024 }
measure do
  data.map { |str| str.upcase }
end

# do
require 'wrapper'
data = Array.new(100) { "x" * 1024 * 1024 }
measure do
  data.map! { |str| str.upcase! }
end

Total time          Extra memory        # of GC calls
map and upcase
0.22s               100 MB              3
map! and upcase!
0.14s               0 MB                0
```


3. Read Files Line by Line
Reading the 26 MB data.csv file1 takes exactly 26 MB of memory. It takes 158 MB to split the same CSV file into lines and columns.
```
# don't
File.read("data.csv")

# don't
File.readlines("data.csv").map! { |line| line.split(",") }
```
The Ruby CSV parser takes even more. It needs 346 MB of memory, 13 times the data size.

```
# do this
require '../wrapper'
measure do
  file = File.open("data.csv", "r")
  while line = file.gets
    line.split(",")
  end
end
```


4. Watch for Memory Leaks Caused by Callbacks
be careful every time you create a block or Proc callback. Remember, if you store it somewhere, you will also keep references to its execution context. That not only hurts the performance, but also might even leak memory.
```
module Logger
  extend self
  attr_accessor :output, :log_actions

  def log(&event)
    self.log_actions ||= []
    self.log_actions << event
  end

  def play
    output = []
    log_actions.each { |e| e.call(output) }
    puts output.join("\n")
  end
end


class Thing
  def initialize(id)
    Logger.log { |output| output << "created thing #{id}" }
  end
end

def do_something
  1000.times { |i| Thing.new(i) }
end

do_something
GC.start
Logger.play
puts ObjectSpace.each_object(Thing).count
```

So be careful every time you create a block or Proc callback. Remember, if you store it somewhere, you will also keep references to its execution context. That not only hurts the performance, but also might even leak memory.

5. Are All Anonymous Blocks Dangerous to Performance?
Lorem
Lorem



6. Optimise your Iterators
Because a Ruby iterator is a function of an object (Array, Range, Hash, etc.), it has two characteristics that affect performance:

i. Ruby GC will not garbage collect the object you’re iterating before the iterator is finished. This means that when you have a large list in memory, that whole list will stay in memory even if you no longer need the parts you’ve already traversed.
ii. Iterators, being functions, can and will create temporary objects behind the scenes. This adds work for the garbage collector and hurts performance.


```
class Thing; end
list = Array.new(1000) { Thing.new } # allocate 1000 objects again
puts ObjectSpace.each_object(Thing).count

while list.count > 0
  GC.start # this will garbage collect item from previous iteration
  puts ObjectSpace.each_object(Thing).count # watch the counter decreasing
  item = list.shift
end

GC.start # this will garbage collect item from previous iteration
puts ObjectSpace.each_object(Thing).count # watch the counter decreasing

```

In the real world you wouldn’t want to force GC. Just let it do its job and your loop will neither take too much time nor run out of memory.

7. Avoid Iterators That Create Additional Objects
Some ruby iterations create additional ruby objects internally. Iterators are where the algorithmic complexity of the functions you use mat- ters, even in Ruby. One millisecond lost in a loop with one thousand iterations translates to a one-second slowdown.

Iterator Example 1:
```
GC.disable
before = ObjectSpace.count_objects

Array.new(10000).each do |i|
  [0,1].each do |j|
  end
end

after = ObjectSpace.count_objects
puts "# of arrays: %d" % (after[:T_ARRAY] - before[:T_ARRAY])
puts "# of nodes: %d" % (after[:T_NODE] - before[:T_NODE])
```
Number of arrays: 10001
Number of nodes: 0



Iterator Example 2:
```
GC.disable
before = ObjectSpace.count_objects

MEMO_OBJECT_TYPE = (RUBY_VERSION >= '2.3.0') ? :T_IMEMO : :T_NODE

Array.new(10000).each do |i|
  [0,1].each_with_index do |j, index|
  end
end

after = ObjectSpace.count_objects
puts "# of arrays: %d" % (after[:T_ARRAY] - before[:T_ARRAY])
puts "# of extra Ruby objects: %d" % (after[MEMO_OBJECT_TYPE] - before[MEMO_OBJECT_TYPE])
```

Number of arrays: 10001
Number of nodes: 20001

each_with_index creates an additional NODE  * memo variable. Because our each_with_index loop is nested in another loop, we get to create 10,000 additional nodes. Worse, the internal function each_with_index_i allocates one more node. Thus we end up with the 20,000 extra T_NODE/T_IMEMO objects that you see in our example output.


Note: Iterators that create 0 additional objects are safe to use in nested loops. But be careful with those that allocate two or even three additional objects: all?, each_with_index, inject, and others.

8. Date#parse (avoid in iterators)
Date parsing in Ruby has been traditionally slow, but this function is especially harmful for performance. Let’s see how much time it uses in a loop with 100,000 iterations:

Date#parse example 1:
```
require 'date'
require 'benchmark'
date = "2014-05-23"

time = Benchmark.realtime do
  100000.times do
    Date.parse(date)
  end
end

puts "%.3f" % time

```

Date#parse example 2
A better solution is to let the date parser know which date format to use, like this:
```
require 'date'
require 'benchmark'
date = "2014-05-23"
time = Benchmark.realtime do
        100000.times do
          Date.strptime(date, '%Y-%m-%d')
        end
      end

puts "%.3f" % time
```

Date#parse example 3:
```
require 'date'
require 'benchmark'
date = "2014-05-23"
time = Benchmark.realtime do
        100000.times do
          Date.civil(date[0,4].to_i, date[5,2].to_i, date[8,2].to_i)
        end
      end

puts "%.3f" % time
```

Note: while the above code is a little uglier. The result is almost 6 times faster than the original implementation.

9. Object#class, Object#is_a?, Object#kind_of? (avoid in iterators)
These have considerable performance overhead when used in loops or frequently used functions like constructors or == comparison operators.

```
require 'benchmark'
obj = "sample string"
time = Benchmark.realtime do
        100000.times do
          obj.class == String
        end
      end

puts time
```

It’s a good idea to move type checking away from iterators or frequently called functions and operators. If you can’t, unfortunately there’s not much you can do about that.

10. Write less Ruby
Best code is the code thats not written. Ruby is especially bad in two areas: large dataset processing and complex computations.

11. Offload work to the database
Avoid trading performance for convenience. that databases are really good at complex computations and other kinds of data manipulation.
Note: Use sql queries for creating db indexes. Better performance. Compare both rake tasks and sql queries, with loa.d test

#### Takeaways (These techniques can help improve ruby perforamce by 10 times)
We saw in this chapter that there are only three things that you need to consider to make your Ruby code faster:
• Optimize memory by avoiding extra allocations and memory leaks.
• Write faster iterators that take both less time and memory.
• And finally, write less Ruby code by letting specialized tools do their job.

12. Optimize rails: db queries
* load only required attributes with 'select' method
* Preload Aggressively: for has_many relationships (.includes)
* Make use of sql features for faster queries
* Use find_each and find_in_batches (mongoid equivalent) with each! pattern from above

#### Takeaways:
Optimize memory taken by ActiveRecord by aggressive preloading, selective attribute fetching, and data processing in batches.
• Replace explicit iterators in views with render collection, which takes both less time and memory.
• Let your database server do your data manipulation.
