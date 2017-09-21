# Binary search only works when your list is in sorted order. 
# For example, the names in a phone book are sorted in alphabetical order, so you can use binary search to look for a name.

def binary_search(list, item)
  low = 0
  high = list.length - 1
  steps = 0

  while low <= high
    steps += 1

    mid = (low + high) / 2
    guess = list[mid]
    if guess == item
      return "Item #{mid} found in #{steps} #{steps == 1 ? 'step' : 'steps'}"
    elsif guess > item
      high = mid - 1
    else
      low = mid + 1
    end
  end 
   return "Nothing found"
end

my_list = [1,3,4,7,9,5,8,10,11,12,13]

puts binary_search(my_list, 12)
puts binary_search(my_list, 5)
