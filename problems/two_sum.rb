
def two_sum(nums, target) # Trading space complex. for time complex.
    num_h = {}
    nums.each_with_index do |num, idx|
      complement = target - num
      if (num_h.key?(complement))
        return [idx, num_h[complement]]
      end
      num_h[num] = idx
    end
    return 'Illegal argument'
  end

  print two_sum([1,4,5,2,4,3,2,5,3,2], 8)