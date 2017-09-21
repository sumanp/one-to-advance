# Binary search only works when your list is in sorted order. For example, the names in a phone book are sorted in alphabetical order, so you can use binary search to look for a name.
def binary_search(list, item)
  low = 0
  high = list.length - 1

  while low <= high
    mid = (low + high)
    guess = list[mid]
    if guess == item
      return mid
    elsif guess > item
      high = mid - 1
    else
      low = mid + 1
    end
  end
  return "Nothing found"
end

my_list = [1,3,4,7,9]

puts binary_search(my_list, 7)
puts binary_search(my_list, 10)
