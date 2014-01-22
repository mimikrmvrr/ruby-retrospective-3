require 'prime'

class Integer
  def prime?
    return false if self < 2
    2.upto(Math.sqrt(abs)).each do |potential_divisor|
      return false if self % potential_divisor == 0
    end
    true
  end

  def prime_factors
    prime_factors = []
    abs.prime_division.map { |factor, power| Array.new(power, factor) }.flatten
  end

  def harmonic
    1.upto(self).map { |n| Rational(1, n) }.inject { |a, b| a + b }
  end

  def digits
    abs.to_s.split(//).map { |digit| digit.to_i }
  end
end

class Array
  def frequencies
    frequencies = Hash.new(0)
    each { |item| frequencies[item] += 1 }
    return frequencies
  end

  def average
    inject { |a, b| a + b }. to_f / size
  end

  def drop_every(n)
    each_slice(n).map { |s| if s.size == n then s[0...-1] else s end }.flatten
  end

  def combine_with(other)
    shorter, longer = size < other.size ? [self, other] : [other, self]
    common = take(shorter.size).zip(other).flatten(1)
    rest = longer.drop(shorter.size)
    common + rest
  end
end
